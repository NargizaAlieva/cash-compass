import pytest


@pytest.fixture
def setup(client, auth_headers):
    """Two accounts and the ids of two default categories."""
    cash = client.post(
        "/accounts",
        headers=auth_headers,
        json={"name": "Cash", "type": "cash", "balance": 10000},
    ).json()
    card = client.post(
        "/accounts",
        headers=auth_headers,
        json={"name": "Kaspi Gold", "type": "card", "balance": 50000},
    ).json()
    categories = client.get("/categories", headers=auth_headers).json()
    food = next(c for c in categories if c["name"] == "Food")
    stipend = next(c for c in categories if c["name"] == "Stipend")
    return {"cash": cash["id"], "card": card["id"], "food": food["id"], "stipend": stipend["id"]}


def balances(client, headers):
    """Return {account name: balance} and the total."""
    body = client.get("/accounts", headers=headers).json()
    return {a["name"]: a["balance"] for a in body["accounts"]}, body["total_balance"]


def add(client, headers, **data):
    return client.post("/transactions", headers=headers, json=data)


def test_expense_lowers_balance(client, auth_headers, setup):
    response = add(
        client, auth_headers,
        kind="expense", amount=2500, account_id=setup["card"],
        category_id=setup["food"], date="2026-11-10", note="Lunch", is_impulsive=True,
    )
    assert response.status_code == 201
    assert response.json()["is_impulsive"] is True
    by_name, total = balances(client, auth_headers)
    assert by_name["Kaspi Gold"] == 47500
    assert total == 57500


def test_income_raises_balance(client, auth_headers, setup):
    add(client, auth_headers, kind="income", amount=45000,
        account_id=setup["card"], category_id=setup["stipend"])
    by_name, _ = balances(client, auth_headers)
    assert by_name["Kaspi Gold"] == 95000


def test_transfer_moves_money_and_keeps_total(client, auth_headers, setup):
    response = add(client, auth_headers, kind="transfer", amount=5000,
                   account_id=setup["card"], to_account_id=setup["cash"])
    assert response.status_code == 201
    by_name, total = balances(client, auth_headers)
    assert by_name == {"Cash": 15000, "Kaspi Gold": 45000}
    assert total == 60000  # a transfer is not spending


def test_income_cannot_be_impulsive(client, auth_headers, setup):
    response = add(client, auth_headers, kind="income", amount=100,
                   account_id=setup["cash"], category_id=setup["stipend"], is_impulsive=True)
    assert response.json()["is_impulsive"] is False


def test_update_recalculates_balance(client, auth_headers, setup):
    tx = add(client, auth_headers, kind="expense", amount=1000,
             account_id=setup["cash"], category_id=setup["food"]).json()
    response = client.put(
        f"/transactions/{tx['id']}",
        headers=auth_headers,
        json={"kind": "expense", "amount": 3000, "account_id": setup["card"],
              "category_id": setup["food"]},
    )
    assert response.status_code == 200
    by_name, _ = balances(client, auth_headers)
    # old expense returned to Cash, new one taken from the card
    assert by_name == {"Cash": 10000, "Kaspi Gold": 47000}


def test_delete_restores_balance(client, auth_headers, setup):
    tx = add(client, auth_headers, kind="transfer", amount=5000,
             account_id=setup["card"], to_account_id=setup["cash"]).json()
    assert client.delete(f"/transactions/{tx['id']}", headers=auth_headers).status_code == 204
    by_name, _ = balances(client, auth_headers)
    assert by_name == {"Cash": 10000, "Kaspi Gold": 50000}


@pytest.mark.parametrize(
    "data",
    [
        {"kind": "expense", "amount": 0},  # amount must be > 0
        {"kind": "expense", "amount": -5},
        {"kind": "expense", "amount": 100, "category_id": None},  # no category
        {"kind": "transfer", "amount": 100, "category_id": None},  # no to_account
    ],
)
def test_invalid_transactions_fail(client, auth_headers, setup, data):
    body = {"account_id": setup["cash"], "category_id": setup["food"]} | data
    assert add(client, auth_headers, **body).status_code == 422


def test_transfer_to_same_account_fails(client, auth_headers, setup):
    response = add(client, auth_headers, kind="transfer", amount=100,
                   account_id=setup["cash"], to_account_id=setup["cash"])
    assert response.status_code == 422


def test_category_kind_must_match(client, auth_headers, setup):
    # "Stipend" is an income category, it cannot be used for an expense
    response = add(client, auth_headers, kind="expense", amount=100,
                   account_id=setup["cash"], category_id=setup["stipend"])
    assert response.status_code == 422


def test_list_is_newest_first_and_filters_work(client, auth_headers, setup):
    add(client, auth_headers, kind="expense", amount=100, account_id=setup["cash"],
        category_id=setup["food"], date="2026-11-01", note="coffee")
    add(client, auth_headers, kind="expense", amount=200, account_id=setup["card"],
        category_id=setup["food"], date="2026-11-05", note="pizza")
    add(client, auth_headers, kind="income", amount=300, account_id=setup["card"],
        category_id=setup["stipend"], date="2026-10-25")

    all_items = client.get("/transactions", headers=auth_headers).json()
    assert [t["amount"] for t in all_items] == [200, 100, 300]

    november = client.get(
        "/transactions?date_from=2026-11-01&date_to=2026-11-30", headers=auth_headers
    ).json()
    assert len(november) == 2

    expenses = client.get("/transactions?kind=expense", headers=auth_headers).json()
    assert all(t["kind"] == "expense" for t in expenses)

    search = client.get("/transactions?q=PIZ", headers=auth_headers).json()
    assert [t["note"] for t in search] == ["pizza"]

    cash_only = client.get(f"/transactions?account_id={setup['cash']}", headers=auth_headers).json()
    assert [t["amount"] for t in cash_only] == [100]


def test_cannot_use_other_users_account(client, auth_headers, other_auth_headers, setup):
    other_categories = client.get("/categories", headers=other_auth_headers).json()
    response = add(client, other_auth_headers, kind="expense", amount=100,
                   account_id=setup["cash"], category_id=other_categories[0]["id"])
    assert response.status_code == 404


def test_cannot_see_other_users_transactions(client, auth_headers, other_auth_headers, setup):
    tx = add(client, auth_headers, kind="expense", amount=100,
             account_id=setup["cash"], category_id=setup["food"]).json()
    assert client.get("/transactions", headers=other_auth_headers).json() == []
    assert client.get(f"/transactions/{tx['id']}", headers=other_auth_headers).status_code == 404
    assert client.delete(f"/transactions/{tx['id']}", headers=other_auth_headers).status_code == 404


def test_account_with_transactions_cannot_be_deleted(client, auth_headers, setup):
    add(client, auth_headers, kind="transfer", amount=100,
        account_id=setup["card"], to_account_id=setup["cash"])
    # Both sides of a transfer are protected
    assert client.delete(f"/accounts/{setup['cash']}", headers=auth_headers).status_code == 409
    assert client.delete(f"/accounts/{setup['card']}", headers=auth_headers).status_code == 409


def test_used_category_cannot_be_deleted(client, auth_headers, setup):
    add(client, auth_headers, kind="expense", amount=100,
        account_id=setup["cash"], category_id=setup["food"])
    assert client.delete(f"/categories/{setup['food']}", headers=auth_headers).status_code == 409