from fastapi import FastAPI
from app.api.v1.routers.pool import router as pool_router
from app.api.v1.routers.prize import router as prize_router
from app.api.v1.routers.ticket import router as ticket_router
from app.api.v1.routers.purchase import router as purchase_router
from app.api.v1.routers.wallet import router as wallet_router
from app.api.v1.routers.user import router as user_router
from app.core.config import settings
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title=settings.PROJECT_NAME, version=settings.VERSION)

# metti qui gli origin del tuo frontend web
ALLOWED_ORIGINS = [
    "http://0.0.0.0:8080",         
    "http://192.168.1.23:8080",    
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,           # tienilo True se usi cookie/sessione, ok anche con Bearer
    allow_methods=["*"],
    allow_headers=["*"],              # oppure ["Authorization", "Content-Type"]
)

app.include_router(pool_router, prefix="/api/v1/pools", tags=["Pools"])
app.include_router(prize_router, prefix="/api/v1/prizes", tags=["Prizes"])
app.include_router(ticket_router, prefix="/api/v1/tickets", tags=["Tickets"])
app.include_router(user_router, prefix="/api/v1/users", tags=["Users"])
app.include_router(purchase_router, prefix="/api/v1/purchases", tags=["Purchases"])
app.include_router(wallet_router, prefix="/api/v1/wallet", tags=["Wallet"])
