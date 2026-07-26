from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers import (
    accounts,
    analytics,
    auth,
    budgets,
    categories,
    dashboard,
    expenses,
    export,
    groups,
    income,
    recurring,
)

app = FastAPI(title="The Ledger API", version="1.1.0")

origins = [o.strip() for o in settings.cors_origins.split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api")
app.include_router(categories.router, prefix="/api")
app.include_router(accounts.router, prefix="/api")
app.include_router(income.router, prefix="/api")
app.include_router(expenses.router, prefix="/api")
app.include_router(groups.router, prefix="/api")
app.include_router(dashboard.router, prefix="/api")
app.include_router(analytics.router, prefix="/api")
app.include_router(budgets.router, prefix="/api")
app.include_router(recurring.router, prefix="/api")
app.include_router(export.router, prefix="/api")


@app.on_event("startup")
def run_migrations() -> None:
    from app.migrate import apply_migrations

    apply_migrations()


@app.get("/api/health")
def health():
    return {"status": "ok"}
