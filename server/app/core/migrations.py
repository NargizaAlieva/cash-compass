"""Brings the database to the newest version when the server starts."""

from pathlib import Path

from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, inspect

from app.core.database import database_url

SERVER_DIR = Path(__file__).resolve().parents[2]

# The first migration: it creates the tables that existed before Alembic
INITIAL_REVISION = "0001"


def alembic_config(url: str) -> Config:
    config = Config(str(SERVER_DIR / "alembic.ini"))
    config.set_main_option("script_location", str(SERVER_DIR / "alembic"))
    # "%" has a special meaning in .ini values, so it must be doubled
    config.set_main_option("sqlalchemy.url", url.replace("%", "%%"))
    return config


def run_migrations(url: str = database_url) -> None:
    config = alembic_config(url)

    engine = create_engine(url)
    tables = inspect(engine).get_table_names()
    engine.dispose()

    # Databases made before Alembic (local SQLite, the first deploy on Render)
    # already have the tables. We only mark them as "version 0001",
    # otherwise Alembic would try to create the same tables again.
    if "users" in tables and "alembic_version" not in tables:
        command.stamp(config, INITIAL_REVISION)

    command.upgrade(config, "head")