import csv
import io
from datetime import date, datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Account, Expense, User
from app.security import get_current_user
from app.services.transactions import TransactionFilters, build_transaction_rows

router = APIRouter(prefix="/export", tags=["export"])


def _pdf_escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")


def _simple_pdf(lines: list[str]) -> bytes:
    page_height = 792
    line_height = 16
    top = 760
    pages = [lines[i : i + 38] for i in range(0, len(lines), 38)] or [[]]
    objects: list[bytes] = []

    def add_object(body: bytes) -> int:
        objects.append(body)
        return len(objects)

    font_id = add_object(b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>")
    page_ids: list[int] = []
    content_ids: list[int] = []

    for page_lines in pages:
        content_lines = [b"BT /F1 10 Tf 50 780 Td"]
        y = top
        for idx, line in enumerate(page_lines):
            if idx == 0:
                content_lines.append(f"({_pdf_escape(line)}) Tj".encode("latin-1", "replace"))
            else:
                content_lines.append(f"0 -{line_height} Td ({_pdf_escape(line)}) Tj".encode("latin-1", "replace"))
            y -= line_height
        content_lines.append(b"ET")
        stream = b"\n".join(content_lines)
        content_id = add_object(
            f"<< /Length {len(stream)} >>\nstream\n".encode() + stream + b"\nendstream"
        )
        content_ids.append(content_id)
        page_id = add_object(
            f"<< /Type /Page /Parent {{PAGES}} 0 R /MediaBox [0 0 612 {page_height}] /Resources << /Font << /F1 {font_id} 0 R >> >> /Contents {content_id} 0 R >>".encode()
        )
        page_ids.append(page_id)

    kids = " ".join(f"{page_id} 0 R" for page_id in page_ids)
    pages_id = add_object(
        f"<< /Type /Pages /Kids [{kids}] /Count {len(page_ids)} >>".encode()
    )

    for page_id in page_ids:
        objects[page_id - 1] = objects[page_id - 1].replace(b"{PAGES}", str(pages_id).encode())

    catalog_id = add_object(f"<< /Type /Catalog /Pages {pages_id} 0 R >>".encode())

    pdf = bytearray(b"%PDF-1.4\n")
    offsets = [0]
    for idx, obj in enumerate(objects, start=1):
        offsets.append(len(pdf))
        pdf.extend(f"{idx} 0 obj\n".encode())
        pdf.extend(obj)
        pdf.extend(b"\nendobj\n")
    xref_pos = len(pdf)
    pdf.extend(f"xref\n0 {len(objects) + 1}\n".encode())
    pdf.extend(b"0000000000 65535 f \n")
    for off in offsets[1:]:
        pdf.extend(f"{off:010d} 00000 n \n".encode())
    pdf.extend(
        f"trailer\n<< /Size {len(objects) + 1} /Root {catalog_id} 0 R >>\nstartxref\n{xref_pos}\n%%EOF".encode()
    )
    return bytes(pdf)


def _export_rows(rows: list[dict[str, str | int | None]], filename_base: str, export_format: str) -> StreamingResponse:
    if export_format == "csv":
        buf = io.StringIO()
        writer = csv.DictWriter(buf, fieldnames=list(rows[0].keys()) if rows else [])
        if rows:
            writer.writeheader()
            writer.writerows(rows)
        buf.seek(0)
        return StreamingResponse(
            iter([buf.getvalue()]),
            media_type="text/csv",
            headers={"Content-Disposition": f"attachment; filename={filename_base}.csv"},
        )

    if export_format == "excel":
        headers = list(rows[0].keys()) if rows else []
        table = [
            "<table><thead><tr>",
            *[f"<th>{header}</th>" for header in headers],
            "</tr></thead><tbody>",
        ]
        for row in rows:
            table.append("<tr>")
            table.extend(f"<td>{row.get(header, '') or ''}</td>" for header in headers)
            table.append("</tr>")
        table.append("</tbody></table>")
        html = (
            "<html><head><meta charset='utf-8'></head><body>"
            + "".join(table)
            + "</body></html>"
        )
        return StreamingResponse(
            iter([html]),
            media_type="application/vnd.ms-excel",
            headers={"Content-Disposition": f"attachment; filename={filename_base}.xls"},
        )

    if export_format == "pdf":
        headers = list(rows[0].keys()) if rows else []
        lines = [" | ".join(headers)] if headers else ["No rows"]
        for row in rows:
            lines.append(" | ".join(str(row.get(header, "") or "") for header in headers))
        return StreamingResponse(
            iter([_simple_pdf(lines)]),
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename={filename_base}.pdf"},
        )

    raise HTTPException(status_code=400, detail="Unsupported export format")


@router.get("/transactions")
def export_transactions(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    format: str = Query("csv", pattern="^(csv|excel|pdf)$"),
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
):
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
    export_rows = [
        {
            "date": row.date.isoformat(),
            "type": row.tx_type,
            "direction": row.direction,
            "title": row.title,
            "merchant_original": row.merchant_original or "",
            "merchant_display": row.merchant_display or "",
            "account": row.account_name or "",
            "counterparty_account": row.counterparty_account_name or "",
            "category": row.category_name or "",
            "amount": row.amount,
            "signed_amount": row.signed_amount,
            "currency": row.currency,
            "notes": row.notes or "",
        }
        for row in rows
    ]
    return _export_rows(export_rows, "transactions", format)


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
