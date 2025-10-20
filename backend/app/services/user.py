from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.schemas.user import UserCreate

async def create_user(
    db: AsyncSession,
    item: UserCreate,
    user_id: Optional[str] = None,
):
    payload = {
        "nickname": item.nickname,
        "avatar_url": item.avatar_url,
        "avatar_character": item.avatar_character,
        "avatar_asset": item.avatar_asset,
    }
    if user_id:
        payload["user_id"] = user_id  # arriva dal token

    new_user = User(**payload)
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    return new_user

async def get_user(db: AsyncSession, user_id: str):
    return await db.get(User, user_id)

async def update_user(db: AsyncSession, user: User, data: dict):
    for key, value in data.items():
        setattr(user, key, value)
    await db.commit()
    await db.refresh(user)
    return user

async def delete_user(db: AsyncSession, user: User):
    await db.delete(user)
    await db.commit()
