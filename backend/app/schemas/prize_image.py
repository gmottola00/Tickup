from datetime import datetime
from uuid import UUID
from typing import Optional, List

from pydantic import BaseModel


class PrizeImageBase(BaseModel):
    bucket: str
    storage_path: str
    url: str
    is_cover: Optional[bool] = False
    sort_order: Optional[int] = None


class PrizeImageCreate(PrizeImageBase):
    pass


class PrizeImageUpdate(BaseModel):
    is_cover: Optional[bool] = None
    sort_order: Optional[int] = None


class PrizeImage(BaseModel):
    image_id: UUID
    prize_id: UUID
    bucket: str
    storage_path: str
    url: str
    is_cover: bool
    sort_order: Optional[int] = None
    created_at: datetime

    class Config:
        orm_mode = True


class PrizeImageReorderItem(BaseModel):
    image_id: UUID
    sort_order: int


class PrizeImageReorderRequest(BaseModel):
    items: List[PrizeImageReorderItem]

