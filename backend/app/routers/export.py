import csv
import io
from datetime import date, datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Account, Expense, User
from app.security import get_current_user

router = APIRouter(prefix="/export", tags=["export"])


@router.get("/expenses.csv")
def export_expenses_csv(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    rows = (
        db.query(Expense)
        .filter(Expense.payer_id == user.id)
        .order_by(Expense.date.desc())
        .all()
    )
    buf = io.StringIO()
    w = csv.writer(buf)
    w.writerow(
        [
            "id",
            "title",
            "amount",
            "currency",
            "date",
            "category_id",
            "group_id",
            "account_id",
            "notes",
        ]
    )
    for e in rows:
        w.writerow(
            [
                str(e.id),
                e.title,
                e.amount,
                e.currency,
                e.date.isoformat(),
                str(e.category_id) if e.category_id else "",
                str(e.group_id) if e.group_id else "",
                str(e.account_id) if e.account_id else "",
                e.notes or "",
            ]
        )
    buf.seek(0)
    return StreamingResponse(
        iter([buf.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=expenses.csv"},
    )


@router.get("/accounts.csv")
def export_accounts_csv(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    rows = db.query(Account).filter(Account.user_id == user.id).all()
    buf = io.StringIO()
    w = csv.writer(buf)
    w.writerow(["id", "name", "type", "balance", "currency", "is_default"])
    for a in rows:
        w.writerow(
            [str(a.id), a.name, a.type.value, a.balance, a.currency, a.is_default]
        )
    buf.seek(0)
    return StreamingResponse(
        iter([buf.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=accounts.csv"},
    )


@router.post("/expenses/import")
async def import_expenses_csv(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    file: UploadFile = File(...),
):
    raw = (await file.read()).decode("utf-8-sig")
    reader = csv.DictReader(io.StringIO(raw))
    created = 0
    errors: list[str] = []
    for i, row in enumerate(reader, start=2):
        try:
            title = (row.get("title") or row.get("description") or "").strip()
            amount_raw = (row.get("amount") or "").strip()
            if not title or not amount_raw:
                errors.append(f"Row {i}: missing title/amount")
                continue
            amount = int(float(amount_raw))
            if amount <= 0:
                # treat decimal yen/dollars as cents if float-like
                amount = abs(int(round(float(amount_raw) * 100)))
            date_str = (row.get("date") or date.today().isoformat()).strip()
            try:
                d = date.fromisoformat(date_str[:10])
            except ValueError:
                d = datetime.strptime(date_str[:10], "%Y/%m/%d").date()
            currency = (row.get("currency") or user.default_currency or "JPY").strip()
            notes = (row.get("notes") or "").strip() or None
            account_id = None
            if row.get("account_id"):
                account_id = UUID(row["account_id"])
            exp = Expense(
                title=title,
                amount=amount,
                currency=currency,
                date=d,
                payer_id=user.id,
                account_id=account_id,
                notes=notes,
            )
            db.add(exp)
            if account_id:
                acc = db.get(Account, account_id)
                if acc and acc.user_id == user.id:
                    acc.balance -= amount
            created += 1
        except Exception as e:
            errors.append(f"Row {i}: {e}")
    db.commit()
    return {"created": created, "errors": errors[:20]}
