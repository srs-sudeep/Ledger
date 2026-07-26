from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Account, AccountType, User
from app.schemas import AccountCreate, AccountOut, AccountUpdate
from app.security import get_current_user

router = APIRouter(prefix="/accounts", tags=["accounts"])


@router.get("", response_model=list[AccountOut])
def list_accounts(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    return (
        db.query(Account)
        .filter(Account.user_id == user.id)
        .order_by(Account.is_default.desc(), Account.created_at.desc())
        .all()
    )


@router.post("", response_model=AccountOut, status_code=status.HTTP_201_CREATED)
def create_account(
    body: AccountCreate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    if body.is_default:
        db.query(Account).filter(Account.user_id == user.id).update(
            {"is_default": False}
        )
    acc = Account(
        user_id=user.id,
        name=body.name,
        type=AccountType(body.type),
        balance=body.balance,
        currency=body.currency,
        color=body.color,
        is_default=body.is_default,
    )
    db.add(acc)
    db.commit()
    db.refresh(acc)
    return acc


@router.patch("/{account_id}", response_model=AccountOut)
def update_account(
    account_id: UUID,
    body: AccountUpdate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    acc = db.get(Account, account_id)
    if not acc or acc.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Account not found")
    data = body.model_dump(exclude_unset=True)
    if data.get("is_default"):
        db.query(Account).filter(Account.user_id == user.id).update(
            {"is_default": False}
        )
    if "type" in data and data["type"] is not None:
        data["type"] = AccountType(data["type"])
    for k, v in data.items():
        setattr(acc, k, v)
    db.commit()
    db.refresh(acc)
    return acc


@router.delete("/{account_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_account(
    account_id: UUID,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    acc = db.get(Account, account_id)
    if not acc or acc.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Account not found")
    db.delete(acc)
    db.commit()
