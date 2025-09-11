from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.schemas.pool import Pool, PoolCreate
from app.services.pool import (
    create_pool,
    get_pool,
    update_pool,
    delete_pool,
    get_all_pool,
)
from app.api.v1.deps import get_db_dep

router = APIRouter()

@router.post("/", response_model=Pool)
async def create(item: PoolCreate, db: AsyncSession = Depends(get_db_dep)):
    return await create_pool(db, item)

@router.get("/all_pools", response_model=list[Pool])
async def read_all(db: AsyncSession = Depends(get_db_dep)):
    pools = await get_all_pool(db)
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
