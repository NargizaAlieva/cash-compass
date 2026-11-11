import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import Base, get_db
from app.main import app


@pytest.fixture
def client():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSession = sessionmaker(bind=engine, autoflush=False)
    Base.metadata.create_all(bind=engine)

    def override_get_db():
        db = TestingSession()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    yield TestClient(app)
    app.dependency_overrides.clear()


@pytest.fixture
def auth_headers(client):
    """Register a test user and return headers with their token."""
    response = client.post(
        "/auth/register",
        json={"email": "test@example.com", "password": "secret123", "name": "Test"},
    )
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}



@pytest.fixture
def other_auth_headers(client):
    """A second user, to check that users cannot see each other's data."""
    response = client.post(
        "/auth/register",
        json={"email": "other@example.com", "password": "secret123", "name": "Other"},
    )
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}