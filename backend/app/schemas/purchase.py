from enum import Enum
from datetime import datetime
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, Field

class PurchaseType(str, Enum):
    ENTRY = "ENTRY"
    BOOST = "BOOST"
    RETRY = "RETRY"

class PurchaseStatus(str, Enum):
    PENDING = "PENDING"
    CONFIRMED = "CONFIRMED"
    FAILED = "FAILED"

class PurchaseBase(BaseModel):
    type: PurchaseType = PurchaseType.ENTRY
    amount_cents: int = Field(..., gt=0)
    currency: str = Field(default="EUR", min_length=3, max_length=3)
    provider_txn_id: Optional[str] = None
    status: PurchaseStatus = PurchaseStatus.PENDING
    pool_id: UUID

class PurchaseCreate(PurchaseBase):
    wallet_entry_id: Optional[int] = None
    wallet_hold_id: Optional[UUID] = None

class PurchaseUpdate(BaseModel):
    type: Optional[PurchaseType] = None
    status: Optional[PurchaseStatus] = None
    provider_txn_id: Optional[str] = None
    pool_id: Optional[UUID] = None
    wallet_entry_id: Optional[int] = None
    wallet_hold_id: Optional[UUID] = None

class Purchase(PurchaseBase):
    purchase_id: UUID
    user_id: UUID
    created_at: datetime
    wallet_entry_id: Optional[int] = None
    wallet_hold_id: Optional[UUID] = None

    class Config:
        orm_mode = True
