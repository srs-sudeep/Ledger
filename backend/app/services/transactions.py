from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from uuid import UUID

from sqlalchemy.orm import Session

from app.models import Account, Category, Expense, Income, Transfer, User
from app.schemas import AnalyticsByCategory, TransactionOut, TransactionSummary
from app.services.labels import translate_label


@dataclass
class TransactionFilters:
    account_id: UUID | None = None
    tx_type: str | None = None
    direction: str | None = None
    category_id: UUID | None = None
    search: str | None = None
    from_date: date | None = None
    to_date: date | None = None
    sort: str = "date_desc"


def _match_search(*values: str | None, search: str | None) -> bool:
    if not search:
        return True
    needle = search.strip().lower()
    if not needle:
        return True
    return any(needle in (value or "").lower() for value in values)


def _sorted_transactions(rows: list[TransactionOut], sort: str) -> list[TransactionOut]:
    if sort == "date_asc":
        return sorted(rows, key=lambda tx: (tx.date, tx.created_at.isoformat(), tx.id))
    if sort == "amount_desc":
        return sorted(rows, key=lambda tx: (abs(tx.signed_amount), tx.date, tx.id), reverse=True)
    if sort == "amount_asc":
        return sorted(rows, key=lambda tx: (abs(tx.signed_amount), tx.date, tx.id))
    if sort == "title_asc":
        return sorted(rows, key=lambda tx: ((tx.title or "").lower(), tx.date, tx.id))
    if sort == "title_desc":
        return sorted(rows, key=lambda tx: ((tx.title or "").lower(), tx.date, tx.id), reverse=True)
    if sort == "type_asc":
        return sorted(rows, key=lambda tx: (tx.tx_type, tx.date, tx.id))
    if sort == "type_desc":
        return sorted(rows, key=lambda tx: (tx.tx_type, tx.date, tx.id), reverse=True)
    if sort == "account_asc":
        return sorted(rows, key=lambda tx: ((tx.account_name or "").lower(), tx.date, tx.id))
    if sort == "account_desc":
        return sorted(
            rows, key=lambda tx: ((tx.account_name or "").lower(), tx.date, tx.id), reverse=True
        )
    if sort == "category_asc":
        return sorted(rows, key=lambda tx: ((tx.category_name or "").lower(), tx.date, tx.id))
    if sort == "category_desc":
        return sorted(
            rows, key=lambda tx: ((tx.category_name or "").lower(), tx.date, tx.id), reverse=True
        )
    return sorted(rows, key=lambda tx: (tx.date, tx.created_at.isoformat(), tx.id), reverse=True)


def _expense_direction(_: Expense, filtered_account_id: UUID | None) -> tuple[str, int]:
    return ("outflow", -1)


def _income_direction(_: Income, filtered_account_id: UUID | None) -> tuple[str, int]:
    return ("inflow", 1)


def _transfer_direction(
    row: Transfer, filtered_account_id: UUID | None
) -> tuple[str, int, UUID | None, UUID | None]:
    if filtered_account_id:
        if row.from_account_id == filtered_account_id:
            return ("outflow", -1, row.from_account_id, row.to_account_id)
        if row.to_account_id == filtered_account_id:
            return ("inflow", 1, row.to_account_id, row.from_account_id)
    if row.from_account_id and row.to_account_id:
        return ("transfer", 0, row.from_account_id, row.to_account_id)
    if row.to_account_id:
        return ("inflow", 1, row.to_account_id, None)
    return ("outflow", -1, row.from_account_id, None)


