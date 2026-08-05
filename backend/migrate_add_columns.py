#!/usr/bin/env python3
"""
Migration script: tambah kolom yang missing di database production (PostgreSQL).
Jalankan SEKALI sebelum restart backend:
    cd backend
    python migrate_add_columns.py
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import text
from app.db.session import engine


def column_exists(conn, table: str, column: str) -> bool:
    """Works for both PostgreSQL and SQLite."""
    try:
        # PostgreSQL
        result = conn.execute(text(
            "SELECT COUNT(*) FROM information_schema.columns "
            "WHERE table_name = :t AND column_name = :c"
        ), {"t": table, "c": column})
        return result.scalar() > 0
    except Exception:
        # SQLite fallback
        result = conn.execute(text(
            f"SELECT COUNT(*) FROM pragma_table_info('{table}') WHERE name='{column}'"
        ))
        return result.scalar() > 0


def migrate():
    migrations = [
        # users.current_room_id — FK ke kost_rooms.id (nullable)
        {
            "table": "users",
            "column": "current_room_id",
            "sql_pg":     "ALTER TABLE users ADD COLUMN current_room_id INTEGER REFERENCES kost_rooms(id)",
            "sql_sqlite": "ALTER TABLE users ADD COLUMN current_room_id INTEGER REFERENCES kost_rooms(id)",
        },
        # reviews.manual_reviewer_name — nama custom untuk review manual admin
        {
            "table": "reviews",
            "column": "manual_reviewer_name",
            "sql_pg":     "ALTER TABLE reviews ADD COLUMN manual_reviewer_name VARCHAR",
            "sql_sqlite": "ALTER TABLE reviews ADD COLUMN manual_reviewer_name VARCHAR",
        },
    ]

    # Detect DB dialect
    dialect = engine.dialect.name  # 'postgresql' or 'sqlite'
    print(f"Database dialect: {dialect}")

    with engine.connect() as conn:
        for m in migrations:
            try:
                exists = column_exists(conn, m["table"], m["column"])
            except Exception as e:
                print(f"  [WARN] Could not check {m['table']}.{m['column']}: {e}")
                exists = False

            if exists:
                print(f"  [SKIP] {m['table']}.{m['column']} sudah ada")
            else:
                print(f"  [ADD]  {m['table']}.{m['column']}...")
                sql = m["sql_pg"] if dialect == "postgresql" else m["sql_sqlite"]
                try:
                    conn.execute(text(sql))
                    conn.commit()
                    print(f"         ✅ OK")
                except Exception as e:
                    # Column might already exist with different detection
                    if "already exists" in str(e).lower() or "duplicate column" in str(e).lower():
                        print(f"         [SKIP] Sudah ada (detected via error)")
                        conn.rollback()
                    else:
                        print(f"         ❌ Error: {e}")
                        conn.rollback()
                        raise

        # Verifikasi akhir
        print("\n--- Verifikasi ---")
        for m in migrations:
            try:
                ok = column_exists(conn, m["table"], m["column"])
                status = "✅" if ok else "❌"
                print(f"  {status} {m['table']}.{m['column']}")
            except Exception as e:
                print(f"  ⚠️  {m['table']}.{m['column']} - cek manual: {e}")


if __name__ == "__main__":
    print("🚀 Running database migration...")
    try:
        migrate()
        print("\n✅ Migration selesai!")
        print("\nLangkah selanjutnya:")
        print("  1. Restart backend server")
        print("  2. Approve ulang booking yang sudah ada dari dashboard admin")
        print("     (booking lama tidak otomatis ter-sync, perlu approve ulang)")
    except Exception as e:
        print(f"\n❌ Migration gagal: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
