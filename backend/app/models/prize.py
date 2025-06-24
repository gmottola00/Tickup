import uuid
from sqlalchemy import Column, Integer, String, Text, DateTime, func
from sqlalchemy.dialects.postgresql import UUID
from app.db.base import Base

class Prize(Base):
    __tablename__ = "prize"

    prize_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String, nullable=False)
    description = Column(Text)
    value_cents = Column(Integer)
    image_url = Column(String)
    sponsor = Column(String)
    stock = Column(Integer, default=1)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
