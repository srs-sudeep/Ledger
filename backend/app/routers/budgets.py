from calendar import monthrange
from datetime import date
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Budget, Category, Expense, User
from app.schemas import BudgetCreate, BudgetOut, BudgetUpdate, CategoryOut
from app.security import get_current_user

router = APIRouter(prefix="/budgets", tags=["budgets"])


def _spent(db: Session, user_id: UUID, category_id: UUID, month: str) -> int:
    y, m = map(int, month.split("-"))
    start = date(y, m, 1)
    end = date(y, m, monthrange(y, m)[1])
    return int(
        db.query(func.coalesce(func.sum(Expense.amount), 0))
        .filter(
            Expense.payer_id == user_id,
            Expense.group_id.is_(None),
            Expense.category_id == category_id,
            Expense.date >= start,
            Expense.date <= end,
        )
        .scalar()
        or 0
    )


def _out(b: Budget, db: Session) -> BudgetOut:
    cat = db.get(Category, b.category_id)
    return BudgetOut(
        id=b.id,
        user_id=b.user_id,
        category_id=b.category_id,
        amount=b.amount,
        month=b.month,
        currency=b.currency,
        spent=_spent(db, b.user_id, b.category_id, b.month),
        category=CategoryOut.model_validate(cat) if cat else None,
        created_at=b.created_at,
    )


@router.get("", response_model=list[BudgetOut])
def list_budgets(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    month: str | None = Query(None, pattern=r"^\d{4}-\d{2}$"),
):
    q = db.query(Budget).filter(Budget.user_id == user.id)
    if month:
        q = q.filter(Budget.month == month)
    else:
        today = date.today()
        q = q.filter(Budget.month == f"{today.year:04d}-{today.month:02d}")
    return [_out(b, db) for b in q.order_by(Budget.created_at.desc()).all()]


@router.post("", response_model=BudgetOut, status_code=status.HTTP_201_CREATED)
def create_budget(
    body: BudgetCreate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    if not db.get(Category, body.category_id):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid category")
    existing = (
        db.query(Budget)
        .filter(
            Budget.user_id == user.id,
            Budget.category_id == body.category_id,
            Budget.month == body.month,
        )
        .first()
    )
    if existing:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Budget already exists for this category/month")
    b = Budget(
        user_id=user.id,
        category_id=body.category_id,
        amount=body.amount,
        month=body.month,
        currency=body.currency,
    )
    db.add(b)
    db.commit()
    db.refresh(b)
    return _out(b, db)


@router.patch("/{budget_id}", response_model=BudgetOut)
def update_budget(
    budget_id: UUID,
    body: BudgetUpdate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    b = db.get(Budget, budget_id)
    if not b or b.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Budget not found")
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(b, k, v)
    db.commit()
    db.refresh(b)
    return _out(b, db)


@router.delete("/{budget_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_budget(
    budget_id: UUID,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    b = db.get(Budget, budget_id)
    if not b or b.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Budget not found")
    db.delete(b)
    db.commit()
