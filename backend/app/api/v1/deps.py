from app.db.session import get_db
from sqlalchemy.ext.asyncio import AsyncSession

def get_db_dep() -> AsyncSession:
    return get_db()
