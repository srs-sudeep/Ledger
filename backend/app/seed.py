"""Seed demo users, accounts, groups, and expenses.

Usage (inside API container or with DATABASE_URL set):
  python -m app.seed
  python -m app.seed --reset   # wipe app data first (keeps categories/schema)
"""
from __future__ import annotations

import argparse
import sys
from datetime import date, timedelta

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models import (
    Account,
    AccountType,
    Budget,
    Category,
    Expense,
    ExpenseSplit,
    Group,
    GroupMember,
    GroupRole,
    GroupType,
    Income,
    SplitType,
    User,
)
from app.security import hash_password

SEED_USERS = [
    {
        "email": "admin@example.com",
        "password": "Admin123!",
        "full_name": "Super Admin",
        "is_superuser": True,
        "currency": "JPY",
    },
    {
        "email": "alice@example.com",
        "password": "Alice123!",
        "full_name": "Alice Tanaka",
        "is_superuser": False,
        "currency": "JPY",
    },
    {
        "email": "bob@example.com",
        "password": "Bob123!",
        "full_name": "Bob Suzuki",
        "is_superuser": False,
        "currency": "JPY",
    },
]


def reset_data(db: Session) -> None:
    db.execute(
        text(
            """
            TRUNCATE
              expense_splits,
              expenses,
              settlements,
              group_invitations,
              group_members,
              groups,
              income,
              budgets,
              recurring_expenses,
              accounts,
              users
            RESTART IDENTITY CASCADE
            """
        )
    )
    db.commit()


def cat(db: Session, name: str) -> Category:
    row = db.query(Category).filter(Category.name == name).one()
    return row


