import uuid
from enum import Enum
from sqlalchemy import (
    Column,
    Integer,
    String,
    ForeignKey,
    DateTime,
    func,
    CheckConstraint,
    BigInteger,
)
from sqlalchemy.dialects.postgresql import UUID
from app.db.base import Base

class PurchaseType(str, Enum):
    ENTRY = "ENTRY"
    BOOST = "BOOST"
    RETRY = "RETRY"

class PurchaseStatus(str, Enum):
    PENDING = "PENDING"
    CONFIRMED = "CONFIRMED"
    FAILED = "FAILED"

class Purchase(Base):
    __tablename__ = "purchase"
    __table_args__ = (
        CheckConstraint("type IN ('ENTRY','BOOST','RETRY')", name="ck_purchase_type"),
        CheckConstraint("status IN ('PENDING','CONFIRMED','FAILED')", name="ck_purchase_status"),
    )

    purchase_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("app_user.user_id"), nullable=False)
    pool_id = Column(UUID(as_uuid=True), ForeignKey("raffle_pool.pool_id"), nullable=False)
    wallet_entry_id = Column(BigInteger, ForeignKey("wallet_ledger.entry_id"), nullable=True)
    wallet_hold_id = Column(UUID(as_uuid=True), ForeignKey("wallet_hold.hold_id"), nullable=True)
    type = Column(String, nullable=False, default=PurchaseType.ENTRY.value)
    amount_cents = Column(Integer, nullable=False)
    currency = Column(String(3), nullable=False, default="EUR")
    provider_txn_id = Column(String, nullable=True)
    status = Column(String, nullable=False, default=PurchaseStatus.PENDING.value)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
