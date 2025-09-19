from datetime import datetime
from uuid import UUID
from typing import Optional

from pydantic import BaseModel

class TicketBase(BaseModel):
    pool_id: UUID
    user_id: UUID
    purchase_id: UUID
    wallet_entry_id: Optional[int] = None

class TicketCreate(TicketBase):
    pass

class TicketPurchaseRequest(BaseModel):
    purchase_id: UUID

class Ticket(TicketBase):
    ticket_id: int
    ticket_num: int
    created_at: datetime

    class Config:
        orm_mode = True