def seed(db: Session) -> None:
    if db.query(User).filter(User.email == "admin@example.com").first():
        print("Seed already applied (admin@example.com exists). Use --reset to wipe first.")
        return

    users: dict[str, User] = {}
    for u in SEED_USERS:
        user = User(
            email=u["email"],
            password_hash=hash_password(u["password"]),
            full_name=u["full_name"],
            email_verified=True,
            default_currency=u["currency"],
            is_superuser=u["is_superuser"],
        )
        db.add(user)
        db.flush()
        users[u["email"]] = user

    admin = users["admin@example.com"]
    alice = users["alice@example.com"]
    bob = users["bob@example.com"]

    admin_cash = Account(
        user_id=admin.id,
        name="Cash",
        type=AccountType.cash,
        balance=100_000,
        currency="JPY",
        is_default=True,
        color="#4CAF50",
    )
    alice_bank = Account(
        user_id=alice.id,
        name="Checking",
        type=AccountType.bank,
        balance=250_000,
        currency="JPY",
        is_default=True,
        color="#2196F3",
    )
    bob_wallet = Account(
        user_id=bob.id,
        name="Wallet",
        type=AccountType.wallet,
        balance=50_000,
        currency="JPY",
        is_default=True,
        color="#FF9800",
    )
    db.add_all([admin_cash, alice_bank, bob_wallet])
    db.flush()

    apartment = Group(
        name="Apartment",
        type=GroupType.home,
        currency="JPY",
        created_by=admin.id,
    )
    trip = Group(
        name="Tokyo Trip",
        type=GroupType.trip,
        currency="JPY",
        created_by=alice.id,
    )
    db.add_all([apartment, trip])
    db.flush()

    db.add_all(
        [
            GroupMember(group_id=apartment.id, user_id=admin.id, role=GroupRole.admin),
            GroupMember(group_id=apartment.id, user_id=alice.id, role=GroupRole.member),
            GroupMember(group_id=apartment.id, user_id=bob.id, role=GroupRole.member),
            GroupMember(group_id=trip.id, user_id=alice.id, role=GroupRole.admin),
            GroupMember(group_id=trip.id, user_id=bob.id, role=GroupRole.member),
        ]
    )

    today = date.today()
    groceries = cat(db, "Groceries")
    dining = cat(db, "Dining")
    transport = cat(db, "Transport")
    rent = cat(db, "Rent")

    personal = Expense(
        title="Weekly groceries",
        amount=4500,
        currency="JPY",
        category_id=groceries.id,
        date=today - timedelta(days=2),
        payer_id=admin.id,
        account_id=admin_cash.id,
        notes="Seed personal expense",
    )
    db.add(personal)
    db.flush()

    dinner = Expense(
        title="Dinner at home",
        amount=9000,
        currency="JPY",
        category_id=dining.id,
        date=today - timedelta(days=1),
        payer_id=alice.id,
        group_id=apartment.id,
        account_id=alice_bank.id,
    )
    db.add(dinner)
    db.flush()
    share = 9000 // 3
    db.add_all(
        [
            ExpenseSplit(
                expense_id=dinner.id,
                user_id=admin.id,
                owed_amount=share,
                split_type=SplitType.equal,
            ),
            ExpenseSplit(
                expense_id=dinner.id,
                user_id=alice.id,
                owed_amount=share,
                split_type=SplitType.equal,
            ),
            ExpenseSplit(
                expense_id=dinner.id,
                user_id=bob.id,
                owed_amount=9000 - 2 * share,
                split_type=SplitType.equal,
            ),
        ]
    )

    uber = Expense(
        title="Airport Uber",
        amount=3200,
        currency="JPY",
        category_id=transport.id,
        date=today - timedelta(days=5),
        payer_id=bob.id,
        group_id=trip.id,
        account_id=bob_wallet.id,
    )
    db.add(uber)
    db.flush()
    db.add_all(
        [
            ExpenseSplit(
                expense_id=uber.id,
                user_id=alice.id,
                owed_amount=1600,
                split_type=SplitType.equal,
            ),
            ExpenseSplit(
                expense_id=uber.id,
                user_id=bob.id,
                owed_amount=1600,
                split_type=SplitType.equal,
            ),
        ]
    )

    rent_exp = Expense(
        title="July rent",
        amount=120_000,
        currency="JPY",
        category_id=rent.id,
        date=today.replace(day=1),
        payer_id=admin.id,
        group_id=apartment.id,
        account_id=admin_cash.id,
    )
    db.add(rent_exp)
    db.flush()
    rent_share = 40_000
    db.add_all(
        [
            ExpenseSplit(
                expense_id=rent_exp.id,
                user_id=admin.id,
                owed_amount=rent_share,
                split_type=SplitType.exact,
            ),
            ExpenseSplit(
                expense_id=rent_exp.id,
                user_id=alice.id,
                owed_amount=rent_share,
                split_type=SplitType.exact,
            ),
            ExpenseSplit(
                expense_id=rent_exp.id,
                user_id=bob.id,
                owed_amount=rent_share,
                split_type=SplitType.exact,
            ),
        ]
    )

    db.add(
        Income(
            user_id=alice.id,
            account_id=alice_bank.id,
            amount=300_000,
            currency="JPY",
            source="Salary",
            date=today.replace(day=25) if today.day >= 25 else today - timedelta(days=5),
            notes="Seed income",
        )
    )
    db.add(
        Budget(
            user_id=alice.id,
            category_id=groceries.id,
            amount=40_000,
            month=today.strftime("%Y-%m"),
            currency="JPY",
        )
    )

    db.commit()
    print("Seed complete.")
    print("")
    print("Accounts:")
    for u in SEED_USERS:
        role = "superadmin" if u["is_superuser"] else "user"
        print(f"  {u['email']} / {u['password']}  ({role}, {u['full_name']})")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Seed Ledger demo data")
    parser.add_argument(
        "--reset",
        action="store_true",
        help="Wipe users/accounts/groups/expenses before seeding",
    )
    args = parser.parse_args(argv)

    db = SessionLocal()
    try:
        if args.reset:
            print("Resetting app data…")
            reset_data(db)
        seed(db)
    finally:
        db.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
