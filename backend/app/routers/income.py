from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Account, Income, User
from app.schemas import IncomeCreate, IncomeOut
from app.security import get_current_user

router = APIRouter(prefix="/income", tags=["income"])


@router.get("", response_model=list[IncomeOut])
def list_income(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    limit: int = 10,
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
