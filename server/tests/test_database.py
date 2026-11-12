import pytest

from app.core.database import normalize_database_url


@pytest.mark.parametrize(
    ("given", "expected"),
    [
        ("postgresql://u:p@host/db", "postgresql+psycopg://u:p@host/db"),
        ("postgres://u:p@host/db", "postgresql+psycopg://u:p@host/db"),
        ("postgresql+psycopg://u:p@host/db", "postgresql+psycopg://u:p@host/db"),
        ("sqlite:///./cash_compass.db", "sqlite:///./cash_compass.db"),
    ],
)
def test_normalize_database_url(given, expected):
    assert normalize_database_url(given) == expected