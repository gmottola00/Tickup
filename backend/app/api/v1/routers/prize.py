from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.schemas.prize import Prize, PrizeCreate
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
