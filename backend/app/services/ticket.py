from uuid import UUID
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException

from app.models.ticket import Ticket
from app.models.pool import RafflePool
from app.models.purchase import Purchase, PurchaseStatus, PurchaseType
from app.schemas.ticket import TicketCreate

async def create_ticket(db: AsyncSession, ticket_in: TicketCreate) -> Ticket:
    ticket, _ = await purchase_ticket_for_pool(
        db,
        ticket_in.pool_id,
        ticket_in.user_id,
        ticket_in.purchase_id,
    )
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

async def purchase_ticket_for_pool(
    db: AsyncSession,
    pool_id: UUID,
    user_id: UUID,
    purchase_id: UUID,
):
    pool = await db.get(RafflePool, pool_id)
    if not pool:
        raise HTTPException(status_code=404, detail="Pool not found")

    if pool.state != "OPEN":
        raise HTTPException(status_code=400, detail="Pool is not open")

    sold_query = select(func.count()).select_from(Ticket).where(Ticket.pool_id == pool.pool_id)
    result = await db.execute(sold_query)
    current_sold = result.scalar_one() or 0

    if current_sold >= pool.tickets_required:
        pool.state = "FULL"
        await db.commit()
        raise HTTPException(status_code=400, detail="Pool is already full")

    purchase = await db.get(Purchase, purchase_id)
    if not purchase:
        raise HTTPException(status_code=404, detail="Purchase not found")
    if purchase.user_id != user_id:
        raise HTTPException(status_code=403, detail="Purchase does not belong to user")
    if purchase.type != PurchaseType.ENTRY.value:
        raise HTTPException(status_code=400, detail="Purchase type not valid for pool entry")
    if purchase.status != PurchaseStatus.CONFIRMED.value:
        raise HTTPException(status_code=400, detail="Purchase not confirmed")
    if purchase.wallet_entry_id is None:
        raise HTTPException(
            status_code=400,
            detail="Purchase is missing wallet ledger entry for ticket issuance",
        )

    existing_ticket = await db.execute(
        select(Ticket).where(Ticket.purchase_id == purchase.purchase_id)
    )
    if existing_ticket.scalars().first() is not None:
        raise HTTPException(status_code=400, detail="Purchase already redeemed")

    ticket_num = current_sold + 1
    ticket = Ticket(
        pool_id=pool.pool_id,
        user_id=user_id,
        purchase_id=purchase.purchase_id,
        wallet_entry_id=purchase.wallet_entry_id,
        ticket_num=ticket_num,
    )
    db.add(ticket)

    if pool.tickets_sold >= pool.tickets_required:
        pool.state = "FULL"

    await db.commit()

    await db.refresh(ticket)
    await db.refresh(pool)

    return ticket, pool
