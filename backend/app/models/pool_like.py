import uuid
from sqlalchemy import Column, DateTime, ForeignKey, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID

from app.db.base import Base


class PoolLike(Base):
    __tablename__ = "pool_like"

    # Composite PK (pool_id, user_id)
    pool_id = Column(
        UUID(as_uuid=True),
        ForeignKey("raffle_pool.pool_id", ondelete="CASCADE"),
        primary_key=True,
    )
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("app_user.user_id", ondelete="CASCADE"),
        primary_key=True,
    )
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint("pool_id", "user_id", name="uq_pool_like_pool_user"),
    )

