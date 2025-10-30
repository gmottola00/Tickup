from datetime import datetime, timedelta
from enum import Enum
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, func, Boolean, Text, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
from app.db.base import Base

class TournamentStatus(str, Enum):
    READY = "ready"
    ACTIVE = "active" 
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class Tournament(Base):
    __tablename__ = "tournaments"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    pool_id = Column(UUID(as_uuid=True), ForeignKey("raffle_pool.pool_id"), unique=True, nullable=False)
    title = Column(String(200), nullable=False)
    description = Column(Text)
    status = Column(String, default=TournamentStatus.READY)
    total_phases = Column(Integer, nullable=False)
    current_phase = Column(Integer, default=0)
    scheduled_start_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    completed_at = Column(DateTime(timezone=True))

    # Relationships
    pool = relationship("RafflePool", back_populates="tournament")
    phases = relationship("TournamentPhase", back_populates="tournament", cascade="all, delete-orphan")
    participants = relationship("TournamentParticipant", back_populates="tournament")

    def is_ready_to_start(self) -> bool:
        return (
            self.status == TournamentStatus.READY and
            self.scheduled_start_at and
            datetime.utcnow() >= self.scheduled_start_at
        )

    def get_current_active_phase(self):
        return next((phase for phase in self.phases if phase.status == "active"), None)