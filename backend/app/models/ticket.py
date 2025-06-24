from sqlalchemy import Column, Integer, ForeignKey, DateTime, func
from sqlalchemy.dialects.postgresql import UUID
from app.db.base import Base

class Ticket(Base):
    __tablename__ = "ticket"

    ticket_id = Column(Integer, primary_key=True, autoincrement=True)
    pool_id = Column(UUID(as_uuid=True), ForeignKey("raffle_pool.pool_id"), nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("app_user.user_id"), nullable=False)
    purchase_id = Column(UUID(as_uuid=True), ForeignKey("purchase.purchase_id"), nullable=False)
    ticket_num = Column(Integer)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
