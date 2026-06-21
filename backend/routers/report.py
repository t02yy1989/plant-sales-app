from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_

from database import get_db
from models import InventoryLog, Plant, LogType
from schemas import DailyReport, MonthlyReport, CategorySummary
from auth import require_executive
from models import User

router = APIRouter(prefix="/report", tags=["report"])


@router.get("/daily", response_model=DailyReport)
async def daily_report(
    date: str,
    current_user: User = Depends(require_executive),
    db: AsyncSession = Depends(get_db),
):
    stmt = (
        select(
            func.count(InventoryLog.id).label("sale_count"),
            func.sum(-InventoryLog.quantity * InventoryLog.unit_price).label("sale_amount"),
            func.sum(-InventoryLog.quantity * (InventoryLog.unit_price - Plant.purchase_price)).label("gross_profit"),
        )
        .join(Plant, InventoryLog.plant_id == Plant.id)
        .where(
            InventoryLog.type == LogType.SALE,
            func.date(InventoryLog.created_at) == date,
        )
    )
    result = await db.execute(stmt)
    row = result.one()
    return DailyReport(
        date=date,
        sale_count=row.sale_count or 0,
        sale_amount=row.sale_amount or 0,
        gross_profit=row.gross_profit or 0,
    )


@router.get("/monthly", response_model=MonthlyReport)
async def monthly_report(
    year: int,
    month: int,
    current_user: User = Depends(require_executive),
    db: AsyncSession = Depends(get_db),
):
    base_filter = and_(
        InventoryLog.type == LogType.SALE,
        func.year(InventoryLog.created_at) == year,
        func.month(InventoryLog.created_at) == month,
    )

    total_stmt = (
        select(
            func.count(InventoryLog.id).label("sale_count"),
            func.sum(-InventoryLog.quantity * InventoryLog.unit_price).label("sale_amount"),
            func.sum(-InventoryLog.quantity * (InventoryLog.unit_price - Plant.purchase_price)).label("gross_profit"),
        )
        .join(Plant, InventoryLog.plant_id == Plant.id)
        .where(base_filter)
    )
    total_result = await db.execute(total_stmt)
    total = total_result.one()

    category_stmt = (
        select(
            Plant.category,
            func.count(InventoryLog.id).label("sale_count"),
            func.sum(-InventoryLog.quantity * InventoryLog.unit_price).label("sale_amount"),
            func.sum(-InventoryLog.quantity * (InventoryLog.unit_price - Plant.purchase_price)).label("gross_profit"),
        )
        .join(Plant, InventoryLog.plant_id == Plant.id)
        .where(base_filter)
        .group_by(Plant.category)
    )
    cat_result = await db.execute(category_stmt)

    by_category = [
        CategorySummary(
            category=row.category,
            sale_count=row.sale_count or 0,
            sale_amount=row.sale_amount or 0,
            gross_profit=row.gross_profit or 0,
        )
        for row in cat_result
    ]

    return MonthlyReport(
        year=year,
        month=month,
        sale_count=total.sale_count or 0,
        sale_amount=total.sale_amount or 0,
        gross_profit=total.gross_profit or 0,
        by_category=by_category,
    )
