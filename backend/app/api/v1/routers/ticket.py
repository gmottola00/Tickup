from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.schemas.ticket import Ticket, TicketCreate
from app.services.ticket import create_ticket, get_ticket, update_ticket, delete_ticket
from app.api.v1.deps import get_db_dep

router = APIRouter()

@router.post("/", response_model=Ticket)
async def create(item: TicketCreate, db: AsyncSession = Depends(get_db_dep)):
    return await create_ticket(db, item)

@router.get("/{ticket_id}", response_model=Ticket)
async def read(ticket_id: int, db: AsyncSession = Depends(get_db_dep)):
    ticket = await get_ticket(db, ticket_id)
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    return ticket

@router.put("/{ticket_id}", response_model=Ticket)
async def update(ticket_id: int, item: TicketCreate, db: AsyncSession = Depends(get_db_dep)):
    ticket = await get_ticket(db, ticket_id)
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    return await update_ticket(db, ticket, item.dict())

@router.delete("/{ticket_id}", status_code=204)
async def delete(ticket_id: int, db: AsyncSession = Depends(get_db_dep)):
    ticket = await get_ticket(db, ticket_id)
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    await delete_ticket(db, ticket)
