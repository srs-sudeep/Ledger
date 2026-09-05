from datetime import date
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_
from sqlalchemy.orm import Query as SAQuery, Session

from app.database import get_db
from app.models import Account, Transfer, User
from app.schemas import TransferCreate, TransferOut, TransferUpdate
from app.security import get_current_user

router = APIRouter(prefix="/transfers", tags=["transfers"])


def _validate_transfer_accounts(
    db: Session,
    user: User,
    from_account_id: UUID | None,
    to_account_id: UUID | None,
) -> tuple[Account | None, Account | None]:
    if not from_account_id and not to_account_id:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Transfer needs a source or destination account",
        )
    if from_account_id and to_account_id and from_account_id == to_account_id:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Source and destination accounts must differ",
        )

    from_acc = db.get(Account, from_account_id) if from_account_id else None
    to_acc = db.get(Account, to_account_id) if to_account_id else None
    for acc in (from_acc, to_acc):
        if acc and acc.user_id != user.id:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid account")
    if from_account_id and not from_acc:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid source account")
    if to_account_id and not to_acc:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid destination account")
    return from_acc, to_acc


def _apply_account_delta(
    amount: int,
    from_acc: Account | None,
    to_acc: Account | None,
) -> None:
    if from_acc:
        from_acc.balance -= amount
    if to_acc:
        to_acc.balance += amount


def _filtered_transfers(
    db: Session,
    user: User,
    search: str | None,
    account_id: UUID | None,
    from_date: date | None,
    to_date: date | None,
) -> SAQuery[Transfer]:
    q = db.query(Transfer).filter(Transfer.user_id == user.id)
    if account_id:
        q = q.filter(
            (Transfer.from_account_id == account_id) | (Transfer.to_account_id == account_id)
        )
    if from_date:
        q = q.filter(Transfer.date >= from_date)
    if to_date:
        q = q.filter(Transfer.date <= to_date)
    if search:
        term = f"%{search.strip()}%"
        q = q.filter(or_(Transfer.kind.ilike(term), Transfer.notes.ilike(term)))
    return q


def _sorted_transfers(q: SAQuery[Transfer], sort: str) -> SAQuery[Transfer]:
    if sort == "date_asc":
        return q.order_by(Transfer.date.asc(), Transfer.created_at.asc())
    if sort == "amount_desc":
        return q.order_by(Transfer.amount.desc(), Transfer.date.desc())
    if sort == "amount_asc":
        return q.order_by(Transfer.amount.asc(), Transfer.date.asc())
    if sort == "title_asc":
        return q.order_by(Transfer.kind.asc().nulls_last(), Transfer.date.desc())
    if sort == "title_desc":
        return q.order_by(Transfer.kind.desc().nulls_last(), Transfer.date.desc())
    return q.order_by(Transfer.date.desc(), Transfer.created_at.desc())


@router.get("/count")
def count_transfers(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    search: str | None = None,
    account_id: UUID | None = None,
    from_date: date | None = None,
    to_date: date | None = None,
):
    return {
        "count": _filtered_transfers(db, user, search, account_id, from_date, to_date).count()
    }


@router.get("", response_model=list[TransferOut])
def list_transfers(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    sort: str = Query("date_desc"),
    search: str | None = None,
    account_id: UUID | None = None,
    from_date: date | None = None,
    to_date: date | None = None,
):
    q = _sorted_transfers(
        _filtered_transfers(db, user, search, account_id, from_date, to_date),
        sort,
    )
    return q.offset(offset).limit(limit).all()


@router.post("", response_model=TransferOut, status_code=status.HTTP_201_CREATED)
def create_transfer(
    body: TransferCreate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    from_acc, to_acc = _validate_transfer_accounts(
        db, user, body.from_account_id, body.to_account_id
    )
    row = Transfer(
        user_id=user.id,
        from_account_id=body.from_account_id,
        to_account_id=body.to_account_id,
        amount=body.amount,
        currency=body.currency,
        date=body.date,
        kind=body.kind,
        notes=body.notes,
    )
    db.add(row)
    _apply_account_delta(body.amount, from_acc, to_acc)
    db.commit()
    db.refresh(row)
    return row


@router.patch("/{transfer_id}", response_model=TransferOut)
def update_transfer(
    transfer_id: UUID,
    body: TransferUpdate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    row = db.get(Transfer, transfer_id)
    if not row or row.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Transfer not found")

    old_amount = row.amount
    old_from = db.get(Account, row.from_account_id) if row.from_account_id else None
    old_to = db.get(Account, row.to_account_id) if row.to_account_id else None
    _apply_account_delta(-old_amount, old_from, old_to)

    data = body.model_dump(exclude_unset=True)
    next_from_id = data.get("from_account_id", row.from_account_id)
    next_to_id = data.get("to_account_id", row.to_account_id)
    next_amount = data.get("amount", row.amount)
    new_from, new_to = _validate_transfer_accounts(db, user, next_from_id, next_to_id)

    for k, v in data.items():
        setattr(row, k, v)

    _apply_account_delta(next_amount, new_from, new_to)
    db.commit()
    db.refresh(row)
    return row


@router.delete("/{transfer_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transfer(
    transfer_id: UUID,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    row = db.get(Transfer, transfer_id)
    if not row or row.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Transfer not found")
    from_acc = db.get(Account, row.from_account_id) if row.from_account_id else None
    to_acc = db.get(Account, row.to_account_id) if row.to_account_id else None
    _apply_account_delta(-row.amount, from_acc, to_acc)
    db.delete(row)
    db.commit()
