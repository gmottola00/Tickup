from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.schemas.user import User, UserCreate
from app.services.user import create_user, get_user, update_user, delete_user
from app.api.v1.deps import get_db_dep
from app.api.v1.auth import get_current_user_id

router = APIRouter()

@router.post("/me", response_model=User)
async def create_current_user(
    item: UserCreate,
    db: AsyncSession = Depends(get_db_dep),
    user_id: str = Depends(get_current_user_id)
):
    existing_user = await get_user(db, user_id)
    if existing_user:
        raise HTTPException(status_code=400, detail="User already exists")
    return await create_user(db, item, user_id=user_id)

@router.post("/", response_model=User)
async def create(item: UserCreate, db: AsyncSession = Depends(get_db_dep)):
    return await create_user(db, item)

@router.get("/{user_id}", response_model=User)
async def read(user_id: str, db: AsyncSession = Depends(get_db_dep)):
    user = await get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="user not found")
    return user

@router.put("/{user_id}", response_model=User)
async def update(user_id: str, item: UserCreate, db: AsyncSession = Depends(get_db_dep)):
    user = await get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="user not found")
    return await update_user(db, user, item.dict())

@router.delete("/{user_id}", status_code=204)
async def delete(user_id: str, db: AsyncSession = Depends(get_db_dep)):
    user = await get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="user not found")
    await delete_user(db, user)
