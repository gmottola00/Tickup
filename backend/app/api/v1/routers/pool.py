from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.pool import Pool, PoolCreate
from app.schemas.ticket import Ticket, TicketPurchaseRequest
from app.services.pool import (
    create_pool,
    get_pool,
    update_pool,
    delete_pool,
    get_all_pool,
    get_pools_by_user,
)
from app.services.ticket import purchase_ticket_for_pool
from app.api.v1.deps import get_db_dep
from app.api.v1.auth import get_current_user_id

router = APIRouter()

@router.post("/", response_model=Pool)
async def create(item: PoolCreate, db: AsyncSession = Depends(get_db_dep)):
    return await create_pool(db, item)

@router.get("/all_pools", response_model=list[Pool])
async def read_all(db: AsyncSession = Depends(get_db_dep)):
    pools = await get_all_pool(db)
    return pools

@router.get("/my", response_model=list[Pool])
async def read_my(
    db: AsyncSession = Depends(get_db_dep),
    user_id: str = Depends(get_current_user_id),
):
    pools = await get_pools_by_user(db, user_id)
    return pools

@router.get("/{pool_id}", response_model=Pool)
async def read(pool_id: str, db: AsyncSession = Depends(get_db_dep)):
    pool = await get_pool(db, pool_id)
    if not pool:
        raise HTTPException(status_code=404, detail="Pool not found")
    return pool

@router.put("/{pool_id}", response_model=Pool)
async def update(pool_id: str, item: PoolCreate, db: AsyncSession = Depends(get_db_dep)):
    pool = await get_pool(db, pool_id)
    if not pool:
        raise HTTPException(status_code=404, detail="Pool not found")
    return await update_pool(db, pool, item.dict())

@router.delete("/{pool_id}", status_code=204)
async def delete(pool_id: str, db: AsyncSession = Depends(get_db_dep)):
    pool = await get_pool(db, pool_id)
    if not pool:
        raise HTTPException(status_code=404, detail="Pool not found")
    await delete_pool(db, pool)

@router.post("/{pool_id}/tickets", response_model=Ticket, status_code=201)
async def purchase_ticket(
    pool_id: str,
    payload: TicketPurchaseRequest,
    db: AsyncSession = Depends(get_db_dep),
    user_sub: str = Depends(get_current_user_id),
):
    try:
        pool_uuid = UUID(pool_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid pool id")
    try:
        user_uuid = UUID(user_sub)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user identifier")

    ticket, _ = await purchase_ticket_for_pool(db, pool_uuid, user_uuid, payload.purchase_id)
    return ticket
