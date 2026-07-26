from datetime import date, timedelta
from typing import Annotated
from uuid import UUID

from dateutil.relativedelta import relativedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Account, Category, Expense, RecurringExpense, User
from app.schemas import CategoryOut, RecurringCreate, RecurringOut, RecurringUpdate
from app.security import get_current_user

router = APIRouter(prefix="/recurring", tags=["recurring"])


def _advance(d: date, frequency: str) -> date:
    if frequency == "weekly":
        return d + timedelta(days=7)
    if frequency == "yearly":
        return d + relativedelta(years=1)
    return d + relativedelta(months=1)


def _out(r: RecurringExpense, db: Session) -> RecurringOut:
    cat = db.get(Category, r.category_id) if r.category_id else None
    return RecurringOut(
        id=r.id,
        user_id=r.user_id,
        title=r.title,
        amount=r.amount,
        currency=r.currency,
        category_id=r.category_id,
        account_id=r.account_id,
        frequency=r.frequency,
        next_due=r.next_due,
        notes=r.notes,
        auto_create=r.auto_create,
        active=r.active,
        created_at=r.created_at,
        category=CategoryOut.model_validate(cat) if cat else None,
    )


@router.get("", response_model=list[RecurringOut])
def list_recurring(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    rows = (
        db.query(RecurringExpense)
        .filter(RecurringExpense.user_id == user.id)
        .order_by(RecurringExpense.next_due)
        .all()
    )
    return [_out(r, db) for r in rows]


@router.post("", response_model=RecurringOut, status_code=status.HTTP_201_CREATED)
def create_recurring(
    body: RecurringCreate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    if body.frequency not in ("monthly", "weekly", "yearly"):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid frequency")
    r = RecurringExpense(
        user_id=user.id,
        title=body.title,
        amount=body.amount,
        currency=body.currency,
        category_id=body.category_id,
        account_id=body.account_id,
        frequency=body.frequency,
        next_due=body.next_due,
        notes=body.notes,
        auto_create=body.auto_create,
    )
    db.add(r)
    db.commit()
    db.refresh(r)
    return _out(r, db)


@router.patch("/{recurring_id}", response_model=RecurringOut)
def update_recurring(
    recurring_id: UUID,
    body: RecurringUpdate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    r = db.get(RecurringExpense, recurring_id)
    if not r or r.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Not found")
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(r, k, v)
    db.commit()
    db.refresh(r)
    return _out(r, db)


@router.delete("/{recurring_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_recurring(
    recurring_id: UUID,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    r = db.get(RecurringExpense, recurring_id)
    if not r or r.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Not found")
    db.delete(r)
    db.commit()


@router.post("/{recurring_id}/run", response_model=RecurringOut)
def run_recurring(
    recurring_id: UUID,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    """Create expense from recurring item and advance next_due."""
    r = db.get(RecurringExpense, recurring_id)
    if not r or r.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Not found")
    exp = Expense(
        title=r.title,
        amount=r.amount,
        currency=r.currency,
        category_id=r.category_id,
        date=r.next_due,
        payer_id=user.id,
        account_id=r.account_id,
        notes=r.notes,
    )
    db.add(exp)
    if r.account_id:
        acc = db.get(Account, r.account_id)
        if acc and acc.user_id == user.id:
            acc.balance -= r.amount
    r.next_due = _advance(r.next_due, r.frequency)
    db.commit()
    db.refresh(r)
    return _out(r, db)
