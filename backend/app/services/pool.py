from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException
from app.models.pool import RafflePool
from app.schemas.pool import PoolCreate
from app.models.prize import Prize

async def create_pool(db: AsyncSession, pool_in: PoolCreate) -> RafflePool:
    prize = await db.get(Prize, pool_in.prize_id)
    if not prize:
        raise HTTPException(status_code=400, detail="Invalid prize_id: does not exist")

    pool = RafflePool(**pool_in.dict())
    db.add(pool)
    await db.commit()
    await db.refresh(pool)
    return pool

async def get_pool(db: AsyncSession, pool_id: str):
    return await db.get(RafflePool, pool_id)

async def get_all_pool(db: AsyncSession) -> list[RafflePool]:
    result = await db.execute(select(RafflePool))
    return result.scalars().all()

async def update_pool(db: AsyncSession, pool: RafflePool, data: dict):
    for key, value in data.items():
        setattr(pool, key, value)
    await db.commit()
    await db.refresh(pool)
    return pool

async def delete_pool(db: AsyncSession, pool: RafflePool):
    await db.delete(pool)
    await db.commit()
