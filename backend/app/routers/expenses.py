from datetime import date
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Account, Category, Expense, ExpenseSplit, SplitType, User
from app.schemas import ExpenseCreate, ExpenseOut, ExpenseUpdate, SplitOut, UserOut
from app.security import get_current_user
from app.services.authz import require_group_member

router = APIRouter(prefix="/expenses", tags=["expenses"])


def _validate_splits(amount: int, splits: list) -> None:
    if not splits:
        return
    total = sum(s.owed_amount for s in splits)
    if total != amount:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"Splits total {total} must equal expense amount {amount}",
        )


def _expense_out(exp: Expense, db: Session, include_splits: bool = False) -> ExpenseOut:
    cat = db.get(Category, exp.category_id) if exp.category_id else None
    payer = db.get(User, exp.payer_id)
    splits_out = None
    if include_splits:
        rows = (
            db.query(ExpenseSplit)
            .filter(ExpenseSplit.expense_id == exp.id)
            .all()
        )
        splits_out = []
        for s in rows:
            u = db.get(User, s.user_id)
            splits_out.append(
                SplitOut(
                    id=s.id,
                    expense_id=s.expense_id,
                    user_id=s.user_id,
                    owed_amount=s.owed_amount,
                    split_type=s.split_type.value,
                    profiles=UserOut.model_validate(u) if u else None,
                )
            )
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
        splits=splits_out,
    )


def _can_mutate(exp: Expense, user: User, db: Session) -> None:
    if exp.group_id:
        require_group_member(db, exp.group_id, user)
        if exp.payer_id != user.id:
            from app.services.authz import require_group_admin

            require_group_admin(db, exp.group_id, user)
    elif exp.payer_id != user.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your expense")


def _replace_splits(db: Session, expense_id: UUID, splits: list) -> None:
    db.query(ExpenseSplit).filter(ExpenseSplit.expense_id == expense_id).delete()
    for s in splits:
        db.add(
            ExpenseSplit(
                expense_id=expense_id,
                user_id=s.user_id,
                owed_amount=s.owed_amount,
                split_type=SplitType(s.split_type),
            )
        )


@router.get("", response_model=list[ExpenseOut])
def list_expenses(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    personal: bool = Query(False),
    group_id: UUID | None = None,
    limit: int = 50,
    from_date: date | None = None,
    to_date: date | None = None,
    category_id: UUID | None = None,
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
    if to_date:
        q = q.filter(Expense.date <= to_date)
    if category_id:
        q = q.filter(Expense.category_id == category_id)
    rows = q.order_by(Expense.date.desc()).limit(limit).all()
    return [_expense_out(e, db) for e in rows]


@router.get("/{expense_id}", response_model=ExpenseOut)
def get_expense(
    expense_id: UUID,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    exp = db.get(Expense, expense_id)
    if not exp:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Expense not found")
    if exp.group_id:
        require_group_member(db, exp.group_id, user)
    elif exp.payer_id != user.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your expense")
    return _expense_out(exp, db, include_splits=True)


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

    _validate_splits(body.amount, body.splits or [])

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
        _replace_splits(db, exp.id, body.splits)

    if body.account_id:
        acc = db.get(Account, body.account_id)
        if not acc or acc.user_id != user.id:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid account")
        acc.balance -= body.amount

    db.commit()
    db.refresh(exp)
    return _expense_out(exp, db, include_splits=True)


@router.patch("/{expense_id}", response_model=ExpenseOut)
def update_expense(
    expense_id: UUID,
    body: ExpenseUpdate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    exp = db.get(Expense, expense_id)
    if not exp:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Expense not found")
    _can_mutate(exp, user, db)

    old_amount = exp.amount
    old_account_id = exp.account_id

    data = body.model_dump(exclude_unset=True)
    splits = data.pop("splits", None)

    if "amount" in data or splits is not None:
        new_amount = data.get("amount", exp.amount)
        if splits is not None:
            _validate_splits(new_amount, splits)

    for k, v in data.items():
        setattr(exp, k, v)

    if splits is not None:
        _replace_splits(db, exp.id, splits)

    new_account_id = exp.account_id
    new_amount = exp.amount

    # Reverse old personal account debit, apply new
    if old_account_id:
        old_acc = db.get(Account, old_account_id)
        if old_acc and old_acc.user_id == user.id:
            old_acc.balance += old_amount
    if new_account_id:
        new_acc = db.get(Account, new_account_id)
        if not new_acc or new_acc.user_id != user.id:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid account")
        new_acc.balance -= new_amount

    db.commit()
    db.refresh(exp)
    return _expense_out(exp, db, include_splits=True)


@router.delete("/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_expense(
    expense_id: UUID,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    exp = db.get(Expense, expense_id)
    if not exp:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Expense not found")
    _can_mutate(exp, user, db)

    if exp.account_id:
        acc = db.get(Account, exp.account_id)
        if acc and acc.user_id == user.id:
            acc.balance += exp.amount

    db.delete(exp)
    db.commit()
