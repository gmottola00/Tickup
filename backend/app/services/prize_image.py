from __future__ import annotations

from typing import Iterable, List, Optional
from uuid import UUID

from fastapi import HTTPException
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
import asyncio
import logging
from urllib import request, parse, error as urlerror
import json

from app.models.prize import Prize
from app.models.prize_image import PrizeImage as PrizeImageModel
from app.schemas.prize_image import (
    PrizeImageCreate,
    PrizeImageUpdate,
    PrizeImageReorderRequest,
)
from app.core.config import settings

logger = logging.getLogger(__name__)


async def _get_prize(db: AsyncSession, prize_id: UUID) -> Prize:
    prize = await db.get(Prize, prize_id)
    if not prize:
        raise HTTPException(status_code=404, detail="Prize not found")
    return prize


async def _ensure_owner(db: AsyncSession, prize_id: UUID, user_id: UUID) -> Prize:
    prize = await _get_prize(db, prize_id)
    if str(prize.user_id) != str(user_id):
        raise HTTPException(status_code=403, detail="Not authorized: not owner")
    return prize


async def list_images(db: AsyncSession, prize_id: UUID) -> List[PrizeImageModel]:
    await _get_prize(db, prize_id)
    stmt = (
        select(PrizeImageModel)
        .where(PrizeImageModel.prize_id == prize_id)
        .order_by(
            PrizeImageModel.sort_order.asc().nulls_last(),
            PrizeImageModel.created_at.asc(),
        )
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def create_image(
    db: AsyncSession, prize_id: UUID, user_id: UUID, data: PrizeImageCreate
) -> PrizeImageModel:
    await _ensure_owner(db, prize_id, user_id)

    if data.is_cover:
        await db.execute(
            update(PrizeImageModel)
            .where(PrizeImageModel.prize_id == prize_id, PrizeImageModel.is_cover == True)  # noqa: E712
            .values(is_cover=False)
        )

    obj = PrizeImageModel(
        prize_id=prize_id,
        bucket=data.bucket,
        storage_path=data.storage_path,
        url=data.url,
        is_cover=bool(data.is_cover),
        sort_order=data.sort_order,
    )
    db.add(obj)
    await db.commit()
    await db.refresh(obj)
    return obj


async def update_image(
    db: AsyncSession,
    prize_id: UUID,
    image_id: UUID,
    user_id: UUID,
    data: PrizeImageUpdate,
) -> PrizeImageModel:
    await _ensure_owner(db, prize_id, user_id)

    obj = await db.get(PrizeImageModel, image_id)
    if not obj or str(obj.prize_id) != str(prize_id):
        raise HTTPException(status_code=404, detail="Image not found for this prize")

    # If setting this as cover, reset others
    if data.is_cover is True:
        await db.execute(
            update(PrizeImageModel)
            .where(PrizeImageModel.prize_id == prize_id, PrizeImageModel.is_cover == True)  # noqa: E712
            .values(is_cover=False)
        )

    if data.is_cover is not None:
        obj.is_cover = data.is_cover
    if data.sort_order is not None:
        obj.sort_order = data.sort_order

    await db.commit()
    await db.refresh(obj)
    return obj


async def reorder_images(
    db: AsyncSession, prize_id: UUID, user_id: UUID, payload: PrizeImageReorderRequest
) -> List[PrizeImageModel]:
    await _ensure_owner(db, prize_id, user_id)

    # Validate all images belong to the prize
    ids = [item.image_id for item in payload.items]
    if not ids:
        return await list_images(db, prize_id)

    stmt = select(PrizeImageModel).where(
        PrizeImageModel.prize_id == prize_id, PrizeImageModel.image_id.in_(ids)
    )
    result = await db.execute(stmt)
    images = {img.image_id: img for img in result.scalars().all()}

    for item in payload.items:
        img = images.get(item.image_id)
        if img is None:
            raise HTTPException(status_code=404, detail=f"Image {item.image_id} not found for this prize")
        img.sort_order = item.sort_order

    await db.commit()
    # Return ordered list
    return await list_images(db, prize_id)


async def delete_image(
    db: AsyncSession, prize_id: UUID, image_id: UUID, user_id: UUID
) -> None:
    await _ensure_owner(db, prize_id, user_id)

    obj = await db.get(PrizeImageModel, image_id)
    if not obj or str(obj.prize_id) != str(prize_id):
        raise HTTPException(status_code=404, detail="Image not found for this prize")

    # Strict deletion: if storage delete fails, abort and return error
    try:
        await _delete_storage_object(obj.bucket, obj.storage_path)
    except Exception as e:
        logger.error(
            "Storage delete failed for %s/%s: %s", obj.bucket, obj.storage_path, e
        )
        raise HTTPException(
            status_code=502,
            detail="Unable to delete storage object; aborting metadata removal",
        )

    await db.delete(obj)
    await db.commit()


async def _delete_storage_object(bucket: str, storage_path: str) -> None:
    """Strict deletion of a Supabase Storage object via REST API.

    Uses service role key to bypass RLS. Expects either SUPABASE_SERVICE_ROLE_KEY
    or SUPABASE_KEY (if that's set to the service role) to be configured.
    """
    base_url = settings.SUPABASE_URL.rstrip("/")
    # Prefer dedicated service role key if provided
    service_key = None
    if getattr(settings, "SUPABASE_SERVICE_ROLE_KEY", None):
        try:
            service_key = settings.SUPABASE_SERVICE_ROLE_KEY.get_secret_value()
        except Exception:
            service_key = str(settings.SUPABASE_SERVICE_ROLE_KEY)
    if not service_key:
        try:
            service_key = settings.SUPABASE_KEY.get_secret_value()
        except Exception:
            service_key = str(settings.SUPABASE_KEY)
    if not base_url or not service_key:
        raise RuntimeError("Supabase settings missing: SUPABASE_URL or SUPABASE_KEY")

    # Use remove API with JSON body of prefixes
    url = f"{base_url}/storage/v1/object/{bucket}"
    body = json.dumps({"prefixes": [storage_path]}).encode("utf-8")

    headers = {
        "Authorization": f"Bearer {service_key}",
        "apikey": service_key,
        "Content-Type": "application/json",
    }

    def _do_delete():
        req = request.Request(url, data=body, method="DELETE", headers=headers)
        try:
            with request.urlopen(req, timeout=15) as resp:
                if resp.status not in (200, 204):
                    payload = resp.read().decode("utf-8", errors="ignore") if resp.length else ""
                    raise RuntimeError(f"Unexpected status {resp.status}: {payload}")
        except urlerror.HTTPError as he:
            if he.code == 404:
                return
            detail = he.read().decode("utf-8", errors="ignore") if he.fp else ""
            raise RuntimeError(f"HTTP {he.code}: {detail}")
        except urlerror.URLError as ue:
            raise RuntimeError(f"Network error: {ue}")

    loop = asyncio.get_running_loop()
    await loop.run_in_executor(None, _do_delete)
