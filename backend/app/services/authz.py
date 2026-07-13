from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models import GroupMember, GroupRole, User


def is_group_member(db: Session, group_id: UUID, user_id: UUID) -> bool:
    return (
        db.query(GroupMember)
        .filter(GroupMember.group_id == group_id, GroupMember.user_id == user_id)
        .first()
        is not None
    )


def is_group_admin(db: Session, group_id: UUID, user_id: UUID) -> bool:
    row = (
        db.query(GroupMember)
        .filter(GroupMember.group_id == group_id, GroupMember.user_id == user_id)
        .first()
    )
    return row is not None and row.role == GroupRole.admin


def require_group_member(db: Session, group_id: UUID, user: User) -> GroupMember:
    row = (
        db.query(GroupMember)
        .filter(GroupMember.group_id == group_id, GroupMember.user_id == user.id)
        .first()
    )
    if not row:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not a group member")
    return row


def require_group_admin(db: Session, group_id: UUID, user: User) -> GroupMember:
    row = require_group_member(db, group_id, user)
    if row.role != GroupRole.admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Admin only")
    return row
