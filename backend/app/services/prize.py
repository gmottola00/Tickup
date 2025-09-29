from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException
from app.models.prize import Prize
from app.models.pool import RafflePool
from app.schemas.prize import PrizeCreate

async def create_prize(db: AsyncSession, prize_in: PrizeCreate, *, user_id: str) -> Prize:
    prize = Prize(**prize_in.dict(), user_id=user_id)
    db.add(prize)
    await db.commit()
    await db.refresh(prize)
    return prize

async def get_prize(db: AsyncSession, prize_id: str):
    return await db.get(Prize, prize_id)

async def get_all_prize(db: AsyncSession) -> list[Prize]:
    result = await db.execute(select(Prize))
    return result.scalars().all()

async def get_prizes_by_user(db: AsyncSession, user_id: str) -> list[Prize]:
    result = await db.execute(select(Prize).where(Prize.user_id == user_id))
    return result.scalars().all()

async def update_prize(db: AsyncSession, prize: Prize, data: dict):
    for key, value in data.items():
        setattr(prize, key, value)
    await db.commit()
    await db.refresh(prize)
    return prize

async def delete_prize(db: AsyncSession, prize: Prize):
    pool_stmt = select(RafflePool.pool_id).where(RafflePool.prize_id == prize.prize_id)
    pool = await db.execute(pool_stmt)
    if pool.scalars().first() is not None:
        raise HTTPException(
            status_code=400,
            detail="Impossibile eliminare il premio: esiste un pool associato. Elimina prima il pool.",
        )

    await db.delete(prize)
    await db.commit()
