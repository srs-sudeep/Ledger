from datetime import date
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models import Account, Category, Expense, ExpenseSplit, SplitType, User
from app.schemas import ExpenseCreate, ExpenseOut, UserOut
from app.security import get_current_user
from app.services.authz import is_group_member, require_group_member

router = APIRouter(prefix="/expenses", tags=["expenses"])


def _expense_out(exp: Expense, db: Session) -> ExpenseOut:
    cat = db.get(Category, exp.category_id) if exp.category_id else None
    payer = db.get(User, exp.payer_id)
    return ExpenseOut(
        id=exp.id,
        title=exp.title,
        amount=exp.amount,
        currency=exp.currency,
        category_id=exp.category_id,
        date=exp.date,
        payer_id=exp.payer_id,
        group_id=exp.group_id,
        account_id=exp.account_id,
        notes=exp.notes,
        created_at=exp.created_at,
        category=cat,
        profiles=UserOut.model_validate(payer) if payer else None,
    )


@router.get("", response_model=list[ExpenseOut])
def list_expenses(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    personal: bool = Query(False),
    group_id: UUID | None = None,
    limit: int = 50,
    from_date: date | None = None,
):
    q = db.query(Expense)
    if personal:
        q = q.filter(Expense.payer_id == user.id, Expense.group_id.is_(None))
    elif group_id:
        require_group_member(db, group_id, user)
        q = q.filter(Expense.group_id == group_id)
    else:
        q = q.filter(Expense.payer_id == user.id)
    if from_date:
        q = q.filter(Expense.date >= from_date)
    rows = q.order_by(Expense.date.desc()).limit(limit).all()
    return [_expense_out(e, db) for e in rows]


@router.post("", response_model=ExpenseOut, status_code=status.HTTP_201_CREATED)
def create_expense(
    body: ExpenseCreate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    payer_id = body.payer_id or user.id
    if body.group_id:
        require_group_member(db, body.group_id, user)
    elif payer_id != user.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Cannot create for another user")

    currency = body.currency
    if body.group_id:
        from app.models import Group

        g = db.get(Group, body.group_id)
        currency = g.currency if g else body.currency

    exp = Expense(
        title=body.title,
        amount=body.amount,
        currency=currency,
        category_id=body.category_id,
        date=body.date,
        payer_id=payer_id,
        group_id=body.group_id,
        account_id=body.account_id,
        notes=body.notes,
    )
    db.add(exp)
    db.flush()

    if body.splits:
        for s in body.splits:
            db.add(
                ExpenseSplit(
                    expense_id=exp.id,
                    user_id=s.user_id,
                    owed_amount=s.owed_amount,
                    split_type=SplitType(s.split_type),
                )
            )

    if body.account_id:
        acc = db.get(Account, body.account_id)
        if not acc or acc.user_id != user.id:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid account")
        acc.balance -= body.amount

    db.commit()
    db.refresh(exp)
    return _expense_out(exp, db)
