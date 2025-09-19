from datetime import datetime
from enum import Enum
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field, ConfigDict


class WalletStatus(str, Enum):
    ACTIVE = "ACTIVE"
    SUSPENDED = "SUSPENDED"


class WalletLedgerDirection(str, Enum):
    DEBIT = "DEBIT"
    CREDIT = "CREDIT"


class WalletLedgerReason(str, Enum):
    TOPUP = "TOPUP"
    TICKET_PURCHASE = "TICKET_PURCHASE"
    REFUND = "REFUND"
    PRIZE_PAYOUT = "PRIZE_PAYOUT"
    ADJUSTMENT = "ADJUSTMENT"


class WalletLedgerEntryStatus(str, Enum):
    PENDING = "PENDING"
    POSTED = "POSTED"
    REVERSED = "REVERSED"


class WalletTopupStatus(str, Enum):
    CREATED = "CREATED"
    PROCESSING = "PROCESSING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    CANCELLED = "CANCELLED"


class WalletWithdrawalStatus(str, Enum):
    CREATED = "CREATED"
    PROCESSING = "PROCESSING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    CANCELLED = "CANCELLED"


class WalletHoldStatus(str, Enum):
    ACTIVE = "ACTIVE"
    RELEASED = "RELEASED"
    CAPTURED = "CAPTURED"


class WalletAccount(BaseModel):
    wallet_id: UUID
    user_id: UUID
    balance_cents: int
    currency: str
    status: WalletStatus
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class WalletLedgerBase(BaseModel):
    amount_cents: int = Field(..., gt=0)
    reason: WalletLedgerReason = WalletLedgerReason.TICKET_PURCHASE
    ref_purchase_id: Optional[UUID] = None
    ref_pool_id: Optional[UUID] = None
    ref_ticket_id: Optional[int] = None
    ref_external_txn: Optional[str] = None


class WalletDebitCreate(WalletLedgerBase):
    pass


class WalletLedgerEntry(WalletLedgerBase):
    entry_id: int
    wallet_id: UUID
    direction: WalletLedgerDirection
    status: WalletLedgerEntryStatus
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class WalletTopupCreate(BaseModel):
    amount_cents: int = Field(..., gt=0)
    provider: str = Field(..., min_length=1)
    provider_txn_id: Optional[str] = None


class WalletTopupComplete(BaseModel):
    provider_txn_id: Optional[str] = None


class WalletTopupRequest(BaseModel):
    topup_id: UUID
    wallet_id: UUID
    provider: str
    provider_txn_id: Optional[str]
    amount_cents: int
    status: WalletTopupStatus
    created_at: datetime
    completed_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class WalletTopupWithEntry(BaseModel):
    topup: WalletTopupRequest
    ledger_entry: WalletLedgerEntry


class WalletLedgerList(BaseModel):
    items: list[WalletLedgerEntry]
    total: int


class WalletBalance(BaseModel):
    wallet_id: UUID
    balance_cents: int
    currency: str

    model_config = ConfigDict(from_attributes=True)
