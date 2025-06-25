from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user import User
from app.schemas.user import UserCreate

async def create_user(db: AsyncSession, item: UserCreate, user_id: str):
    new_user = User(
        user_id=user_id,  # arriva dal token
        nickname=item.nickname,
        avatar_url=item.avatar_url
    )
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
