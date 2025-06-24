from sqlalchemy.ext.asyncio import AsyncSession
from app.models.prize import Prize
from app.schemas.prize import PrizeCreate

async def create_prize(db: AsyncSession, prize_in: PrizeCreate) -> Prize:
    prize = Prize(**prize_in.dict())
    db.add(prize)
    await db.commit()
    await db.refresh(prize)
    return prize

async def get_prize(db: AsyncSession, prize_id: str):
    return await db.get(Prize, prize_id)

async def update_prize(db: AsyncSession, prize: Prize, data: dict):
    for key, value in data.items():
        setattr(prize, key, value)
    await db.commit()
    await db.refresh(prize)
    return prize

async def delete_prize(db: AsyncSession, prize: Prize):
    await db.delete(prize)
    await db.commit()
