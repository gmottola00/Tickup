import uuid
from sqlalchemy import Column, Text, Boolean, Integer, DateTime, ForeignKey, UniqueConstraint, Index, func
from sqlalchemy.dialects.postgresql import UUID

from app.db.base import Base


class PrizeImage(Base):
    __tablename__ = "prize_image"

    image_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    prize_id = Column(UUID(as_uuid=True), ForeignKey("prize.prize_id", ondelete="CASCADE"), nullable=False)
    bucket = Column(Text, nullable=False)
    storage_path = Column(Text, nullable=False)
    url = Column(Text, nullable=False)
    is_cover = Column(Boolean, nullable=False, default=False)
    sort_order = Column(Integer)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint("prize_id", "storage_path", name="uq_prize_image_storage"),
        Index("ix_prize_image_prize_sort", "prize_id", "sort_order"),
    )

