from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Expense, ExpenseSplit, Settlement, SettlementStatus, User
from app.schemas import DashboardSummary, SettlementOut, UserOut
from app.security import get_current_user

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


@router.get("/summary", response_model=DashboardSummary)
def dashboard_summary(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    today = date.today()
    start = date(today.year, today.month, 1)

    personal = (
        db.query(func.coalesce(func.sum(Expense.amount), 0))
        .filter(
            Expense.payer_id == user.id,
            Expense.group_id.is_(None),
            Expense.date >= start,
            Expense.date <= today,
        )
        .scalar()
    )

    owed_splits = (
        db.query(ExpenseSplit)
        .join(Expense, Expense.id == ExpenseSplit.expense_id)
        .filter(Expense.payer_id == user.id, ExpenseSplit.user_id != user.id)
        .all()
    )
    owed_to_me = sum(s.owed_amount for s in owed_splits)

    i_owe_splits = (
        db.query(ExpenseSplit)
        .join(Expense, Expense.id == ExpenseSplit.expense_id)
        .filter(
            ExpenseSplit.user_id == user.id,
            Expense.payer_id != user.id,
        )
        .all()
    )
    i_owe = sum(s.owed_amount for s in i_owe_splits)

    return DashboardSummary(
        net_worth=owed_to_me - i_owe,
        owed_to_me=owed_to_me,
        i_owe=i_owe,
        monthly_spend=int(personal or 0),
    )


@router.get("/settlements/pending", response_model=list[SettlementOut])
def pending_settlements(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    rows = (
        db.query(Settlement)
        .filter(
            Settlement.status == SettlementStatus.pending,
            (Settlement.from_user_id == user.id) | (Settlement.to_user_id == user.id),
        )
        .order_by(Settlement.created_at.desc())
        .limit(10)
        .all()
    )
    out = []
    for row in rows:
        from_u = db.get(User, row.from_user_id)
        to_u = db.get(User, row.to_user_id)
        out.append(
            SettlementOut(
                id=row.id,
                from_user_id=row.from_user_id,
                to_user_id=row.to_user_id,
                amount=row.amount,
                currency=row.currency,
                group_id=row.group_id,
                status=row.status.value,
                created_at=row.created_at,
                settled_at=row.settled_at,
                from_profile=UserOut.model_validate(from_u) if from_u else None,
                to_profile=UserOut.model_validate(to_u) if to_u else None,
            )
        )
    return out
