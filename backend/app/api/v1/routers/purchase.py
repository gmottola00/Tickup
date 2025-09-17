from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.auth import get_current_user_id
from app.api.v1.deps import get_db_dep
from app.schemas.purchase import Purchase, PurchaseCreate, PurchaseUpdate
from app.services.purchase import (
    create_purchase,
    get_purchase,
    get_all_purchases,
    get_user_purchases,
    update_purchase,
    delete_purchase,
)

router = APIRouter()

@router.post("/", response_model=Purchase, status_code=status.HTTP_201_CREATED)
async def create(
    item: PurchaseCreate,
    db: AsyncSession = Depends(get_db_dep),
    user_sub: str = Depends(get_current_user_id),
):
    try:
        user_id = UUID(user_sub)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user identifier")
    return await create_purchase(db, user_id, item)

@router.get("/all", response_model=list[Purchase])
async def read_all(db: AsyncSession = Depends(get_db_dep)):
    return await get_all_purchases(db)

@router.get("/my", response_model=list[Purchase])
async def read_my(
    db: AsyncSession = Depends(get_db_dep),
    user_sub: str = Depends(get_current_user_id),
):
    try:
        user_id = UUID(user_sub)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user identifier")
    return await get_user_purchases(db, user_id)

@router.get("/{purchase_id}", response_model=Purchase)
async def read(purchase_id: UUID, db: AsyncSession = Depends(get_db_dep)):
    purchase = await get_purchase(db, purchase_id)
    if not purchase:
        raise HTTPException(status_code=404, detail="Purchase not found")
    return purchase

@router.put("/{purchase_id}", response_model=Purchase)
async def update(
    purchase_id: UUID,
    item: PurchaseUpdate,
    db: AsyncSession = Depends(get_db_dep),
):
    purchase = await get_purchase(db, purchase_id)
    if not purchase:
        raise HTTPException(status_code=404, detail="Purchase not found")
    return await update_purchase(db, purchase, item)

@router.delete("/{purchase_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete(purchase_id: UUID, db: AsyncSession = Depends(get_db_dep)):
    purchase = await get_purchase(db, purchase_id)
    if not purchase:
        raise HTTPException(status_code=404, detail="Purchase not found")
    await delete_purchase(db, purchase)
