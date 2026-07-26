from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Account, Income, User
from app.schemas import IncomeCreate, IncomeOut, IncomeUpdate
from app.security import get_current_user

router = APIRouter(prefix="/income", tags=["income"])


@router.get("", response_model=list[IncomeOut])
def list_income(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    limit: int = 50,
):
    return (
        db.query(Income)
        .filter(Income.user_id == user.id)
        .order_by(Income.date.desc())
        .limit(limit)
        .all()
    )


@router.post("", response_model=IncomeOut, status_code=status.HTTP_201_CREATED)
def create_income(
    body: IncomeCreate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    row = Income(
        user_id=user.id,
        account_id=body.account_id,
        amount=body.amount,
        currency=body.currency,
        source=body.source,
        date=body.date,
        notes=body.notes,
    )
    db.add(row)
    if body.account_id:
        acc = db.get(Account, body.account_id)
        if not acc or acc.user_id != user.id:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid account")
        acc.balance += body.amount
    db.commit()
    db.refresh(row)
    return row


@router.patch("/{income_id}", response_model=IncomeOut)
def update_income(
    income_id: UUID,
    body: IncomeUpdate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    row = db.get(Income, income_id)
    if not row or row.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Income not found")

    old_amount = row.amount
    old_account_id = row.account_id
    data = body.model_dump(exclude_unset=True)
    for k, v in data.items():
        setattr(row, k, v)

    if old_account_id:
        old_acc = db.get(Account, old_account_id)
        if old_acc and old_acc.user_id == user.id:
            old_acc.balance -= old_amount
    if row.account_id:
        new_acc = db.get(Account, row.account_id)
        if not new_acc or new_acc.user_id != user.id:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid account")
        new_acc.balance += row.amount

    db.commit()
    db.refresh(row)
    return row


@router.delete("/{income_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_income(
    income_id: UUID,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    row = db.get(Income, income_id)
    if not row or row.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Income not found")
    if row.account_id:
        acc = db.get(Account, row.account_id)
        if acc and acc.user_id == user.id:
            acc.balance -= row.amount
    db.delete(row)
    db.commit()
