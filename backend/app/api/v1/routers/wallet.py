from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.auth import get_current_user_id
from app.api.v1.deps import get_db_dep
from app.models.wallet import WalletLedgerReason as WalletLedgerReasonModel
from app.schemas.wallet import (
    WalletAccount,
    WalletDebitCreate,
    WalletLedgerEntry,
    WalletLedgerList,
    WalletTopupComplete,
    WalletTopupCreate,
    WalletTopupRequest,
    WalletTopupWithEntry,
)
from app.services.wallet import (
    complete_topup_request,
    create_topup_request,
    create_wallet_debit,
    get_or_create_wallet,
    get_topup_request,
    list_topup_requests,
    list_wallet_ledger,
)

router = APIRouter()


def _parse_user_id(user_sub: str) -> UUID:
    try:
        return UUID(user_sub)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user identifier")


@router.get("/me", response_model=WalletAccount)
async def get_my_wallet(
    db: AsyncSession = Depends(get_db_dep),
    user_sub: str = Depends(get_current_user_id),
):
    user_id = _parse_user_id(user_sub)
    wallet = await get_or_create_wallet(db, user_id)
    return wallet


@router.get("/me/ledger", response_model=WalletLedgerList)
async def read_my_ledger(
    db: AsyncSession = Depends(get_db_dep),
    user_sub: str = Depends(get_current_user_id),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
):
    user_id = _parse_user_id(user_sub)
    wallet = await get_or_create_wallet(db, user_id)
    items, total = await list_wallet_ledger(db, wallet.wallet_id, limit=limit, offset=offset)
    return WalletLedgerList(items=list(items), total=total)


@router.post("/me/ledger/debit", response_model=WalletLedgerEntry, status_code=status.HTTP_201_CREATED)
async def create_ledger_debit(
    payload: WalletDebitCreate,
    db: AsyncSession = Depends(get_db_dep),
    user_sub: str = Depends(get_current_user_id),
):
    user_id = _parse_user_id(user_sub)
    wallet = await get_or_create_wallet(db, user_id)
    entry = await create_wallet_debit(
        db,
        wallet,
        amount_cents=payload.amount_cents,
        reason=WalletLedgerReasonModel(payload.reason.value),
        ref_purchase_id=payload.ref_purchase_id,
        ref_pool_id=payload.ref_pool_id,
        ref_ticket_id=payload.ref_ticket_id,
        ref_external_txn=payload.ref_external_txn,
    )
    return entry


@router.post("/topups", response_model=WalletTopupRequest, status_code=status.HTTP_201_CREATED)
async def create_topup(
    payload: WalletTopupCreate,
    db: AsyncSession = Depends(get_db_dep),
    user_sub: str = Depends(get_current_user_id),
):
    user_id = _parse_user_id(user_sub)
    wallet = await get_or_create_wallet(db, user_id)
    topup = await create_topup_request(
        db,
        wallet,
        provider=payload.provider,
        amount_cents=payload.amount_cents,
        provider_txn_id=payload.provider_txn_id,
    )
    return topup


@router.get("/topups", response_model=list[WalletTopupRequest])
async def list_topups(
    db: AsyncSession = Depends(get_db_dep),
    user_sub: str = Depends(get_current_user_id),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
):
    user_id = _parse_user_id(user_sub)
    wallet = await get_or_create_wallet(db, user_id)
    topups = await list_topup_requests(db, wallet.wallet_id, limit=limit, offset=offset)
    return list(topups)


@router.post("/topups/{topup_id}/complete", response_model=WalletTopupWithEntry)
async def complete_topup(
    topup_id: UUID,
    payload: WalletTopupComplete,
    db: AsyncSession = Depends(get_db_dep),
    user_sub: str = Depends(get_current_user_id),
):
    user_id = _parse_user_id(user_sub)
    wallet = await get_or_create_wallet(db, user_id)
    topup = await get_topup_request(db, topup_id)
    if not topup or topup.wallet_id != wallet.wallet_id:
        raise HTTPException(status_code=404, detail="Top-up non trovato")

    updated_topup, ledger_entry = await complete_topup_request(
        db,
        wallet,
        topup,
        provider_txn_id=payload.provider_txn_id,
    )
    return WalletTopupWithEntry(topup=updated_topup, ledger_entry=ledger_entry)
