from fastapi import APIRouter, Depends, HTTPException
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from app.schemas.prize import Prize, PrizeCreate
from app.schemas.prize_image import (
    PrizeImage as PrizeImageSchema,
    PrizeImageCreate,
    PrizeImageUpdate,
    PrizeImageReorderRequest,
)
from app.services.prize import (
    create_prize,
    get_prize,
    update_prize,
    delete_prize,
    get_all_prize,
    get_prizes_by_user,
)
from app.api.v1.deps import get_db_dep
from app.api.v1.auth import get_current_user_id
from app.services.prize_image import (
    list_images as list_prize_images,
    create_image as create_prize_image,
    update_image as update_prize_image,
    reorder_images as reorder_prize_images,
    delete_image as delete_prize_image,
)

router = APIRouter()

@router.post("/", response_model=Prize)
async def create(
    item: PrizeCreate,
    db: AsyncSession = Depends(get_db_dep),
    user_id: str = Depends(get_current_user_id),
):
    return await create_prize(db, item, user_id=user_id)

@router.get("/all_prizes", response_model=list[Prize])
async def read_all(db: AsyncSession = Depends(get_db_dep)):
    prizes = await get_all_prize(db)
    return prizes

@router.get("/my", response_model=list[Prize])
async def read_my(
    db: AsyncSession = Depends(get_db_dep),
    user_id: str = Depends(get_current_user_id),
):
    prizes = await get_prizes_by_user(db, user_id)
    return prizes

@router.get("/{prize_id}", response_model=Prize)
async def read(prize_id: str, db: AsyncSession = Depends(get_db_dep)):
    prize = await get_prize(db, prize_id)
    if not prize:
        raise HTTPException(status_code=404, detail="Prize not found")
    return prize

# Prize Images Endpoints

@router.get("/{prize_id}/images", response_model=list[PrizeImageSchema])
async def list_images(prize_id: str, db: AsyncSession = Depends(get_db_dep)):
    try:
        pid = UUID(prize_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid prize id")
    images = await list_prize_images(db, pid)
    return images


@router.post("/{prize_id}/images", response_model=PrizeImageSchema)
async def create_image(
    prize_id: str,
    item: PrizeImageCreate,
    db: AsyncSession = Depends(get_db_dep),
    user_sub: str = Depends(get_current_user_id),
):
    try:
        pid = UUID(prize_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid prize id")
    try:
        uid = UUID(user_sub)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user identifier")

    image = await create_prize_image(db, pid, uid, item)
    return image


@router.put("/{prize_id}/images/{image_id}", response_model=PrizeImageSchema)
async def update_image(
    prize_id: str,
    image_id: str,
    item: PrizeImageUpdate,
    db: AsyncSession = Depends(get_db_dep),
    user_sub: str = Depends(get_current_user_id),
):
    try:
        pid = UUID(prize_id)
        iid = UUID(image_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid id")
    try:
        uid = UUID(user_sub)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user identifier")

    image = await update_prize_image(db, pid, iid, uid, item)
    return image


@router.put("/{prize_id}/images/reorder", response_model=list[PrizeImageSchema])
async def reorder_images(
    prize_id: str,
    payload: PrizeImageReorderRequest,
    db: AsyncSession = Depends(get_db_dep),
    user_sub: str = Depends(get_current_user_id),
):
    try:
        pid = UUID(prize_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid prize id")
    try:
        uid = UUID(user_sub)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user identifier")

    images = await reorder_prize_images(db, pid, uid, payload)
    return images


@router.delete("/{prize_id}/images/{image_id}", status_code=204)
async def delete_image(
    prize_id: str,
    image_id: str,
    db: AsyncSession = Depends(get_db_dep),
    user_sub: str = Depends(get_current_user_id),
):
    try:
        pid = UUID(prize_id)
        iid = UUID(image_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid id")
    try:
        uid = UUID(user_sub)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user identifier")

    await delete_prize_image(db, pid, iid, uid)

@router.put("/{prize_id}", response_model=Prize)
async def update(prize_id: str, item: PrizeCreate, db: AsyncSession = Depends(get_db_dep)):
    prize = await get_prize(db, prize_id)
    if not prize:
        raise HTTPException(status_code=404, detail="Prize not found")
    return await update_prize(db, prize, item.dict())

@router.delete("/{prize_id}", status_code=204)
async def delete(prize_id: str, db: AsyncSession = Depends(get_db_dep)):
    prize = await get_prize(db, prize_id)
    if not prize:
        raise HTTPException(status_code=404, detail="Prize not found")
    await delete_prize(db, prize)
