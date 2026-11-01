"""
db.py
Database connection manager and table rendering utilities.
"""
import sys
import pymysql
from contextlib import contextmanager
from src.config import DatabaseConfig

def get_connection(host=None, port=None, user=None, password=None, database=None):
    """Establishes connection to MySQL database with interactive fallback."""
    h = host or DatabaseConfig.HOST
    p = port or DatabaseConfig.PORT
    u = user or DatabaseConfig.USER
    pw = password if password is not None else DatabaseConfig.PASSWORD
    db = database or DatabaseConfig.DATABASE

    try:
        conn = pymysql.connect(
            host=h,
            port=p,
            user=u,
            password=pw,
            database=db,
            cursorclass=pymysql.cursors.DictCursor,
            autocommit=False
        )
        return conn
    except pymysql.Error as e:
        return None

@contextmanager
def transaction(conn):
    """Context manager for ACID transaction handling."""
    try:
        yield conn
        conn.commit()
    except Exception as e:
        conn.rollback()
        print(f"\n[ERROR] Transaction failed and was rolled back: {e}", file=sys.stderr)
        raise

def print_rows(rows, title="Results"):
    """
    Renders query results in a clean formatted table.
    Uses 'tabulate' if available, otherwise falls back to aligned ASCII table.
    """
    print(f"\n=== {title} ===")
    if not rows:
        print("  (0 rows returned / empty set)\n")
        return

    try:
        from tabulate import tabulate
        headers = "keys"
        print(tabulate(rows, headers=headers, tablefmt="grid"))
    except ImportError:
        # Fallback manual formatting
        keys = list(rows[0].keys())
        # Compute column widths
        widths = {k: max(len(str(k)), max(len(str(r.get(k, ''))) for r in rows)) for k in keys}
        header_line = " | ".join(k.ljust(widths[k]) for k in keys)
        separator = "-+-".join("-" * widths[k] for k in keys)
        print(header_line)
        print(separator)
        for r in rows:
            print(" | ".join(str(r.get(k, '')).ljust(widths[k]) for k in keys))
    print(f"Total rows: {len(rows)}\n")

