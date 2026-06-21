from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from database import get_db
from models import Plant, InventoryLog, LogType
from schemas import SaleRequest, PurchaseRequest, DiscardRequest, AdjustRequest, InventoryLogOut
from auth import get_current_user, require_executive
from models import User

router = APIRouter(prefix="/inventory", tags=["inventory"])


async def _check_plant(db: AsyncSession, plant_id: int) -> Plant:
    result = await db.execute(select(Plant).where(Plant.id == plant_id, Plant.is_active == True))
    plant = result.scalar_one_or_none()
    if not plant:
        raise HTTPException(status_code=404, detail="植物が見つかりません")
    return plant


@router.post("/sale", status_code=201)
async def record_sale(
    payload: SaleRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    plant = await _check_plant(db, payload.plant_id)
    log = InventoryLog(
        plant_id=plant.id,
        type=LogType.SALE,
        quantity=-abs(payload.quantity),
        unit_price=plant.sale_price,
        note=payload.note,
        created_by=current_user.id,
    )
    db.add(log)
    await db.flush()
    await db.refresh(log)
    return InventoryLogOut.model_validate(log)


@router.post("/purchase", status_code=201)
async def record_purchase(
    payload: PurchaseRequest,
    current_user: User = Depends(require_executive),
    db: AsyncSession = Depends(get_db),
):
    plant = await _check_plant(db, payload.plant_id)
    log = InventoryLog(
        plant_id=plant.id,
        type=LogType.PURCHASE,
        quantity=abs(payload.quantity),
        unit_price=payload.unit_price,
        note=payload.note,
        created_by=current_user.id,
    )
    db.add(log)
    await db.flush()
    await db.refresh(log)
    return InventoryLogOut.model_validate(log)


@router.post("/discard", status_code=201)
async def record_discard(
    payload: DiscardRequest,
    current_user: User = Depends(require_executive),
    db: AsyncSession = Depends(get_db),
):
    plant = await _check_plant(db, payload.plant_id)
    log = InventoryLog(
        plant_id=plant.id,
        type=LogType.DISCARD,
        quantity=-abs(payload.quantity),
        unit_price=0,
        note=payload.note,
        created_by=current_user.id,
    )
    db.add(log)
    await db.flush()
    await db.refresh(log)
    return InventoryLogOut.model_validate(log)


@router.post("/adjust", status_code=201)
async def record_adjust(
    payload: AdjustRequest,
    current_user: User = Depends(require_executive),
    db: AsyncSession = Depends(get_db),
):
    plant = await _check_plant(db, payload.plant_id)
    log = InventoryLog(
        plant_id=plant.id,
        type=LogType.ADJUST,
        quantity=payload.quantity,
        unit_price=0,
        note=payload.note,
        created_by=current_user.id,
    )
    db.add(log)
    await db.flush()
    await db.refresh(log)
    return InventoryLogOut.model_validate(log)


@router.get("/logs")
async def get_logs(
    plant_id: int | None = None,
    type: LogType | None = None,
    date_from: str | None = None,
    date_to: str | None = None,
    current_user: User = Depends(require_executive),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(InventoryLog).order_by(InventoryLog.created_at.desc())
    if plant_id:
        stmt = stmt.where(InventoryLog.plant_id == plant_id)
    if type:
        stmt = stmt.where(InventoryLog.type == type)
    if date_from:
        stmt = stmt.where(InventoryLog.created_at >= date_from)
    if date_to:
        stmt = stmt.where(InventoryLog.created_at <= date_to + " 23:59:59")
    result = await db.execute(stmt)
    logs = result.scalars().all()
    return [InventoryLogOut.model_validate(log) for log in logs]
