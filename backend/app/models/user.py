import uuid
from sqlalchemy import Column, Integer, String, Text, DateTime, func
from sqlalchemy.dialects.postgresql import UUID
from app.db.base import Base

class User(Base):
    __tablename__ = "app_user"

    user_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    nickname = Column(Text, nullable=False)
    avatar_url = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
