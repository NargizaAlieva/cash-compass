import pytest

from app.services.months import month_range


@pytest.fixture
def ids(client, auth_headers):
    """One account and a few default categories."""
    account = client.post(
        "/accounts",
        headers=auth_headers,
        json={"name": "Card", "type": "card", "balance": 100000},
    ).json()
    categories = {c["name"]: c["id"] for c in client.get("/categories", headers=auth_headers).json()}
    return {
        "account": account["id"],
        "food": categories["Food"],
        "transport": categories["Transport"],
        "stipend": categories["Stipend"],
    }


def spend(client, headers, ids, category, amount, day):
    response = client.post(
        "/transactions",
        headers=headers,
        json={"kind": "expense", "amount": amount, "account_id": ids["account"],
              "category_id": ids[category], "date": day},
    )
    assert response.status_code == 201


def set_limit(client, headers, category_id, amount):
    return client.put(f"/budgets/{category_id}", headers=headers, json={"limit_amount": amount})


def overview(client, headers, month="2026-11"):
    return client.get(f"/budgets?month={month}", headers=headers).json()


def test_month_range_handles_december():
    assert [str(d) for d in month_range("2026-11")] == ["2026-11-01", "2026-12-01"]
    assert [str(d) for d in month_range("2026-12")] == ["2026-12-01", "2027-01-01"]


def test_no_limits_at_start(client, auth_headers):
    body = client.get("/budgets", headers=auth_headers).json()
    assert body["items"] == []
    assert body["total_limit"] == 0


def test_spent_counts_only_this_month_and_category(client, auth_headers, ids):
    set_limit(client, auth_headers, ids["food"], 40000)
    spend(client, auth_headers, ids, "food", 10000, "2026-11-03")
    spend(client, auth_headers, ids, "food", 6000, "2026-11-20")
    spend(client, auth_headers, ids, "food", 99999, "2026-10-31")  # other month
    spend(client, auth_headers, ids, "transport", 5000, "2026-11-05")  # other category

    item = overview(client, auth_headers)["items"][0]
    assert item["spent"] == 16000
    assert item["remaining"] == 24000
    assert item["percent"] == 40.0
    assert item["level"] == "ok"


@pytest.mark.parametrize(
    ("spent", "level"),
    [(7999, "ok"), (8000, "warning"), (9999, "warning"), (10000, "over"), (12500, "over")],
)
def test_levels(client, auth_headers, ids, spent, level):
    set_limit(client, auth_headers, ids["food"], 10000)
    spend(client, auth_headers, ids, "food", spent, "2026-11-10")
    assert overview(client, auth_headers)["items"][0]["level"] == level


def test_over_limit_has_negative_remaining(client, auth_headers, ids):
    set_limit(client, auth_headers, ids["food"], 10000)
    spend(client, auth_headers, ids, "food", 12500, "2026-11-10")
    item = overview(client, auth_headers)["items"][0]
    assert item["remaining"] == -2500
    assert item["percent"] == 125.0


def test_most_used_limit_comes_first(client, auth_headers, ids):
    set_limit(client, auth_headers, ids["food"], 40000)
    set_limit(client, auth_headers, ids["transport"], 10000)
    spend(client, auth_headers, ids, "food", 4000, "2026-11-10")  # 10%
    spend(client, auth_headers, ids, "transport", 9000, "2026-11-10")  # 90%

    body = overview(client, auth_headers)
    assert [i["category_id"] for i in body["items"]] == [ids["transport"], ids["food"]]
    assert body["total_limit"] == 50000
    assert body["total_spent"] == 13000


def test_set_limit_twice_updates_it(client, auth_headers, ids):
    set_limit(client, auth_headers, ids["food"], 40000)
    response = set_limit(client, auth_headers, ids["food"], 30000)
    assert response.status_code == 200
    items = response.json()["items"]
    assert len(items) == 1
    assert items[0]["limit_amount"] == 30000


def test_limit_only_for_expense_categories(client, auth_headers, ids):
    assert set_limit(client, auth_headers, ids["stipend"], 1000).status_code == 422


@pytest.mark.parametrize("amount", [0, -100])
def test_limit_must_be_positive(client, auth_headers, ids, amount):
    assert set_limit(client, auth_headers, ids["food"], amount).status_code == 422


def test_bad_month_format(client, auth_headers):
    assert client.get("/budgets?month=2026-13", headers=auth_headers).status_code == 422
    assert client.get("/budgets?month=11-2026", headers=auth_headers).status_code == 422


def test_delete_limit(client, auth_headers, ids):
    set_limit(client, auth_headers, ids["food"], 40000)
    assert client.delete(f"/budgets/{ids['food']}", headers=auth_headers).status_code == 204
    assert overview(client, auth_headers)["items"] == []
    assert client.delete(f"/budgets/{ids['food']}", headers=auth_headers).status_code == 404


def test_deleting_category_removes_its_limit(client, auth_headers, ids):
    set_limit(client, auth_headers, ids["transport"], 10000)
    assert client.delete(f"/categories/{ids['transport']}", headers=auth_headers).status_code == 204
    assert overview(client, auth_headers)["items"] == []


def test_cannot_set_limit_on_other_users_category(client, auth_headers, other_auth_headers, ids):
    assert set_limit(client, other_auth_headers, ids["food"], 1000).status_code == 404
    assert overview(client, other_auth_headers)["items"] == []