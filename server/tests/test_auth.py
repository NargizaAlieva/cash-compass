def test_register_returns_token(client):
    response = client.post(
        "/auth/register",
        json={"email": "new@example.com", "password": "secret123", "name": "New"},
    )
    assert response.status_code == 201
    assert "access_token" in response.json()


def test_register_duplicate_email_fails(client, auth_headers):
    response = client.post(
        "/auth/register",
        json={"email": "TEST@example.com", "password": "secret123", "name": "Again"},
    )
    assert response.status_code == 409


def test_register_short_password_fails(client):
    response = client.post(
        "/auth/register",
        json={"email": "a@example.com", "password": "123", "name": "A"},
    )
    assert response.status_code == 422


def test_login_success(client, auth_headers):
    response = client.post(
        "/auth/login", json={"email": "test@example.com", "password": "secret123"}
    )
    assert response.status_code == 200
    assert "access_token" in response.json()


def test_login_wrong_password(client, auth_headers):
    response = client.post(
        "/auth/login", json={"email": "test@example.com", "password": "wrong-pass"}
    )
    assert response.status_code == 401


def test_me_without_token(client):
    assert client.get("/auth/me").status_code == 401


def test_me_with_invalid_token(client):
    response = client.get("/auth/me", headers={"Authorization": "Bearer abc"})
    assert response.status_code == 401


def test_me_returns_user(client, auth_headers):
    response = client.get("/auth/me", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["email"] == "test@example.com"


def test_update_stipend_settings(client, auth_headers):
    response = client.put(
        "/auth/me", headers=auth_headers, json={"stipend_day": 25, "stipend_amount": 45000}
    )
    assert response.status_code == 200
    assert response.json()["stipend_day"] == 25


def test_update_invalid_stipend_day(client, auth_headers):
    response = client.put("/auth/me", headers=auth_headers, json={"stipend_day": 40})
    assert response.status_code == 422