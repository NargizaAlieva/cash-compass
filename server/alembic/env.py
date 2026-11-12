"""Alembic runs this file for every migration command."""

from logging.config import fileConfig

from alembic import context
from sqlalchemy import create_engine, pool

import app.models  # noqa: F401 - imports every table, so Alembic can see them
from app.core.database import Base, database_url

config = context.config

# Logging from alembic.ini (keep the loggers of a running server working)
if config.config_file_name is not None:
    fileConfig(config.config_file_name, disable_existing_loggers=False)

target_metadata = Base.metadata


def run_migrations_online() -> None:
    # The address can be passed by the code (see app/core/migrations.py),
    # otherwise it comes from .env like for the server itself
    url = config.get_main_option("sqlalchemy.url") or database_url
    engine = create_engine(url, poolclass=pool.NullPool)

    with engine.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            # SQLite cannot change a column directly, "batch" mode
            # copies the table instead
            render_as_batch=connection.dialect.name == "sqlite",
            compare_type=True,
        )
        with context.begin_transaction():
            context.run_migrations()


run_migrations_online()