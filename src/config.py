"""
config.py
Configuration module for Hashira Market DBMS.
Supports environment variables (.env) with safe defaults.
"""
import os
from pathlib import Path

# Load .env if present
try:
    from dotenv import load_dotenv
    env_path = Path(__file__).resolve().parent.parent / '.env'
    if env_path.exists():
        load_dotenv(dotenv_path=env_path)
except ImportError:
    pass

class DatabaseConfig:
    HOST: str = os.getenv("DB_HOST", "localhost")
    PORT: int = int(os.getenv("DB_PORT", "3306"))
    USER: str = os.getenv("DB_USER", "root")
    PASSWORD: str = os.getenv("DB_PASS", "")
    DATABASE: str = os.getenv("DB_NAME", "mini_world_db")

    @classmethod
    def get_connection_dict(cls) -> dict:
        return {
            "host": cls.HOST,
            "port": cls.PORT,
            "user": cls.USER,
            "password": cls.PASSWORD,
            "database": cls.DATABASE,
        }

