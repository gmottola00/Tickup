from datetime import datetime, timedelta
from enum import Enum
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, func, Boolean, Text, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
from app.db.base import Base

class PhaseStatus(str, Enum):
    SCHEDULED = "scheduled"
    ACTIVE = "active"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class TournamentPhase(Base):
    __tablename__ = "tournament_phases"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tournament_id = Column(UUID(as_uuid=True), ForeignKey("tournaments.id"), nullable=False)
    phase_number = Column(Integer, nullable=False)
    game_id = Column(UUID(as_uuid=True), ForeignKey("games.id"), nullable=False)
    level_id = Column(UUID(as_uuid=True), ForeignKey("levels.id"))
    title = Column(String(100), nullable=False)
    description = Column(Text)
    duration_hours = Column(Integer, default=72)  # 3 days default
    elimination_rule = Column(JSON)  # {"type": "top_percentage", "value": 50}
    min_score = Column(Integer)
    max_time_seconds = Column(Integer)
    status = Column(String, default=PhaseStatus.SCHEDULED)
    started_at = Column(DateTime(timezone=True))
    deadline_at = Column(DateTime(timezone=True))
    participants_count = Column(Integer, default=0)
    qualified_count = Column(Integer, default=0)

    # Relationships
    tournament = relationship("Tournament", back_populates="phases")
    participants = relationship("TournamentParticipant", back_populates="phase")
    sessions = relationship("TournamentSession", back_populates="phase")

    def is_expired(self) -> bool:
        return self.deadline_at and datetime.utcnow() > self.deadline_at

    def start_phase(self):
        """Activate this phase and set deadline"""
        self.status = PhaseStatus.ACTIVE
        self.started_at = datetime.utcnow()
        self.deadline_at = self.started_at + timedelta(hours=self.duration_hours)

    def get_elimination_threshold(self, participants):
        """Calculate who should qualify based on elimination rules"""
        rule = self.elimination_rule or {}
        rule_type = rule.get('type', 'top_percentage')
        
        if rule_type == 'top_percentage':
            percentage = rule.get('value', 50)
            return int(len(participants) * percentage / 100)
        elif rule_type == 'min_score':
            return len([p for p in participants if p.best_score >= rule.get('value', 0)])
        elif rule_type == 'max_time':
            return len([p for p in participants if p.best_time_seconds <= rule.get('value', float('inf'))])
        
        return len(participants)  # fallback