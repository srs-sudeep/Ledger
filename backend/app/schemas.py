from __future__ import annotations

from datetime import date as Date, datetime as DateTime
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
    full_name: str | None = None
    phone_primary: str | None = None
    phone_secondary: str | None = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class GoogleAuthRequest(BaseModel):
    id_token: str


class UserUpdate(BaseModel):
    full_name: str | None = None
    phone_primary: str | None = None
    phone_secondary: str | None = None
    default_currency: str | None = None
    avatar_url: str | None = None


class UserOut(BaseModel):
    id: UUID
    email: EmailStr
    full_name: str | None
    phone_primary: str | None
    phone_secondary: str | None
    avatar_url: str | None
    default_currency: str
    email_verified: bool
    is_superuser: bool = False
    created_at: DateTime
    updated_at: DateTime

    model_config = {"from_attributes": True}


class CategoryOut(BaseModel):
    id: UUID
    name: str
    icon: str
    color: str | None

    model_config = {"from_attributes": True}


class AccountCreate(BaseModel):
    name: str
    type: str = "bank"
    balance: int = 0
    currency: str = "JPY"
    color: str | None = None
    is_default: bool = False


class AccountUpdate(BaseModel):
    name: str | None = None
    type: str | None = None
    balance: int | None = None
    currency: str | None = None
    color: str | None = None
    is_default: bool | None = None


class AccountOut(BaseModel):
    id: UUID
    user_id: UUID
    name: str
    type: str
    balance: int
    currency: str
    icon: str | None
    color: str | None
    is_default: bool
    created_at: DateTime
    updated_at: DateTime

    model_config = {"from_attributes": True}


class IncomeCreate(BaseModel):
    amount: int = Field(gt=0)
    source: str
    date: Date
    account_id: UUID | None = None
    currency: str = "JPY"
    notes: str | None = None


class IncomeUpdate(BaseModel):
    amount: int | None = Field(default=None, gt=0)
    source: str | None = None
    date: Date | None = None
    account_id: UUID | None = None
    currency: str | None = None
    notes: str | None = None


class IncomeOut(BaseModel):
    id: UUID
    user_id: UUID
    account_id: UUID | None
    amount: int
    currency: str
    source: str
    date: Date
    notes: str | None
    created_at: DateTime

    model_config = {"from_attributes": True}


class TransferCreate(BaseModel):
    amount: int = Field(gt=0)
    date: Date
    from_account_id: UUID | None = None
    to_account_id: UUID | None = None
    currency: str = "JPY"
    kind: str | None = None
    notes: str | None = None


class TransferUpdate(BaseModel):
    amount: int | None = Field(default=None, gt=0)
    date: Date | None = None
    from_account_id: UUID | None = None
    to_account_id: UUID | None = None
    currency: str | None = None
    kind: str | None = None
    notes: str | None = None


class TransferOut(BaseModel):
    id: UUID
    user_id: UUID
    from_account_id: UUID | None
    to_account_id: UUID | None
    amount: int
    currency: str
    date: Date
    kind: str | None
    notes: str | None
    created_at: DateTime

    model_config = {"from_attributes": True}


class ExpenseCreate(BaseModel):
    title: str
    amount: int = Field(gt=0)
    currency: str = "JPY"
    category_id: UUID | None = None
    date: Date
    group_id: UUID | None = None
    account_id: UUID | None = None
    notes: str | None = None
    payer_id: UUID | None = None
    splits: list["SplitCreate"] | None = None


class ExpenseUpdate(BaseModel):
    title: str | None = None
    amount: int | None = Field(default=None, gt=0)
    currency: str | None = None
    category_id: UUID | None = None
    date: Date | None = None
    account_id: UUID | None = None
    notes: str | None = None
    payer_id: UUID | None = None
    splits: list["SplitCreate"] | None = None


class SplitCreate(BaseModel):
    user_id: UUID
    owed_amount: int = Field(ge=0)
    split_type: str = "equal"


class SplitOut(BaseModel):
    id: UUID
    expense_id: UUID
    user_id: UUID
    owed_amount: int
    split_type: str
    profiles: UserOut | None = None

    model_config = {"from_attributes": True}


class ExpenseOut(BaseModel):
    id: UUID
    title: str
    amount: int
    currency: str
    category_id: UUID | None
    date: Date
    payer_id: UUID
    group_id: UUID | None
    account_id: UUID | None
    notes: str | None
    created_at: DateTime
    category: CategoryOut | None = None
    profiles: UserOut | None = None
    splits: list[SplitOut] | None = None

    model_config = {"from_attributes": True}


