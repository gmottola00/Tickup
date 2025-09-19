from typing import Sequence
from uuid import UUID
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from fastapi import HTTPException

from app.models.purchase import Purchase, PurchaseStatus, PurchaseType
from app.schemas.purchase import PurchaseCreate, PurchaseUpdate
from app.services.ticket import purchase_ticket_for_pool

async def create_purchase(
    db: AsyncSession,
    user_id: UUID,
    purchase_in: PurchaseCreate,
) -> Purchase:
    pool_id = purchase_in.pool_id
    wallet_entry_id = purchase_in.wallet_entry_id
    wallet_hold_id = purchase_in.wallet_hold_id
    data = purchase_in.model_dump(
        exclude={"pool_id", "wallet_entry_id", "wallet_hold_id"}
    )
    data["type"] = purchase_in.type.value
    data["status"] = purchase_in.status.value

    if (
        data["status"] == PurchaseStatus.CONFIRMED.value
        and wallet_entry_id is None
    ):
        raise HTTPException(
            status_code=400,
            detail="Confirmed purchase requires a wallet ledger entry",
        )

    purchase = Purchase(
        user_id=user_id,
        pool_id=pool_id,
        wallet_entry_id=wallet_entry_id,
        wallet_hold_id=wallet_hold_id,
        **data,
    )
    db.add(purchase)
    await db.flush()

    should_issue_ticket = (
        purchase.type == PurchaseType.ENTRY.value
        and purchase.status == PurchaseStatus.CONFIRMED.value
    )

    if should_issue_ticket:
        if purchase.wallet_entry_id is None:
            await db.rollback()
            raise HTTPException(
                status_code=400,
                detail="Confirmed purchase requires a wallet ledger entry",
            )
        try:
            await purchase_ticket_for_pool(db, pool_id, user_id, purchase.purchase_id)
        except HTTPException as exc:
            await db.rollback()
            raise exc
        await db.refresh(purchase)
        return purchase

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
    if "status" in payload and isinstance(payload["status"], PurchaseStatus):
        payload["status"] = payload["status"].value
    if "type" in payload and isinstance(payload["type"], PurchaseType):
        payload["type"] = payload["type"].value
    if not payload:
        return purchase

    previous_status = purchase.status
    pool_id = payload.get('pool_id') or purchase.pool_id

    new_status = payload.get('status', purchase.status)
    new_wallet_entry_id = payload.get('wallet_entry_id', purchase.wallet_entry_id)

    if (
        new_status == PurchaseStatus.CONFIRMED.value
        and new_wallet_entry_id is None
    ):
        raise HTTPException(
            status_code=400,
            detail="Confirmed purchase requires a wallet ledger entry",
        )

    for key, value in payload.items():
        setattr(purchase, key, value)
    await db.flush()

    should_issue_ticket = (
        purchase.type == PurchaseType.ENTRY.value
        and purchase.status == PurchaseStatus.CONFIRMED.value
        and previous_status != PurchaseStatus.CONFIRMED.value
    )

    if should_issue_ticket:
        if purchase.wallet_entry_id is None:
            await db.rollback()
            raise HTTPException(
                status_code=400,
                detail="Confirmed purchase requires a wallet ledger entry",
            )
        try:
            await purchase_ticket_for_pool(
                db,
                pool_id,
                purchase.user_id,
                purchase.purchase_id,
            )
        except HTTPException as exc:
            await db.rollback()
            raise exc
        await db.refresh(purchase)
        return purchase

    await db.commit()
    await db.refresh(purchase)
    return purchase

async def delete_purchase(db: AsyncSession, purchase: Purchase) -> None:
    await db.delete(purchase)
    await db.commit()
