from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models import User
from app.schemas import (
    GoogleAuthRequest,
    TokenResponse,
    UserLogin,
    UserOut,
    UserRegister,
    UserUpdate,
)
from app.security import (
    create_access_token,
    get_current_user,
    hash_password,
    verify_password,
)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse)
def register(body: UserRegister, db: Annotated[Session, Depends(get_db)]):
    if db.query(User).filter(User.email == body.email.lower()).first():
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Email already registered")
    user = User(
        email=body.email.lower(),
        password_hash=hash_password(body.password),
        full_name=body.full_name,
        email_verified=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return TokenResponse(access_token=create_access_token(user.id))


@router.post("/login", response_model=TokenResponse)
def login(body: UserLogin, db: Annotated[Session, Depends(get_db)]):
    user = db.query(User).filter(User.email == body.email.lower()).first()
    if not user:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid credentials")
    if not user.password_hash:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            "This account uses Google sign-in",
        )
    if not verify_password(body.password, user.password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid credentials")
    return TokenResponse(access_token=create_access_token(user.id))


@router.post("/google", response_model=TokenResponse)
def google_auth(body: GoogleAuthRequest, db: Annotated[Session, Depends(get_db)]):
    if not settings.google_client_id:
        raise HTTPException(
            status.HTTP_501_NOT_IMPLEMENTED,
            "Google sign-in is not configured (set GOOGLE_CLIENT_ID in .env)",
        )
    try:
        idinfo = id_token.verify_oauth2_token(
            body.id_token,
            google_requests.Request(),
            settings.google_client_id,
        )
    except ValueError as e:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, f"Invalid Google token: {e}")

    google_sub = idinfo.get("sub")
    email = idinfo.get("email")
    if not google_sub or not email:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Google account missing email")

    email = email.lower()
    user = (
        db.query(User)
        .filter((User.google_id == google_sub) | (User.email == email))
        .first()
    )

    if user:
        if not user.google_id:
            if user.password_hash:
                user.google_id = google_sub
            else:
                user.google_id = google_sub
        user.email_verified = True
        if idinfo.get("name") and not user.full_name:
            user.full_name = idinfo.get("name")
        if idinfo.get("picture") and not user.avatar_url:
            user.avatar_url = idinfo.get("picture")
    else:
        user = User(
            email=email,
            google_id=google_sub,
            full_name=idinfo.get("name"),
            avatar_url=idinfo.get("picture"),
            email_verified=True,
        )
        db.add(user)

    db.commit()
    db.refresh(user)
    return TokenResponse(access_token=create_access_token(user.id))


@router.get("/me", response_model=UserOut)
def me(user: Annotated[User, Depends(get_current_user)]):
    return user


@router.patch("/me", response_model=UserOut)
def update_me(
    body: UserUpdate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    if body.full_name is not None:
        user.full_name = body.full_name
    if body.default_currency is not None:
        user.default_currency = body.default_currency
    if body.avatar_url is not None:
        user.avatar_url = body.avatar_url
    db.commit()
    db.refresh(user)
    return user
