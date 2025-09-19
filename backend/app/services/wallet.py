from datetime import datetime, timezone
from typing import Sequence
from uuid import UUID

from fastapi import HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.wallet import (
    WalletAccount,
    WalletLedgerEntry,
    WalletLedgerDirection,
    WalletLedgerEntryStatus,
    WalletLedgerReason,
    WalletTopupRequest,
    WalletTopupStatus,
)


async def get_wallet_by_user(
    db: AsyncSession,
    user_id: UUID,
) -> WalletAccount | None:
    result = await db.execute(
        select(WalletAccount).where(WalletAccount.user_id == user_id)
    )
    return result.scalar_one_or_none()


async def get_or_create_wallet(
    db: AsyncSession,
    user_id: UUID,
) -> WalletAccount:
    wallet = await get_wallet_by_user(db, user_id)
    if wallet:
        return wallet

    wallet = WalletAccount(user_id=user_id)
    db.add(wallet)
    await db.commit()
    await db.refresh(wallet)
    return wallet


async def get_wallet_by_id(
    db: AsyncSession,
    wallet_id: UUID,
) -> WalletAccount | None:
    return await db.get(WalletAccount, wallet_id)


async def list_wallet_ledger(
    db: AsyncSession,
    wallet_id: UUID,
    *,
    limit: int = 50,
    offset: int = 0,
) -> tuple[Sequence[WalletLedgerEntry], int]:
    stmt = (
        select(WalletLedgerEntry)
        .where(WalletLedgerEntry.wallet_id == wallet_id)
        .order_by(WalletLedgerEntry.created_at.desc())
        .offset(offset)
        .limit(limit)
    )
    result = await db.execute(stmt)
    items = result.scalars().all()

    count_stmt = (
        select(func.count())
        .select_from(WalletLedgerEntry)
        .where(WalletLedgerEntry.wallet_id == wallet_id)
    )
    total = (await db.execute(count_stmt)).scalar_one()
    return items, total


async def _create_wallet_entry(
    db: AsyncSession,
    wallet: WalletAccount,
    *,
    direction: WalletLedgerDirection,
    amount_cents: int,
    reason: WalletLedgerReason,
    status: WalletLedgerEntryStatus = WalletLedgerEntryStatus.POSTED,
    ref_purchase_id: UUID | None = None,
    ref_pool_id: UUID | None = None,
    ref_ticket_id: int | None = None,
    ref_external_txn: str | None = None,
    commit: bool = True,
) -> WalletLedgerEntry:
    if amount_cents <= 0:
        raise HTTPException(status_code=400, detail="Amount must be greater than zero")

    if direction == WalletLedgerDirection.DEBIT and wallet.balance_cents < amount_cents:
        raise HTTPException(status_code=400, detail="Saldo insufficiente")

    if direction == WalletLedgerDirection.DEBIT:
        wallet.balance_cents -= amount_cents
    else:
        wallet.balance_cents += amount_cents

    entry = WalletLedgerEntry(
        wallet_id=wallet.wallet_id,
        direction=direction.value,
        amount_cents=amount_cents,
        reason=reason.value,
        status=status.value,
        ref_purchase_id=ref_purchase_id,
        ref_pool_id=ref_pool_id,
        ref_ticket_id=ref_ticket_id,
        ref_external_txn=ref_external_txn,
    )
    db.add(entry)

    if commit:
        await db.commit()
        await db.refresh(entry)
        await db.refresh(wallet)
    else:
        await db.flush()

    return entry


async def create_wallet_debit(
    db: AsyncSession,
    wallet: WalletAccount,
    *,
    amount_cents: int,
    reason: WalletLedgerReason,
    ref_purchase_id: UUID | None = None,
    ref_pool_id: UUID | None = None,
    ref_ticket_id: int | None = None,
    ref_external_txn: str | None = None,
) -> WalletLedgerEntry:
    entry = await _create_wallet_entry(
        db,
        wallet,
        direction=WalletLedgerDirection.DEBIT,
        amount_cents=amount_cents,
        reason=reason,
        ref_purchase_id=ref_purchase_id,
        ref_pool_id=ref_pool_id,
        ref_ticket_id=ref_ticket_id,
        ref_external_txn=ref_external_txn,
    )
    return entry


async def create_wallet_credit(
    db: AsyncSession,
    wallet: WalletAccount,
    *,
    amount_cents: int,
    reason: WalletLedgerReason,
    ref_external_txn: str | None = None,
    commit: bool = True,
) -> WalletLedgerEntry:
    entry = await _create_wallet_entry(
        db,
        wallet,
        direction=WalletLedgerDirection.CREDIT,
        amount_cents=amount_cents,
        reason=reason,
        ref_external_txn=ref_external_txn,
        commit=commit,
    )
    return entry


async def create_topup_request(
    db: AsyncSession,
    wallet: WalletAccount,
    *,
    provider: str,
    amount_cents: int,
    provider_txn_id: str | None = None,
) -> WalletTopupRequest:
    topup = WalletTopupRequest(
        wallet_id=wallet.wallet_id,
        provider=provider,
        provider_txn_id=provider_txn_id,
        amount_cents=amount_cents,
        status=WalletTopupStatus.CREATED.value,
    )
    db.add(topup)
    await db.commit()
    await db.refresh(topup)
    return topup


async def list_topup_requests(
    db: AsyncSession,
    wallet_id: UUID,
    *,
    limit: int = 50,
    offset: int = 0,
) -> Sequence[WalletTopupRequest]:
    stmt = (
        select(WalletTopupRequest)
        .where(WalletTopupRequest.wallet_id == wallet_id)
        .order_by(WalletTopupRequest.created_at.desc())
        .offset(offset)
        .limit(limit)
    )
    result = await db.execute(stmt)
    return result.scalars().all()


async def get_topup_request(
    db: AsyncSession,
    topup_id: UUID,
) -> WalletTopupRequest | None:
    return await db.get(WalletTopupRequest, topup_id)


async def complete_topup_request(
    db: AsyncSession,
    wallet: WalletAccount,
    topup: WalletTopupRequest,
    *,
    provider_txn_id: str | None = None,
) -> tuple[WalletTopupRequest, WalletLedgerEntry]:
    if topup.status == WalletTopupStatus.COMPLETED.value:
        raise HTTPException(status_code=400, detail="Top-up già completato")
    if topup.status in {
        WalletTopupStatus.FAILED.value,
        WalletTopupStatus.CANCELLED.value,
    }:
        raise HTTPException(status_code=400, detail="Impossibile completare il top-up nello stato attuale")

    if provider_txn_id:
        topup.provider_txn_id = provider_txn_id

    topup.status = WalletTopupStatus.COMPLETED.value
    topup.completed_at = datetime.now(timezone.utc)

    entry = await create_wallet_credit(
        db,
        wallet,
        amount_cents=topup.amount_cents,
        reason=WalletLedgerReason.TOPUP,
        ref_external_txn=topup.provider_txn_id,
        commit=False,
    )

    await db.commit()
    await db.refresh(topup)
    await db.refresh(entry)
    await db.refresh(wallet)
    return topup, entry
