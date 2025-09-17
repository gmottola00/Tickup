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

class PurchaseCreate(PurchaseBase):
    pass

class PurchaseUpdate(BaseModel):
    type: Optional[PurchaseType] = None
    status: Optional[PurchaseStatus] = None
    provider_txn_id: Optional[str] = None

class Purchase(PurchaseBase):
    purchase_id: UUID
    user_id: UUID
    created_at: datetime

    class Config:
        orm_mode = True
