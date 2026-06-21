from datetime import datetime
from pydantic import BaseModel
from models import LogType, UserRole


# --- Auth ---

class LoginRequest(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    username: str


# --- User ---

class UserCreate(BaseModel):
    username: str
    password: str
    role: UserRole = UserRole.EMPLOYEE


class UserUpdate(BaseModel):
    password: str | None = None
    role: UserRole | None = None
    is_active: bool | None = None


class UserOut(BaseModel):
    id: int
    username: str
    role: UserRole
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


# --- Plant ---

class PlantCreate(BaseModel):
    plant_code: str | None = None
    name: str
    scientific_name: str | None = None
    category: str | None = None
    sale_price: int = 0
    purchase_price: int = 0
    unit: str = "ポット"
    notes: str | None = None


class PlantUpdate(BaseModel):
    plant_code: str | None = None
    name: str | None = None
    scientific_name: str | None = None
    category: str | None = None
    sale_price: int | None = None
    purchase_price: int | None = None
    unit: str | None = None
    notes: str | None = None
    is_active: bool | None = None


class PlantPublic(BaseModel):
    """employee向け（仕入値なし）"""
    id: int
    plant_code: str
    name: str
    scientific_name: str | None
    category: str | None
    sale_price: int
    unit: str
    notes: str | None
    stock: int = 0

    model_config = {"from_attributes": True}


class PlantFull(PlantPublic):
    """executive以上向け（仕入値あり）"""
    purchase_price: int


# --- Inventory ---

class SaleRequest(BaseModel):
    plant_id: int
    quantity: int
    note: str | None = None


class PurchaseRequest(BaseModel):
    plant_id: int
    quantity: int
    unit_price: int = 0
    note: str | None = None


class DiscardRequest(BaseModel):
    plant_id: int
    quantity: int
    note: str | None = None


class AdjustRequest(BaseModel):
    plant_id: int
    quantity: int
    note: str | None = None


class InventoryLogOut(BaseModel):
    id: int
    plant_id: int
    type: LogType
    quantity: int
    unit_price: int
    note: str | None
    created_by: int | None
    created_at: datetime

    model_config = {"from_attributes": True}


# --- Report ---

class DailyReport(BaseModel):
    date: str
    sale_count: int
    sale_amount: int
    gross_profit: int


class CategorySummary(BaseModel):
    category: str | None
    sale_count: int
    sale_amount: int
    gross_profit: int


class MonthlyReport(BaseModel):
    year: int
    month: int
    sale_count: int
    sale_amount: int
    gross_profit: int
    by_category: list[CategorySummary]
