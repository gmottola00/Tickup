from typing import Sequence
from uuid import UUID
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.purchase import Purchase
from app.schemas.purchase import PurchaseCreate, PurchaseUpdate

async def create_purchase(
    db: AsyncSession,
    user_id: UUID,
    purchase_in: PurchaseCreate,
) -> Purchase:
    purchase = Purchase(user_id=user_id, **purchase_in.model_dump())
    db.add(purchase)
    await db.commit()
    await db.refresh(purchase)
    return purchase

async def get_purchase(db: AsyncSession, purchase_id: UUID) -> Purchase | None:
    return await db.get(Purchase, purchase_id)

async def get_all_purchases(db: AsyncSession) -> Sequence[Purchase]:
    result = await db.execute(select(Purchase))
    return result.scalars().all()

async def get_user_purchases(db: AsyncSession, user_id: UUID) -> Sequence[Purchase]:
    stmt = select(Purchase).where(Purchase.user_id == user_id)
    result = await db.execute(stmt)
    return result.scalars().all()

async def update_purchase(
    db: AsyncSession,
    purchase: Purchase,
    data: PurchaseUpdate,
) -> Purchase:
    payload = data.model_dump(exclude_unset=True)
    if not payload:
        return purchase
    for key, value in payload.items():
        setattr(purchase, key, value)
    await db.commit()
    await db.refresh(purchase)
    return purchase

async def delete_purchase(db: AsyncSession, purchase: Purchase) -> None:
    await db.delete(purchase)
    await db.commit()
