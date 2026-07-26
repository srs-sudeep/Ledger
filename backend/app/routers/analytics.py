from calendar import monthrange
from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Category, Expense, User
from app.schemas import AnalyticsByCategory, AnalyticsByMonth, AnalyticsOut
from app.security import get_current_user

router = APIRouter(prefix="/analytics", tags=["analytics"])


@router.get("/summary", response_model=AnalyticsOut)
def analytics_summary(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    months: int = Query(6, ge=1, le=24),
):
    today = date.today()
    start_month = today.month - (months - 1)
    start_year = today.year
    while start_month <= 0:
        start_month += 12
        start_year -= 1
    from_date = date(start_year, start_month, 1)

    personal_total = (
        db.query(func.coalesce(func.sum(Expense.amount), 0))
        .filter(
            Expense.payer_id == user.id,
            Expense.group_id.is_(None),
            Expense.date >= from_date,
        )
        .scalar()
    )
    group_total = (
        db.query(func.coalesce(func.sum(Expense.amount), 0))
        .filter(
            Expense.payer_id == user.id,
            Expense.group_id.isnot(None),
            Expense.date >= from_date,
        )
        .scalar()
    )

    cat_rows = (
        db.query(
            Expense.category_id,
            Category.name,
            Category.color,
            func.coalesce(func.sum(Expense.amount), 0),
        )
        .outerjoin(Category, Category.id == Expense.category_id)
        .filter(
            Expense.payer_id == user.id,
            Expense.group_id.is_(None),
            Expense.date >= from_date,
        )
        .group_by(Expense.category_id, Category.name, Category.color)
        .all()
    )
    by_category = [
        AnalyticsByCategory(
            category_id=cid,
            category_name=name or "Uncategorized",
            color=color,
            total=int(total),
        )
        for cid, name, color, total in cat_rows
    ]

    by_month: list[AnalyticsByMonth] = []
    y, m = start_year, start_month
    for _ in range(months):
        last = monthrange(y, m)[1]
        month_start = date(y, m, 1)
        month_end = date(y, m, last)
        personal = (
            db.query(func.coalesce(func.sum(Expense.amount), 0))
            .filter(
                Expense.payer_id == user.id,
                Expense.group_id.is_(None),
                Expense.date >= month_start,
                Expense.date <= month_end,
            )
            .scalar()
        )
        group = (
            db.query(func.coalesce(func.sum(Expense.amount), 0))
            .filter(
                Expense.payer_id == user.id,
                Expense.group_id.isnot(None),
                Expense.date >= month_start,
                Expense.date <= month_end,
            )
            .scalar()
        )
        by_month.append(
            AnalyticsByMonth(
                month=f"{y:04d}-{m:02d}",
                personal=int(personal or 0),
                group=int(group or 0),
            )
        )
        m += 1
        if m > 12:
            m = 1
            y += 1

    return AnalyticsOut(
        personal_total=int(personal_total or 0),
        group_total=int(group_total or 0),
        by_category=by_category,
        by_month=by_month,
    )
