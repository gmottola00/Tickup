from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.schemas.prize import Prize, PrizeCreate
from app.services.prize import create_prize, get_prize, update_prize, delete_prize, get_all_prize
from app.api.v1.deps import get_db_dep

router = APIRouter()

@router.post("/", response_model=Prize)
async def create(item: PrizeCreate, db: AsyncSession = Depends(get_db_dep)):
    return await create_prize(db, item)

@router.get("/{prize_id}", response_model=Prize)
async def read(prize_id: str, db: AsyncSession = Depends(get_db_dep)):
    prize = await get_prize(db, prize_id)
    if not prize:
        raise HTTPException(status_code=404, detail="Prize not found")
    return prize

@router.get("/all_prizes", response_model=Prize)
async def read_all(prize_id: str, db: AsyncSession = Depends(get_db_dep)):
    prizes = await get_all_prize(db, prize_id)
    if not prizes:
        raise HTTPException(status_code=404, detail="Prizes not found")
    return prizes

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
