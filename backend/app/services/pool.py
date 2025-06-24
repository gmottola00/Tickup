from sqlalchemy.ext.asyncio import AsyncSession
from app.models.pool import RafflePool
from app.schemas.pool import PoolCreate

async def create_pool(db: AsyncSession, pool_in: PoolCreate) -> RafflePool:
    pool = RafflePool(**pool_in.dict())
    db.add(pool)
    await db.commit()
    await db.refresh(pool)
    return pool

async def get_pool(db: AsyncSession, pool_id: str):
    return await db.get(RafflePool, pool_id)

async def update_pool(db: AsyncSession, pool: RafflePool, data: dict):
    for key, value in data.items():
        setattr(pool, key, value)
    await db.commit()
    await db.refresh(pool)
    return pool

async def delete_pool(db: AsyncSession, pool: RafflePool):
    await db.delete(pool)
    await db.commit()
