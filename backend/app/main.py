from fastapi import FastAPI
from app.api.v1.routers.pool import router as pool_router
from app.api.v1.routers.prize import router as prize_router
from app.api.v1.routers.ticket import router as ticket_router
from app.api.v1.routers.user import router as user_router
from app.core.config import settings

app = FastAPI(title=settings.PROJECT_NAME, version=settings.VERSION)

app.include_router(pool_router, prefix="/api/v1/pools", tags=["Pools"])
app.include_router(prize_router, prefix="/api/v1/prizes", tags=["Prizes"])
app.include_router(ticket_router, prefix="/api/v1/tickets", tags=["Tickets"])
app.include_router(user_router, prefix="/api/v1/users", tags=["Users"])