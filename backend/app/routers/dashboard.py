from datetime import date
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import (
    Account,
    Expense,
    ExpenseSplit,
    GroupMember,
    Settlement,
    SettlementStatus,
    User,
)
from app.schemas import DashboardSummary, SettlementOut, UserOut
from app.security import get_current_user
from app.services.debt import compute_group_balances

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

    net_worth = (
        db.query(func.coalesce(func.sum(Account.balance), 0))
        .filter(Account.user_id == user.id)
        .scalar()
    )

    memberships = (
        db.query(GroupMember.group_id)
        .filter(GroupMember.user_id == user.id)
        .all()
    )
    owed_to_me = 0
    i_owe = 0
    for (gid,) in memberships:
        expenses = db.query(Expense).filter(Expense.group_id == gid).all()
        if not expenses:
            continue
        expense_ids = [e.id for e in expenses]
        splits = (
            db.query(ExpenseSplit)
            .filter(ExpenseSplit.expense_id.in_(expense_ids))
            .all()
        )
        settlements = (
            db.query(Settlement)
            .filter(
                Settlement.group_id == gid,
                Settlement.status == SettlementStatus.completed,
            )
            .all()
        )
        balances = compute_group_balances(expenses, splits, settlements)
        bal = balances.get(str(user.id), 0)
        if bal > 0:
            owed_to_me += bal
        elif bal < 0:
            i_owe += abs(bal)

    return DashboardSummary(
        net_worth=int(net_worth or 0),
        group_net=owed_to_me - i_owe,
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
