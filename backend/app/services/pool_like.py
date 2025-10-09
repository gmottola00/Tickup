from uuid import UUID

from fastapi import HTTPException
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError

from app.models.pool import RafflePool
from app.models.pool_like import PoolLike


async def _ensure_pool(db: AsyncSession, pool_id: UUID) -> RafflePool:
    pool = await db.get(RafflePool, pool_id)
    if not pool:
        raise HTTPException(status_code=404, detail="Pool not found")
    return pool


async def get_like_status(db: AsyncSession, pool_id: UUID, user_id: UUID) -> tuple[int, bool]:
    pool = await _ensure_pool(db, pool_id)
    liked = (
        await db.execute(
            select(PoolLike).where(
                PoolLike.pool_id == pool_id, PoolLike.user_id == user_id
            )
        )
    ).scalar_one_or_none() is not None
    return int(pool.likes or 0), liked


async def like_pool(db: AsyncSession, pool_id: UUID, user_id: UUID) -> tuple[int, bool]:
    pool = await _ensure_pool(db, pool_id)

    exists = (
        await db.execute(
            select(PoolLike).where(
                PoolLike.pool_id == pool_id, PoolLike.user_id == user_id
            )
        )
    ).scalar_one_or_none()
    if exists:
        return int(pool.likes or 0), True

    db.add(PoolLike(pool_id=pool_id, user_id=user_id))
    pool.likes = int(pool.likes or 0) + 1
    try:
        await db.commit()
    except IntegrityError:
        # Another concurrent like inserted first: idempotent return
        await db.rollback()
        # Refresh pool.likes from DB to avoid overcount
        pool = await _ensure_pool(db, pool_id)
        return int(pool.likes or 0), True

    await db.refresh(pool)
    return int(pool.likes or 0), True


async def unlike_pool(db: AsyncSession, pool_id: UUID, user_id: UUID) -> tuple[int, bool]:
    pool = await _ensure_pool(db, pool_id)

    existing = (
        await db.execute(
            select(PoolLike).where(
                PoolLike.pool_id == pool_id, PoolLike.user_id == user_id
            )
        )
    ).scalar_one_or_none()
    if not existing:
        return int(pool.likes or 0), False

    await db.execute(
        delete(PoolLike).where(PoolLike.pool_id == pool_id, PoolLike.user_id == user_id)
    )
    pool.likes = max(0, int(pool.likes or 0) - 1)
    await db.commit()
    await db.refresh(pool)
    return int(pool.likes or 0), False

