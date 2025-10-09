from __future__ import annotations

from typing import Iterable, List
from uuid import UUID

from fastapi import HTTPException
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.prize import Prize
from app.models.prize_image import PrizeImage as PrizeImageModel
from app.schemas.prize_image import (
    PrizeImageCreate,
    PrizeImageUpdate,
    PrizeImageReorderRequest,
)


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

    await db.delete(obj)
    await db.commit()

