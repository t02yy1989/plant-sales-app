from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from database import get_db
from models import Plant, InventoryLog, UserRole
from schemas import PlantCreate, PlantUpdate, PlantPublic, PlantFull
from auth import get_current_user, require_executive
from models import User

router = APIRouter(prefix="/plants", tags=["plants"])

# TODO: バーコード化時は plant_code をそのままJAN/QRに変換
# GET /plants/by-code/{plant_code} エンドポイントを追加予定


def generate_plant_code(last_plant: Plant | None) -> str:
    if not last_plant or not last_plant.plant_code:
        return "P001"
    num = int(last_plant.plant_code.lstrip("P")) + 1
    return f"P{num:03d}"


async def _get_stock(db: AsyncSession, plant_id: int) -> int:
    result = await db.execute(
        select(func.coalesce(func.sum(InventoryLog.quantity), 0))
        .where(InventoryLog.plant_id == plant_id)
    )
    return result.scalar() or 0


async def _stock_subquery(db: AsyncSession) -> dict[int, int]:
    result = await db.execute(
        select(InventoryLog.plant_id, func.coalesce(func.sum(InventoryLog.quantity), 0).label("stock"))
        .group_by(InventoryLog.plant_id)
    )
    return {row.plant_id: row.stock for row in result}


def _build_plant_response(plant: Plant, stock: int, is_executive: bool) -> dict:
    data = {
        "id": plant.id,
        "plant_code": plant.plant_code,
        "name": plant.name,
        "scientific_name": plant.scientific_name,
        "category": plant.category,
        "sale_price": plant.sale_price,
        "unit": plant.unit,
        "notes": plant.notes,
        "stock": stock,
    }
    if is_executive:
        data["purchase_price"] = plant.purchase_price
    return data


@router.get("")
async def list_plants(
    category: str | None = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Plant).where(Plant.is_active == True)
    if category:
        stmt = stmt.where(Plant.category == category)
    result = await db.execute(stmt)
    plants = result.scalars().all()

    stock_map = await _stock_subquery(db)
    is_executive = current_user.role in (UserRole.EXECUTIVE, UserRole.ADMIN)

    return [_build_plant_response(p, stock_map.get(p.id, 0), is_executive) for p in plants]


@router.get("/by-code/{plant_code}")
async def get_plant_by_code(
    plant_code: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Plant).where(Plant.plant_code == plant_code, Plant.is_active == True)
    )
    plant = result.scalar_one_or_none()
    if not plant:
        raise HTTPException(status_code=404, detail="植物が見つかりません")
    stock = await _get_stock(db, plant.id)
    is_executive = current_user.role in (UserRole.EXECUTIVE, UserRole.ADMIN)
    return _build_plant_response(plant, stock, is_executive)


@router.get("/{plant_id}")
async def get_plant(
    plant_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Plant).where(Plant.id == plant_id, Plant.is_active == True)
    )
    plant = result.scalar_one_or_none()
    if not plant:
        raise HTTPException(status_code=404, detail="植物が見つかりません")
    stock = await _get_stock(db, plant.id)
    is_executive = current_user.role in (UserRole.EXECUTIVE, UserRole.ADMIN)
    return _build_plant_response(plant, stock, is_executive)


@router.post("", status_code=201)
async def create_plant(
    payload: PlantCreate,
    current_user: User = Depends(require_executive),
    db: AsyncSession = Depends(get_db),
):
    if payload.plant_code:
        existing = await db.execute(select(Plant).where(Plant.plant_code == payload.plant_code))
        if existing.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="この管理番号はすでに使用されています")
        code = payload.plant_code
    else:
        result = await db.execute(select(Plant).order_by(Plant.id.desc()))
        last = result.scalars().first()
        code = generate_plant_code(last)

    plant = Plant(
        plant_code=code,
        name=payload.name,
        scientific_name=payload.scientific_name,
        category=payload.category,
        sale_price=payload.sale_price,
        purchase_price=payload.purchase_price,
        unit=payload.unit,
        notes=payload.notes,
    )
    db.add(plant)
    await db.flush()
    await db.refresh(plant)
    return _build_plant_response(plant, 0, True)


@router.put("/{plant_id}")
async def update_plant(
    plant_id: int,
    payload: PlantUpdate,
    current_user: User = Depends(require_executive),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Plant).where(Plant.id == plant_id))
    plant = result.scalar_one_or_none()
    if not plant:
        raise HTTPException(status_code=404, detail="植物が見つかりません")

    for field, value in payload.model_dump(exclude_none=True).items():
        setattr(plant, field, value)

    await db.flush()
    stock = await _get_stock(db, plant.id)
    return _build_plant_response(plant, stock, True)


@router.delete("/{plant_id}", status_code=204)
async def delete_plant(
    plant_id: int,
    current_user: User = Depends(require_executive),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Plant).where(Plant.id == plant_id))
    plant = result.scalar_one_or_none()
    if not plant:
        raise HTTPException(status_code=404, detail="植物が見つかりません")
    plant.is_active = False
