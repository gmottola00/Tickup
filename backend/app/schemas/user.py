from pydantic import BaseModel
from typing import Optional
from uuid import UUID
from datetime import datetime


class UserBase(BaseModel):
    nickname: str
    avatar_url: Optional[str] = None
    avatar_character: Optional[str] = None
    avatar_asset: Optional[str] = None


# Input per la creazione dell'utente (richiesta dal client)
class UserCreate(UserBase):
    pass


# Output/response dell'utente (ritorno dal DB o API)
class User(UserBase):
    user_id: UUID
    created_at: datetime

    class Config:
        orm_mode = True


# (Opzionale) Modello per l'update dell'utente
class UserUpdate(BaseModel):
    nickname: Optional[str] = None
    avatar_url: Optional[str] = None
    avatar_character: Optional[str] = None
    avatar_asset: Optional[str] = None