class GroupCreate(BaseModel):
    name: str
    type: str = "custom"
    currency: str = "JPY"


class GroupUpdate(BaseModel):
    name: str | None = None
    type: str | None = None
    currency: str | None = None


class GroupOut(BaseModel):
    id: UUID
    name: str
    type: str
    currency: str
    created_by: UUID
    created_at: DateTime
    member_count: int | None = None
    role: str | None = None

    model_config = {"from_attributes": True}


class GroupMemberOut(BaseModel):
    id: UUID
    group_id: UUID
    user_id: UUID
    role: str
    joined_at: DateTime
    profiles: UserOut | None = None

    model_config = {"from_attributes": True}


class InviteMember(BaseModel):
    email: EmailStr


class SettlementCreate(BaseModel):
    from_user_id: UUID
    to_user_id: UUID
    amount: int = Field(gt=0)
    group_id: UUID | None = None
    status: str = "completed"


class SettlementOut(BaseModel):
    id: UUID
    from_user_id: UUID
    to_user_id: UUID
    amount: int
    currency: str
    group_id: UUID
    status: str
    created_at: DateTime
    settled_at: DateTime | None
    from_profile: UserOut | None = None
    to_profile: UserOut | None = None

    model_config = {"from_attributes": True}


class DebtSimplifyOut(BaseModel):
    transactions: list[dict]
    balances: dict[str, int]


class DashboardSummary(BaseModel):
    net_worth: int
    asset_total: int
    liability_total: int
    group_net: int
    owed_to_me: int
    i_owe: int
    monthly_spend: int


class TransactionOut(BaseModel):
    id: str
    tx_type: str
    direction: str
    amount: int
    signed_amount: int
    currency: str
    title: str
    merchant_original: str | None = None
    merchant_display: str | None = None
    date: Date
    created_at: DateTime
    category_id: UUID | None = None
    category_name: str | None = None
    account_id: UUID | None = None
    account_name: str | None = None
    counterparty_account_id: UUID | None = None
    counterparty_account_name: str | None = None
    notes: str | None = None


class TransactionSummary(BaseModel):
    transaction_count: int
    income_total: int
    expense_total: int
    transfer_in_total: int
    transfer_out_total: int
    net_flow: int
    top_categories: list[AnalyticsByCategory]
    top_merchants: list[dict[str, int | str]]


class AnalyticsByCategory(BaseModel):
    category_id: UUID | None
    category_name: str
    color: str | None
    total: int


class AnalyticsByMonth(BaseModel):
    month: str
    personal: int
    group: int


class AnalyticsOut(BaseModel):
    personal_total: int
    group_total: int
    by_category: list[AnalyticsByCategory]
    by_month: list[AnalyticsByMonth]


class BudgetCreate(BaseModel):
    category_id: UUID
    amount: int = Field(gt=0)
    month: str  # YYYY-MM
    currency: str = "JPY"


class BudgetUpdate(BaseModel):
    amount: int | None = Field(default=None, gt=0)
    currency: str | None = None


class BudgetOut(BaseModel):
    id: UUID
    user_id: UUID
    category_id: UUID
    amount: int
    month: str
    currency: str
    spent: int = 0
    category: CategoryOut | None = None
    created_at: DateTime

    model_config = {"from_attributes": True}


class RecurringCreate(BaseModel):
    title: str
    amount: int = Field(gt=0)
    currency: str = "JPY"
    category_id: UUID | None = None
    account_id: UUID | None = None
    frequency: str = "monthly"  # monthly | weekly | yearly
    next_due: Date
    notes: str | None = None
    auto_create: bool = False


class RecurringUpdate(BaseModel):
    title: str | None = None
    amount: int | None = Field(default=None, gt=0)
    currency: str | None = None
    category_id: UUID | None = None
    account_id: UUID | None = None
    frequency: str | None = None
    next_due: Date | None = None
    notes: str | None = None
    auto_create: bool | None = None
    active: bool | None = None


class RecurringOut(BaseModel):
    id: UUID
    user_id: UUID
    title: str
    amount: int
    currency: str
    category_id: UUID | None
    account_id: UUID | None
    frequency: str
    next_due: Date
    notes: str | None
    auto_create: bool
    active: bool
    created_at: DateTime
    category: CategoryOut | None = None

    model_config = {"from_attributes": True}


ExpenseCreate.model_rebuild()
ExpenseUpdate.model_rebuild()