def build_transaction_rows(
    db: Session,
    user: User,
    filters: TransactionFilters,
) -> list[TransactionOut]:
    accounts = {
        row.id: row
        for row in db.query(Account).filter(Account.user_id == user.id).all()
    }
    categories = {row.id: row for row in db.query(Category).all()}
    out: list[TransactionOut] = []
    direction_filter = filters.direction

    if filters.tx_type in (None, "expense"):
        q = db.query(Expense).filter(Expense.payer_id == user.id, Expense.group_id.is_(None))
        if filters.from_date:
            q = q.filter(Expense.date >= filters.from_date)
        if filters.to_date:
            q = q.filter(Expense.date <= filters.to_date)
        if filters.category_id:
            q = q.filter(Expense.category_id == filters.category_id)
        if filters.account_id:
            q = q.filter(Expense.account_id == filters.account_id)
        for row in q.all():
            category = categories.get(row.category_id)
            display = translate_label(row.title) or row.title
            if not _match_search(
                row.title,
                display,
                row.notes,
                category.name if category else None,
                search=filters.search,
            ):
                continue
            direction, sign = _expense_direction(row, filters.account_id)
            account = accounts.get(row.account_id) if row.account_id else None
            if direction_filter and direction != direction_filter:
                continue
            out.append(
                TransactionOut(
                    id=str(row.id),
                    tx_type="expense",
                    direction=direction,
                    amount=row.amount,
                    signed_amount=row.amount * sign,
                    currency=row.currency,
                    title=display,
                    merchant_original=row.title,
                    merchant_display=display,
                    date=row.date,
                    created_at=row.created_at,
                    category_id=row.category_id,
                    category_name=category.name if category else None,
                    account_id=row.account_id,
                    account_name=account.name if account else None,
                    notes=row.notes,
                )
            )

    if filters.tx_type in (None, "income"):
        q = db.query(Income).filter(Income.user_id == user.id)
        if filters.from_date:
            q = q.filter(Income.date >= filters.from_date)
        if filters.to_date:
            q = q.filter(Income.date <= filters.to_date)
        if filters.account_id:
            q = q.filter(Income.account_id == filters.account_id)
        for row in q.all():
            display = translate_label(row.source) or row.source
            if not _match_search(row.source, display, row.notes, search=filters.search):
                continue
            direction, sign = _income_direction(row, filters.account_id)
            account = accounts.get(row.account_id) if row.account_id else None
            if direction_filter and direction != direction_filter:
                continue
            out.append(
                TransactionOut(
                    id=str(row.id),
                    tx_type="income",
                    direction=direction,
                    amount=row.amount,
                    signed_amount=row.amount * sign,
                    currency=row.currency,
                    title=display,
                    merchant_original=row.source,
                    merchant_display=display,
                    date=row.date,
                    created_at=row.created_at,
                    account_id=row.account_id,
                    account_name=account.name if account else None,
                    notes=row.notes,
                )
            )

    if filters.tx_type in (None, "transfer"):
        q = db.query(Transfer).filter(Transfer.user_id == user.id)
        if filters.from_date:
            q = q.filter(Transfer.date >= filters.from_date)
        if filters.to_date:
            q = q.filter(Transfer.date <= filters.to_date)
        if filters.account_id:
            q = q.filter(
                (Transfer.from_account_id == filters.account_id)
                | (Transfer.to_account_id == filters.account_id)
            )
        for row in q.all():
            direction, sign, account_id, counterparty_id = _transfer_direction(row, filters.account_id)
            account = accounts.get(account_id) if account_id else None
            counterparty = accounts.get(counterparty_id) if counterparty_id else None
            original = row.kind or "Transfer"
            display = translate_label(original) or original
            if not _match_search(
                row.kind,
                display,
                row.notes,
                account.name if account else None,
                counterparty.name if counterparty else None,
                search=filters.search,
            ):
                continue
            if direction_filter and direction != direction_filter:
                continue
            out.append(
                TransactionOut(
                    id=str(row.id),
                    tx_type="transfer",
                    direction=direction,
                    amount=row.amount,
                    signed_amount=row.amount * sign,
                    currency=row.currency,
                    title=display,
                    merchant_original=original,
                    merchant_display=display,
                    date=row.date,
                    created_at=row.created_at,
                    account_id=account_id,
                    account_name=account.name if account else None,
                    counterparty_account_id=counterparty_id,
                    counterparty_account_name=counterparty.name if counterparty else None,
                    notes=row.notes,
                )
            )

    return _sorted_transactions(out, filters.sort)


def summarize_transactions(rows: list[TransactionOut]) -> TransactionSummary:
    income_total = sum(row.amount for row in rows if row.tx_type == "income")
    expense_total = sum(row.amount for row in rows if row.tx_type == "expense")
    transfer_in_total = sum(
        row.amount for row in rows if row.tx_type == "transfer" and row.signed_amount > 0
    )
    transfer_out_total = sum(
        row.amount for row in rows if row.tx_type == "transfer" and row.signed_amount < 0
    )

    cat_totals: dict[tuple[str | None, str], int] = {}
    merchant_totals: dict[str, int] = {}
    for row in rows:
        if row.tx_type == "expense":
            key = (str(row.category_id) if row.category_id else None, row.category_name or "Uncategorized")
            cat_totals[key] = cat_totals.get(key, 0) + row.amount
        if row.tx_type == "expense":
            merchant = row.merchant_display or row.title
            merchant_totals[merchant] = merchant_totals.get(merchant, 0) + row.amount

    top_categories = [
        AnalyticsByCategory(category_id=UUID(cid) if cid else None, category_name=name, color=None, total=total)
        for (cid, name), total in sorted(cat_totals.items(), key=lambda item: item[1], reverse=True)[:5]
    ]
    top_merchants = [
        {"name": name, "total": total}
        for name, total in sorted(merchant_totals.items(), key=lambda item: item[1], reverse=True)[:5]
    ]

    return TransactionSummary(
        transaction_count=len(rows),
        income_total=income_total,
        expense_total=expense_total,
        transfer_in_total=transfer_in_total,
        transfer_out_total=transfer_out_total,
        net_flow=sum(row.signed_amount for row in rows),
        top_categories=top_categories,
        top_merchants=top_merchants,
    )
