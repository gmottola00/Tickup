from pydantic import BaseModel
from uuid import UUID
from datetime import datetime

class PrizeBase(BaseModel):
    title: str
    description: str
    value_cents: int

class PrizeCreate(PrizeBase):
    image_url: str = None
    sponsor: str = None
    stock: int = 1

class Prize(PrizeBase):
    prize_id: UUID
    image_url: str
    sponsor: str
    stock: int
    created_at: datetime

    class Config:
        orm_mode = True
