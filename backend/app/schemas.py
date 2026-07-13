from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
    full_name: str | None = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class GoogleAuthRequest(BaseModel):
    id_token: str


class UserUpdate(BaseModel):
    full_name: str | None = None
    default_currency: str | None = None
    avatar_url: str | None = None


class UserOut(BaseModel):
    id: UUID
    email: EmailStr
    full_name: str | None
    avatar_url: str | None
    default_currency: str
    email_verified: bool
    created_at: datetime
    updated_at: datetime

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
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class IncomeCreate(BaseModel):
    amount: int = Field(gt=0)
    source: str
    date: date
    account_id: UUID | None = None
    currency: str = "JPY"
    notes: str | None = None


class IncomeOut(BaseModel):
    id: UUID
    user_id: UUID
    account_id: UUID | None
    amount: int
    currency: str
    source: str
    date: date
    notes: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class ExpenseCreate(BaseModel):
    title: str
    amount: int = Field(gt=0)
    currency: str = "JPY"
    category_id: UUID | None = None
    date: date
    group_id: UUID | None = None
    account_id: UUID | None = None
    notes: str | None = None
    payer_id: UUID | None = None
    splits: list["SplitCreate"] | None = None


class SplitCreate(BaseModel):
    user_id: UUID
    owed_amount: int = Field(ge=0)
    split_type: str = "equal"


class ExpenseOut(BaseModel):
    id: UUID
    title: str
    amount: int
    currency: str
    category_id: UUID | None
    date: date
    payer_id: UUID
    group_id: UUID | None
    account_id: UUID | None
    notes: str | None
    created_at: datetime
    category: CategoryOut | None = None
    profiles: UserOut | None = None

    model_config = {"from_attributes": True}


class GroupCreate(BaseModel):
    name: str
    type: str = "custom"
    currency: str = "JPY"


class GroupOut(BaseModel):
    id: UUID
    name: str
    type: str
    currency: str
    created_by: UUID
    created_at: datetime
    member_count: int | None = None
    role: str | None = None

    model_config = {"from_attributes": True}


class GroupMemberOut(BaseModel):
    id: UUID
    group_id: UUID
    user_id: UUID
    role: str
    joined_at: datetime
    profiles: UserOut | None = None

    model_config = {"from_attributes": True}


class InviteMember(BaseModel):
    email: EmailStr


class SettlementCreate(BaseModel):
    from_user_id: UUID
    to_user_id: UUID
    amount: int = Field(gt=0)
    group_id: UUID
    status: str = "completed"


class SettlementOut(BaseModel):
    id: UUID
    from_user_id: UUID
    to_user_id: UUID
    amount: int
    currency: str
    group_id: UUID
    status: str
    created_at: datetime
    settled_at: datetime | None
    from_profile: UserOut | None = None
    to_profile: UserOut | None = None

    model_config = {"from_attributes": True}


class DebtSimplifyOut(BaseModel):
    transactions: list[dict]
    balances: dict[str, int]


class DashboardSummary(BaseModel):
    net_worth: int
    owed_to_me: int
    i_owe: int
    monthly_spend: int


ExpenseCreate.model_rebuild()
