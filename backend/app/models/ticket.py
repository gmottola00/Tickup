from sqlalchemy import (
    Column,
    BigInteger,
    Integer,
    ForeignKey,
    DateTime,
    func,
    UniqueConstraint,
    CheckConstraint,
)
from sqlalchemy.dialects.postgresql import UUID
from app.db.base import Base

class Ticket(Base):
    __tablename__ = "ticket"
    __table_args__ = (
        UniqueConstraint("pool_id", "ticket_num", name="uq_ticket_pool_ticketnum"),
        CheckConstraint("ticket_num > 0", name="ck_ticket_positive"),
    )

    ticket_id = Column(BigInteger, primary_key=True, autoincrement=True)
    pool_id = Column(UUID(as_uuid=True), ForeignKey("raffle_pool.pool_id"), nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("app_user.user_id"), nullable=False)
    purchase_id = Column(UUID(as_uuid=True), ForeignKey("purchase.purchase_id"), nullable=False)
    ticket_num = Column(Integer, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
