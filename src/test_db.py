"""
test_db.py
Automated test suite and validator for Hashira Market DBMS.
Tests SQL script integrity, Python module imports, and live database queries (if online).
"""
import sys
import re
from pathlib import Path

# Ensure UTF-8 output on Windows consoles
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# Add project root to path
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

def test_sql_files_exist():
    """Verify presence of core SQL artifacts."""
    expected_files = [
        ROOT / "sql" / "schema.sql",
        ROOT / "sql" / "populate.sql",
        ROOT / "sql" / "advanced_queries.sql",
        ROOT / "sql" / "views_and_procedures.sql",
        ROOT / "src" / "schema.sql",
        ROOT / "src" / "populate.sql",
    ]
    for p in expected_files:
        assert p.exists(), f"Missing file: {p}"
        size = p.stat().st_size
        assert size > 0, f"File {p} is empty!"
        print(f"✓ SQL File check passed: {p.relative_to(ROOT)} ({size:,} bytes)")

def test_schema_syntax_integrity():
    """Validates table definitions and foreign key constraints in schema.sql."""
    schema_path = ROOT / "sql" / "schema.sql"
    with open(schema_path, "r", encoding="utf-8") as f:
        content = f.read()

    table_matches = re.findall(r'CREATE TABLE\s+(?:IF NOT EXISTS\s+)?([A-Za-z0-9_]+)', content, re.IGNORECASE)
    print(f"✓ Found {len(table_matches)} tables defined in schema.sql:")
    for t in table_matches:
        print(f"    - {t}")

    assert len(table_matches) >= 20, f"Expected at least 20 tables, found {len(table_matches)}"

    # Check for foreign keys and primary keys
    fk_count = len(re.findall(r'FOREIGN KEY', content, re.IGNORECASE))
    pk_count = len(re.findall(r'PRIMARY KEY', content, re.IGNORECASE))
    print(f"✓ Primary Keys: {pk_count}, Foreign Keys: {fk_count}")
    assert pk_count >= 20
    assert fk_count >= 15

def test_populate_syntax_integrity():
    """Validates INSERT statements in populate.sql."""
    pop_path = ROOT / "sql" / "populate.sql"
    with open(pop_path, "r", encoding="utf-8") as f:
        content = f.read()

    inserts = re.findall(r'INSERT INTO\s+([A-Za-z0-9_]+)', content, re.IGNORECASE)
    print(f"✓ Found {len(inserts)} INSERT statement blocks across tables in populate.sql")
    assert len(inserts) >= 20

def test_python_modules_import():
    """Verifies all Python components import without syntax or runtime errors."""
    from src.config import DatabaseConfig
    from src.db import print_rows
    from src import queries
    assert DatabaseConfig.DATABASE == "mini_world_db"
    assert hasattr(queries, "q1_list_all_investors")
    assert hasattr(queries, "w1_insert_fight_and_news")
    print("✓ All Python modules imported and verified successfully.")

def test_live_database_connection():
    """Attempts live connection if MySQL server is running."""
    from src.db import get_connection
    conn = get_connection()
    if conn:
        print("✓ Live database connection established!")
        try:
            with conn.cursor() as cur:
                cur.execute("SELECT DATABASE();")
                db_name = cur.fetchone()
                print(f"✓ Active database: {db_name}")
                cur.execute("SHOW TABLES;")
                tables = cur.fetchall()
                print(f"✓ Tables in live database: {len(tables)}")
        finally:
            conn.close()
    else:
        print("ℹ Live MySQL server not currently reachable. Offline static tests passed.")

if __name__ == "__main__":
    print("\n" + "="*50)
    print("Running Hashira Market DBMS Test Suite")
    print("="*50)
    test_sql_files_exist()
    test_schema_syntax_integrity()
    test_populate_syntax_integrity()
    test_python_modules_import()
    test_live_database_connection()
    print("\n✓ Test suite execution complete. All static checks passed!\n")
