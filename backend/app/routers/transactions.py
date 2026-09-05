from __future__ import annotations

from datetime import date
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Account, User
from app.schemas import TransactionOut, TransactionSummary
from app.security import get_current_user
from app.services.transactions import (
    TransactionFilters,
    build_transaction_rows,
    summarize_transactions,
)

router = APIRouter(prefix="/transactions", tags=["transactions"])


def _filters(
    account_id: UUID | None = None,
    tx_type: str | None = Query(default=None, pattern="^(expense|income|transfer)$"),
    direction: str | None = Query(default=None, pattern="^(inflow|outflow|transfer)$"),
    category_id: UUID | None = None,
    search: str | None = None,
    from_date: date | None = None,
    to_date: date | None = None,
    sort: str = Query(
        "date_desc",
        pattern="^(date_desc|date_asc|amount_desc|amount_asc|title_asc|title_desc|type_asc|type_desc|account_asc|account_desc|category_asc|category_desc)$",
    ),
) -> TransactionFilters:
    return TransactionFilters(
        account_id=account_id,
        tx_type=tx_type,
        direction=direction,
        category_id=category_id,
        search=search,
        from_date=from_date,
        to_date=to_date,
        sort=sort,
    )


def _require_account(db: Session, user: User, account_id: UUID) -> None:
    account = db.get(Account, account_id)
    if not account or account.user_id != user.id:
        raise HTTPException(status_code=404, detail="Account not found")


@router.get("", response_model=list[TransactionOut])
def list_transactions(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    filters: Annotated[TransactionFilters, Depends(_filters)],
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
):
    if filters.account_id:
        _require_account(db, user, filters.account_id)
    rows = build_transaction_rows(db, user, filters)
    return rows[offset : offset + limit]


@router.get("/summary", response_model=TransactionSummary)
def transactions_summary(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    filters: Annotated[TransactionFilters, Depends(_filters)],
):
    if filters.account_id:
        _require_account(db, user, filters.account_id)
    rows = build_transaction_rows(db, user, filters)
    return summarize_transactions(rows)


@router.get("/accounts/{account_id}", response_model=list[TransactionOut])
def account_transactions(
    account_id: UUID,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    tx_type: str | None = Query(default=None, pattern="^(expense|income|transfer)$"),
    direction: str | None = Query(default=None, pattern="^(inflow|outflow|transfer)$"),
    category_id: UUID | None = None,
    search: str | None = None,
    from_date: date | None = None,
    to_date: date | None = None,
    sort: str = Query(
        "date_desc",
        pattern="^(date_desc|date_asc|amount_desc|amount_asc|title_asc|title_desc|type_asc|type_desc|account_asc|account_desc|category_asc|category_desc)$",
    ),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
):
    _require_account(db, user, account_id)
    rows = build_transaction_rows(
        db,
        user,
        TransactionFilters(
            account_id=account_id,
            tx_type=tx_type,
            direction=direction,
            category_id=category_id,
            search=search,
            from_date=from_date,
            to_date=to_date,
            sort=sort,
        ),
    )
    return rows[offset : offset + limit]
