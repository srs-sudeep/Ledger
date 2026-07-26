from datetime import datetime, timezone
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import (
    Expense,
    ExpenseSplit,
    Group,
    GroupMember,
    GroupRole,
    Settlement,
    SettlementStatus,
    User,
)
from app.schemas import (
    DebtSimplifyOut,
    GroupCreate,
    GroupMemberOut,
    GroupOut,
    GroupUpdate,
    InviteMember,
    SettlementCreate,
    SettlementOut,
    UserOut,
)
from app.security import get_current_user
from app.services.authz import require_group_admin, require_group_member
from app.services.debt import compute_group_balances, simplify_debts

router = APIRouter(prefix="/groups", tags=["groups"])


def _member_out(m: GroupMember, db: Session) -> GroupMemberOut:
    profile = db.get(User, m.user_id)
    return GroupMemberOut(
        id=m.id,
        group_id=m.group_id,
        user_id=m.user_id,
        role=m.role.value,
        joined_at=m.joined_at,
        profiles=UserOut.model_validate(profile) if profile else None,
    )


@router.get("", response_model=list[GroupOut])
def list_groups(
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    memberships = (
        db.query(GroupMember, Group)
        .join(Group, Group.id == GroupMember.group_id)
        .filter(GroupMember.user_id == user.id)
        .all()
    )
    out: list[GroupOut] = []
    for mem, group in memberships:
        count = (
            db.query(func.count(GroupMember.id))
            .filter(GroupMember.group_id == group.id)
            .scalar()
        )
        out.append(
            GroupOut(
                id=group.id,
                name=group.name,
                type=group.type.value,
                currency=group.currency,
                created_by=group.created_by,
                created_at=group.created_at,
                member_count=count or 0,
                role=mem.role.value,
            )
        )
    return out


@router.post("", response_model=GroupOut, status_code=status.HTTP_201_CREATED)
def create_group(
    body: GroupCreate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    from app.models import GroupType

    group = Group(
        name=body.name,
        type=GroupType(body.type),
        currency=body.currency,
        created_by=user.id,
    )
    db.add(group)
    db.flush()
    db.add(
        GroupMember(group_id=group.id, user_id=user.id, role=GroupRole.admin)
    )
    db.commit()
    db.refresh(group)
    return GroupOut(
        id=group.id,
        name=group.name,
        type=group.type.value,
        currency=group.currency,
        created_by=group.created_by,
        created_at=group.created_at,
        member_count=1,
        role="admin",
    )


@router.get("/{group_id}", response_model=GroupOut)
def get_group(
    group_id: UUID,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    mem = require_group_member(db, group_id, user)
    group = db.get(Group, group_id)
    if not group:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Group not found")
    count = (
        db.query(func.count(GroupMember.id))
        .filter(GroupMember.group_id == group_id)
        .scalar()
    )
    return GroupOut(
        id=group.id,
        name=group.name,
        type=group.type.value,
        currency=group.currency,
        created_by=group.created_by,
        created_at=group.created_at,
        member_count=count or 0,
        role=mem.role.value,
    )


@router.patch("/{group_id}", response_model=GroupOut)
def update_group(
    group_id: UUID,
    body: GroupUpdate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    from app.models import GroupType

    require_group_admin(db, group_id, user)
    group = db.get(Group, group_id)
    if not group:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Group not found")
    data = body.model_dump(exclude_unset=True)
    if "type" in data and data["type"] is not None:
        data["type"] = GroupType(data["type"])
    for k, v in data.items():
        setattr(group, k, v)
    db.commit()
    db.refresh(group)
    mem = require_group_member(db, group_id, user)
    count = (
        db.query(func.count(GroupMember.id))
        .filter(GroupMember.group_id == group_id)
        .scalar()
    )
    return GroupOut(
        id=group.id,
        name=group.name,
        type=group.type.value,
        currency=group.currency,
        created_by=group.created_by,
        created_at=group.created_at,
        member_count=count or 0,
        role=mem.role.value,
    )


@router.get("/{group_id}/members", response_model=list[GroupMemberOut])
def list_members(
    group_id: UUID,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    require_group_member(db, group_id, user)
    members = (
        db.query(GroupMember)
        .filter(GroupMember.group_id == group_id)
        .order_by(GroupMember.joined_at)
        .all()
    )
    return [_member_out(m, db) for m in members]


@router.post("/{group_id}/members", response_model=GroupMemberOut)
def invite_member(
    group_id: UUID,
    body: InviteMember,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    require_group_admin(db, group_id, user)
    invitee = db.query(User).filter(User.email == body.email.lower()).first()
    if not invitee:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "No registered user with that email",
        )
    existing = (
        db.query(GroupMember)
        .filter(
            GroupMember.group_id == group_id,
            GroupMember.user_id == invitee.id,
        )
        .first()
    )
    if existing:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Already a member")
    mem = GroupMember(
        group_id=group_id, user_id=invitee.id, role=GroupRole.member
    )
    db.add(mem)
    db.commit()
    db.refresh(mem)
    return _member_out(mem, db)


@router.delete("/{group_id}/members/{member_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_member(
    group_id: UUID,
    member_id: UUID,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    require_group_admin(db, group_id, user)
    mem = db.get(GroupMember, member_id)
    if not mem or mem.group_id != group_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Member not found")
    if mem.role == GroupRole.admin:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Cannot remove admin")
    db.delete(mem)
    db.commit()


@router.post("/{group_id}/simplify-debts", response_model=DebtSimplifyOut)
def simplify_group_debts(
    group_id: UUID,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    require_group_member(db, group_id, user)
    expenses = db.query(Expense).filter(Expense.group_id == group_id).all()
    if not expenses:
        return DebtSimplifyOut(transactions=[], balances={})

    expense_ids = [e.id for e in expenses]
    splits = (
        db.query(ExpenseSplit)
        .filter(ExpenseSplit.expense_id.in_(expense_ids))
        .all()
    )
    settlements = (
        db.query(Settlement)
        .filter(
            Settlement.group_id == group_id,
            Settlement.status == SettlementStatus.completed,
        )
        .all()
    )
    balance_map = compute_group_balances(expenses, splits, settlements)
    net = [
        {"userId": uid, "balance": bal}
        for uid, bal in balance_map.items()
        if abs(bal) > 0
    ]
    return DebtSimplifyOut(
        transactions=simplify_debts(net),
        balances=balance_map,
    )


@router.get("/{group_id}/settlements", response_model=list[SettlementOut])
def list_settlements(
    group_id: UUID,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    require_group_member(db, group_id, user)
    rows = (
        db.query(Settlement)
        .filter(Settlement.group_id == group_id)
        .order_by(Settlement.created_at.desc())
        .limit(50)
        .all()
    )
    out = []
    for row in rows:
        from_u = db.get(User, row.from_user_id)
        to_u = db.get(User, row.to_user_id)
        out.append(
            SettlementOut(
                id=row.id,
                from_user_id=row.from_user_id,
                to_user_id=row.to_user_id,
                amount=row.amount,
                currency=row.currency,
                group_id=row.group_id,
                status=row.status.value,
                created_at=row.created_at,
                settled_at=row.settled_at,
                from_profile=UserOut.model_validate(from_u) if from_u else None,
                to_profile=UserOut.model_validate(to_u) if to_u else None,
            )
        )
    return out


@router.post("/{group_id}/settlements", response_model=SettlementOut)
def create_settlement(
    group_id: UUID,
    body: SettlementCreate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    require_group_member(db, group_id, user)
    if body.from_user_id != user.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Only payer can settle")
    group = db.get(Group, group_id)
    row = Settlement(
        from_user_id=body.from_user_id,
        to_user_id=body.to_user_id,
        amount=body.amount,
        currency=group.currency if group else "JPY",
        group_id=group_id,
        status=SettlementStatus(body.status),
        settled_at=datetime.now(timezone.utc) if body.status == "completed" else None,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    from_u = db.get(User, row.from_user_id)
    to_u = db.get(User, row.to_user_id)
    return SettlementOut(
        id=row.id,
        from_user_id=row.from_user_id,
        to_user_id=row.to_user_id,
        amount=row.amount,
        currency=row.currency,
        group_id=row.group_id,
        status=row.status.value,
        created_at=row.created_at,
        settled_at=row.settled_at,
        from_profile=UserOut.model_validate(from_u) if from_u else None,
        to_profile=UserOut.model_validate(to_u) if to_u else None,
    )


@router.patch("/{group_id}/settlements/{settlement_id}", response_model=SettlementOut)
def complete_settlement(
    group_id: UUID,
    settlement_id: UUID,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    require_group_member(db, group_id, user)
    row = db.get(Settlement, settlement_id)
    if not row or row.group_id != group_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Settlement not found")
    if user.id not in (row.from_user_id, row.to_user_id):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not a party to this settlement")
    row.status = SettlementStatus.completed
    row.settled_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(row)
    from_u = db.get(User, row.from_user_id)
    to_u = db.get(User, row.to_user_id)
    return SettlementOut(
        id=row.id,
        from_user_id=row.from_user_id,
        to_user_id=row.to_user_id,
        amount=row.amount,
        currency=row.currency,
        group_id=row.group_id,
        status=row.status.value,
        created_at=row.created_at,
        settled_at=row.settled_at,
        from_profile=UserOut.model_validate(from_u) if from_u else None,
        to_profile=UserOut.model_validate(to_u) if to_u else None,
    )
