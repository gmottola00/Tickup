from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, join, func
from fastapi import HTTPException

from app.models.pool import RafflePool
from app.models.prize import Prize
from app.models.ticket import Ticket
from app.models.purchase import Purchase
from app.schemas.pool import PoolCreate

async def create_pool(db: AsyncSession, pool_in: PoolCreate) -> RafflePool:
    prize = await db.get(Prize, pool_in.prize_id)
    if not prize:
        raise HTTPException(status_code=400, detail="Invalid prize_id: does not exist")

    # Ensure only one pool can be associated with a given prize
    existing_pool_stmt = select(RafflePool.pool_id).where(
        RafflePool.prize_id == pool_in.prize_id
    )
    existing_pool = await db.execute(existing_pool_stmt)
    if existing_pool.scalar_one_or_none() is not None:
        raise HTTPException(
            status_code=400,
            detail="Esiste già un pool associato a questo premio",
        )

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

async def get_pools_by_user(db: AsyncSession, user_id: str) -> list[RafflePool]:
    # Join pools -> prize to filter by owner
    j = join(RafflePool, Prize, RafflePool.prize_id == Prize.prize_id)
    stmt = select(RafflePool).select_from(j).where(Prize.user_id == user_id)
    result = await db.execute(stmt)
    return result.scalars().all()

async def update_pool(db: AsyncSession, pool: RafflePool, data: dict):
    new_prize_id = data.get("prize_id", pool.prize_id)

    if new_prize_id != pool.prize_id:
        prize = await db.get(Prize, new_prize_id)
        if not prize:
            raise HTTPException(status_code=400, detail="Invalid prize_id: does not exist")

        existing_pool_stmt = select(RafflePool.pool_id).where(
            RafflePool.prize_id == new_prize_id,
            RafflePool.pool_id != pool.pool_id,
        )
        existing_pool = await db.execute(existing_pool_stmt)
        if existing_pool.scalar_one_or_none() is not None:
            raise HTTPException(
                status_code=400,
                detail="Esiste già un pool associato a questo premio",
            )

    for key, value in data.items():
        setattr(pool, key, value)
    await db.commit()
    await db.refresh(pool)
    return pool

async def delete_pool(db: AsyncSession, pool: RafflePool):
    ticket_count_stmt = select(func.count()).select_from(Ticket).where(
        Ticket.pool_id == pool.pool_id
    )
    tickets_count = (await db.execute(ticket_count_stmt)).scalar_one()
    if tickets_count and tickets_count > 0:
        raise HTTPException(
            status_code=400,
            detail="Impossibile eliminare il pool: sono presenti ticket già acquistati.",
        )

    purchase_count_stmt = select(func.count()).select_from(Purchase).where(
        Purchase.pool_id == pool.pool_id
    )
    purchases_count = (await db.execute(purchase_count_stmt)).scalar_one()
    if purchases_count and purchases_count > 0:
        raise HTTPException(
            status_code=400,
            detail="Impossibile eliminare il pool: esistono acquisti collegati al pool.",
        )

    await db.delete(pool)
    await db.commit()
