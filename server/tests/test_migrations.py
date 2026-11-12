from alembic import command
from alembic.autogenerate import compare_metadata
from alembic.migration import MigrationContext
from sqlalchemy import create_engine, inspect, text

import app.models  # noqa: F401 - registers all tables
from app.core.database import Base
from app.core.migrations import INITIAL_REVISION, alembic_config, run_migrations


def sqlite_url(tmp_path) -> str:
    return f"sqlite:///{(tmp_path / 'test.db').as_posix()}"


def current_revision(url: str) -> str:
    engine = create_engine(url)
    with engine.connect() as connection:
        revision = connection.execute(text("select version_num from alembic_version")).scalar()
    engine.dispose()
    return revision


def test_migrations_match_the_models(tmp_path):
    """If a model changes without a new migration, this test fails.

    Fix: alembic revision --autogenerate -m "what changed"
    """
    url = sqlite_url(tmp_path)
    run_migrations(url)

    engine = create_engine(url)
    with engine.connect() as connection:
        differences = compare_metadata(MigrationContext.configure(connection), Base.metadata)
    engine.dispose()
    assert differences == []


def test_old_database_without_alembic_is_kept(tmp_path):
    """A database made with create_all (before Alembic) keeps its data."""
    url = sqlite_url(tmp_path)
    # Build the tables exactly as they were before Alembic (= version 0001),
    # then remove Alembic's own table, like on the first deploy
    command.upgrade(alembic_config(url), INITIAL_REVISION)
    engine = create_engine(url)
    with engine.begin() as connection:
        connection.execute(text("drop table alembic_version"))
    with engine.begin() as connection:
        connection.execute(text(
            "insert into users (email, password_hash, name, created_at) "
            "values ('old@example.com', 'x', 'Old', '2026-01-01')"
        ))
    engine.dispose()

    run_migrations(url)

    engine = create_engine(url)
    with engine.connect() as connection:
        emails = connection.execute(text("select email from users")).scalars().all()
    engine.dispose()
    assert emails == ["old@example.com"]
    # The old database got all the new tables too
    engine = create_engine(url)
    assert "recurring_payments" in inspect(engine).get_table_names()
    engine.dispose()
    assert current_revision(url) is not None


def test_running_twice_is_safe(tmp_path):
    url = sqlite_url(tmp_path)
    run_migrations(url)
    first = current_revision(url)
    run_migrations(url)
    assert current_revision(url) == first
    assert first >= INITIAL_REVISION

    engine = create_engine(url)
    assert "transactions" in inspect(engine).get_table_names()
    engine.dispose()