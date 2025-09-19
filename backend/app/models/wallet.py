import uuid
from enum import Enum
from sqlalchemy import (
    Column,
    BigInteger,
    Integer,
    String,
    DateTime,
    func,
    ForeignKey,
    CheckConstraint,
    UniqueConstraint,
    Index,
)
from sqlalchemy.dialects.postgresql import UUID
from app.db.base import Base


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


class WalletAccount(Base):
    __tablename__ = "wallet_account"
    __table_args__ = (
        UniqueConstraint("user_id", name="uq_wallet_account_user"),
    )

    wallet_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("app_user.user_id"), nullable=False)
    balance_cents = Column(Integer, nullable=False, default=0)
    currency = Column(String(3), nullable=False, default="EUR")
    status = Column(String, nullable=False, default=WalletStatus.ACTIVE.value)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class WalletLedgerEntry(Base):
    __tablename__ = "wallet_ledger"
    __table_args__ = (
        CheckConstraint("amount_cents > 0", name="ck_wallet_ledger_amount_positive"),
        Index("ix_wallet_ledger_wallet_created_at", "wallet_id", "created_at"),
    )

    entry_id = Column(BigInteger, primary_key=True, autoincrement=True)
    wallet_id = Column(UUID(as_uuid=True), ForeignKey("wallet_account.wallet_id"), nullable=False)
    direction = Column(String, nullable=False)
    amount_cents = Column(Integer, nullable=False)
    reason = Column(String, nullable=False)
    status = Column(String, nullable=False, default=WalletLedgerEntryStatus.PENDING.value)
    ref_purchase_id = Column(UUID(as_uuid=True), ForeignKey("purchase.purchase_id"), nullable=True)
    ref_pool_id = Column(UUID(as_uuid=True), ForeignKey("raffle_pool.pool_id"), nullable=True)
    ref_ticket_id = Column(BigInteger, ForeignKey("ticket.ticket_id"), nullable=True)
    ref_external_txn = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class WalletTopupRequest(Base):
    __tablename__ = "wallet_topup_request"
    __table_args__ = (
        UniqueConstraint("provider_txn_id", name="uq_wallet_topup_provider_txn"),
        CheckConstraint("amount_cents > 0", name="ck_wallet_topup_amount_positive"),
    )

    topup_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    wallet_id = Column(UUID(as_uuid=True), ForeignKey("wallet_account.wallet_id"), nullable=False)
    provider = Column(String, nullable=False)
    provider_txn_id = Column(String, nullable=True)
    amount_cents = Column(Integer, nullable=False)
    status = Column(String, nullable=False, default=WalletTopupStatus.CREATED.value)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    completed_at = Column(DateTime(timezone=True), nullable=True)


class WalletWithdrawalRequest(Base):
    __tablename__ = "wallet_withdrawal_request"
    __table_args__ = (
        UniqueConstraint("provider_txn_id", name="uq_wallet_withdrawal_provider_txn"),
        CheckConstraint("amount_cents > 0", name="ck_wallet_withdrawal_amount_positive"),
    )

    withdrawal_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    wallet_id = Column(UUID(as_uuid=True), ForeignKey("wallet_account.wallet_id"), nullable=False)
    provider = Column(String, nullable=False)
    provider_txn_id = Column(String, nullable=True)
    amount_cents = Column(Integer, nullable=False)
    status = Column(String, nullable=False, default=WalletWithdrawalStatus.CREATED.value)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    completed_at = Column(DateTime(timezone=True), nullable=True)


class WalletHold(Base):
    __tablename__ = "wallet_hold"
    __table_args__ = (
        CheckConstraint("amount_cents > 0", name="ck_wallet_hold_amount_positive"),
    )

    hold_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    wallet_id = Column(UUID(as_uuid=True), ForeignKey("wallet_account.wallet_id"), nullable=False)
    amount_cents = Column(Integer, nullable=False)
    reason = Column(String, nullable=False, default="TICKET_RESERVATION")
    status = Column(String, nullable=False, default=WalletHoldStatus.ACTIVE.value)
    ref_purchase_id = Column(UUID(as_uuid=True), ForeignKey("purchase.purchase_id"), nullable=True)
    ref_pool_id = Column(UUID(as_uuid=True), ForeignKey("raffle_pool.pool_id"), nullable=True)
    expires_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), nullable=True)
