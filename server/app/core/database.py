from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from app.core.config import settings


def normalize_database_url(url: str) -> str:
    """Render gives "postgresql://..." (old services: "postgres://...").

    SQLAlchemy also needs to know the driver, so we turn it into
    "postgresql+psycopg://...". SQLite URLs stay as they are.
    """
    if url.startswith("postgres://"):
        url = "postgresql://" + url.removeprefix("postgres://")
    if url.startswith("postgresql://"):
        url = "postgresql+psycopg://" + url.removeprefix("postgresql://")
    return url


database_url = normalize_database_url(settings.database_url)

# SQLite needs this flag to be used from several threads
connect_args = {"check_same_thread": False} if database_url.startswith("sqlite") else {}

engine = create_engine(
    database_url,
    connect_args=connect_args,
    # Check the connection before using it: a free cloud database
    # may close idle connections
    pool_pre_ping=True,
)
SessionLocal = sessionmaker(bind=engine, autoflush=False)


class Base(DeclarativeBase):
    """Base class for all database tables."""


def get_db():
    """Give one database session per request and close it afterwards."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()