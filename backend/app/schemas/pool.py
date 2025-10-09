from datetime import datetime
from uuid import UUID
from pydantic import BaseModel

class PoolBase(BaseModel):
    prize_id: UUID
    ticket_price_cents: int
    tickets_required: int

class PoolCreate(PoolBase):
    pass

class Pool(PoolBase):
    pool_id: UUID
    tickets_sold: int
    likes: int
    state: str
    created_at: datetime

    class Config:
        orm_mode = True


class LikeStatus(BaseModel):
    likes: int
    liked_by_me: bool
