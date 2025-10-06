import uuid
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, func
from sqlalchemy.dialects.postgresql import UUID
from app.db.base import Base

class RafflePool(Base):
    __tablename__ = "raffle_pool"

    pool_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    prize_id = Column(UUID(as_uuid=True), ForeignKey("prize.prize_id"), nullable=False)
    ticket_price_cents = Column(Integer, nullable=False)
    tickets_required = Column(Integer, nullable=False)
    tickets_sold = Column(Integer, default=0)
    likes = Column(Integer, default=0)
    state = Column(String, default="OPEN")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
