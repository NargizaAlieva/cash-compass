def create_account(client, headers, **data):
    payload = {"name": "Kaspi Gold", "type": "card", "balance": 50000} | data
    return client.post("/accounts", headers=headers, json=payload)


def test_accounts_need_token(client):
    assert client.get("/accounts").status_code == 401


def test_new_user_has_no_accounts(client, auth_headers):
    response = client.get("/accounts", headers=auth_headers)
    assert response.status_code == 200
    assert response.json() == {"accounts": [], "total_balance": 0}


def test_create_account(client, auth_headers):
    response = create_account(client, auth_headers)
    assert response.status_code == 201
    body = response.json()
    assert body["name"] == "Kaspi Gold"
    assert body["type"] == "card"
    assert body["currency"] == "KGS"
    assert body["balance"] == 50000


def test_total_balance_sums_all_accounts(client, auth_headers):
    create_account(client, auth_headers, name="Cash", type="cash", balance=12000)
    create_account(client, auth_headers, name="Kaspi Gold", balance=50000)
    body = client.get("/accounts", headers=auth_headers).json()
    assert len(body["accounts"]) == 2
    assert body["total_balance"] == 62000


def test_create_account_with_wrong_type_fails(client, auth_headers):
    response = create_account(client, auth_headers, type="crypto")
    assert response.status_code == 422


def test_update_account(client, auth_headers):
    account_id = create_account(client, auth_headers).json()["id"]
    response = client.put(
        f"/accounts/{account_id}", headers=auth_headers, json={"name": "Halyk"}
    )
    assert response.status_code == 200
    assert response.json()["name"] == "Halyk"
    # balance is not changed by update
    assert response.json()["balance"] == 50000


def test_delete_account(client, auth_headers):
    account_id = create_account(client, auth_headers).json()["id"]
    response = client.delete(f"/accounts/{account_id}", headers=auth_headers)
    assert response.status_code == 204
    assert client.get("/accounts", headers=auth_headers).json()["accounts"] == []


def test_cannot_touch_other_users_account(client, auth_headers, other_auth_headers):
    account_id = create_account(client, auth_headers).json()["id"]

    # Another user does not see it and cannot change or delete it
    assert client.get("/accounts", headers=other_auth_headers).json()["accounts"] == []
    assert (
        client.put(
            f"/accounts/{account_id}", headers=other_auth_headers, json={"name": "Mine"}
        ).status_code
        == 404
    )
    assert (
        client.delete(f"/accounts/{account_id}", headers=other_auth_headers).status_code
        == 404
    )