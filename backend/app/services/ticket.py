from sqlalchemy.ext.asyncio import AsyncSession
from app.models.ticket import Ticket
from app.schemas.ticket import TicketCreate

async def create_ticket(db: AsyncSession, ticket_in: TicketCreate) -> Ticket:
    ticket = Ticket(**ticket_in.dict())
    db.add(ticket)
    await db.commit()
    await db.refresh(ticket)
    return ticket

async def get_ticket(db: AsyncSession, ticket_id: int):
    return await db.get(Ticket, ticket_id)

async def update_ticket(db: AsyncSession, ticket: Ticket, data: dict):
    for key, value in data.items():
        setattr(ticket, key, value)
    await db.commit()
    await db.refresh(ticket)
    return ticket

async def delete_ticket(db: AsyncSession, ticket: Ticket):
    await db.delete(ticket)
    await db.commit()
