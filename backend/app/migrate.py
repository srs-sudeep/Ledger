"""Apply SQL baseline files from backend/migrations/ on startup."""
from __future__ import annotations

import logging
from pathlib import Path

from sqlalchemy import text

from app.database import engine

log = logging.getLogger("migrate")
MIGRATIONS_DIR = Path(__file__).resolve().parent.parent / "migrations"


def apply_migrations() -> None:
    MIGRATIONS_DIR.mkdir(exist_ok=True)
    with engine.begin() as conn:
        conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS schema_migrations (
                  id TEXT PRIMARY KEY,
                  applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
                )
                """
            )
        )
        applied = {
            row[0]
            for row in conn.execute(text("SELECT id FROM schema_migrations")).fetchall()
        }

    files = sorted(MIGRATIONS_DIR.glob("*.sql"))
    for path in files:
        mid = path.name
        if mid in applied:
            continue
        sql = path.read_text()
        log.info("Applying migration %s", mid)
        # psycopg2 accepts multi-statement scripts on the DBAPI connection
        raw = engine.raw_connection()
        try:
            with raw.cursor() as cur:
                cur.execute(sql)
            raw.commit()
        except Exception:
            raw.rollback()
            raise
        finally:
            raw.close()
        with engine.begin() as conn:
            conn.execute(
                text("INSERT INTO schema_migrations (id) VALUES (:id)"),
                {"id": mid},
            )
