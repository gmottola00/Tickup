from pydantic import BaseModel
from uuid import UUID
from datetime import datetime

class TicketBase(BaseModel):
    pool_id: UUID
    user_id: UUID
    purchase_id: UUID
    ticket_num: int

class TicketCreate(TicketBase):
    pass

class Ticket(TicketBase):
    ticket_id: int
    created_at: datetime

    class Config:
        orm_mode = True
