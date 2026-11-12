from datetime import date

import pytest

from app.core.database import get_db
from app.main import app
from app.services.goals import add_months, average_monthly_saving


def test_add_months():
    assert add_months(date(2026, 11, 13), 1) == date(2026, 12, 1)
    assert add_months(date(2026, 11, 13), 3) == date(2027, 2, 1)


@pytest.fixture
def history(client, auth_headers):
    """Saves 20 000 in September and 40 000 in October -> 30 000 a month."""
    card = client.post("/accounts", headers=auth_headers,
                       json={"name": "Card", "type": "card", "balance": 0}).json()["id"]
    cats = {c["name"]: c["id"] for c in client.get("/categories", headers=auth_headers).json()}

    def add(kind, amount, day, category):
        client.post("/transactions", headers=auth_headers, json={
            "kind": kind, "amount": amount, "account_id": card,
            "category_id": cats[category], "date": day})

    add("income", 50000, "2026-09-05", "Salary")
    add("expense", 30000, "2026-09-10", "Food")
    add("income", 50000, "2026-10-05", "Salary")
    add("expense", 10000, "2026-10-10", "Food")
    return client.get("/auth/me", headers=auth_headers).json()["id"]


def test_average_saving_skips_empty_months(history):
    db = next(app.dependency_overrides[get_db]())
    # August has no data, so only September and October count
    assert average_monthly_saving(db, history, date(2026, 11, 13)) == 30000


def test_create_goal_without_history_has_no_forecast(client, auth_headers):
    body = client.post("/goals", headers=auth_headers,
                       json={"name": "Laptop", "target_amount": 400000}).json()
    assert body["percent"] == 0
    assert body["months_left"] is None and body["forecast_date"] is None


def test_goal_forecast_and_progress(client, auth_headers):
    goal = client.post("/goals", headers=auth_headers,
                       json={"name": "Laptop", "target_amount": 400000, "saved_amount": 100000}).json()
    assert goal["percent"] == 25.0

    db = next(app.dependency_overrides[get_db]())
    from app.models.goal import Goal
    from app.services.goals import goal_out
    result = goal_out(db.get(Goal, goal["id"]), 30000, date(2026, 11, 13))
    assert result.months_left == 10  # 300 000 left / 30 000 a month
    assert result.forecast_date == date(2027, 9, 1)


def test_achieved_goal(client, auth_headers):
    body = client.post("/goals", headers=auth_headers,
                       json={"name": "Phone", "target_amount": 1000, "saved_amount": 1500}).json()
    assert body["achieved"] is True and body["percent"] == 100 and body["months_left"] == 0


def test_list_update_delete(client, auth_headers, history):
    goal = client.post("/goals", headers=auth_headers,
                       json={"name": "Trip", "target_amount": 90000}).json()
    overview = client.get("/goals", headers=auth_headers).json()
    assert len(overview["goals"]) == 1
    assert overview["monthly_saving"] >= 0

    updated = client.put(f"/goals/{goal['id']}", headers=auth_headers,
                         json={"saved_amount": 45000}).json()
    assert updated["percent"] == 50.0
    assert client.delete(f"/goals/{goal['id']}", headers=auth_headers).status_code == 204
    assert client.get("/goals", headers=auth_headers).json()["goals"] == []


@pytest.mark.parametrize("body", [{"name": "", "target_amount": 100},
                                  {"name": "X", "target_amount": 0},
                                  {"name": "X", "target_amount": 100, "saved_amount": -1}])
def test_invalid_goal(client, auth_headers, body):
    assert client.post("/goals", headers=auth_headers, json=body).status_code == 422


def test_other_user_cannot_touch_goal(client, auth_headers, other_auth_headers):
    goal = client.post("/goals", headers=auth_headers,
                       json={"name": "Laptop", "target_amount": 400000}).json()
    assert client.get("/goals", headers=other_auth_headers).json()["goals"] == []
    assert client.delete(f"/goals/{goal['id']}", headers=other_auth_headers).status_code == 404
