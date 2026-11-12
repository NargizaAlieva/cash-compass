from datetime import date

import pytest

from app.core.database import get_db
from app.main import app
from app.services.analytics import month_analytics, previous_month


@pytest.fixture
def data(client, auth_headers):
    """October and November with expenses, income, a transfer and impulses."""
    card = client.post(
        "/accounts", headers=auth_headers,
        json={"name": "Card", "type": "card", "balance": 500000},
    ).json()["id"]
    cash = client.post(
        "/accounts", headers=auth_headers,
        json={"name": "Cash", "type": "cash", "balance": 0},
    ).json()["id"]
    cats = {c["name"]: c["id"] for c in client.get("/categories", headers=auth_headers).json()}

    def add(kind, amount, day, category=None, impulsive=False, to=None):
        body = {"kind": kind, "amount": amount, "account_id": card, "date": day,
                "is_impulsive": impulsive}
        if category:
            body["category_id"] = cats[category]
        if to:
            body["to_account_id"] = to
        assert client.post("/transactions", headers=auth_headers, json=body).status_code == 201

    # October
    add("expense", 20000, "2026-10-05", "Food")
    add("expense", 10000, "2026-10-12", "Transport")
    # November
    add("income", 45000, "2026-11-01", "Stipend")
    add("expense", 15000, "2026-11-02", "Food")
    add("expense", 5000, "2026-11-02", "Food", impulsive=True)
    add("expense", 10000, "2026-11-10", "Entertainment", impulsive=True)
    add("expense", 10000, "2026-11-15", "Transport")
    add("transfer", 7000, "2026-11-15", to=cash)  # must NOT count as expense
    return cats


def get(client, headers, month="2026-11"):
    response = client.get(f"/analytics/month?month={month}", headers=headers)
    assert response.status_code == 200
    return response.json()


def test_previous_month():
    assert previous_month("2026-11") == "2026-10"
    assert previous_month("2026-01") == "2025-12"


def test_totals_ignore_transfers(client, auth_headers, data):
    body = get(client, auth_headers)
    assert body["income"] == 45000
    assert body["expense"] == 40000
    assert body["net"] == 5000


def test_by_category_sorted_with_percent(client, auth_headers, data):
    by_category = get(client, auth_headers)["by_category"]
    assert by_category[0] == {"category_id": data["Food"], "amount": 20000, "percent": 50.0}
    assert [c["amount"] for c in by_category] == [20000, 10000, 10000]
    assert sum(c["percent"] for c in by_category) == 100


def test_daily_has_every_day_of_month(client, auth_headers, data):
    daily = get(client, auth_headers)["daily"]
    assert len(daily) == 30  # November
    assert daily[0] == {"date": "2026-11-01", "expense": 0}  # only income that day
    assert daily[1] == {"date": "2026-11-02", "expense": 20000}
    assert daily[14] == {"date": "2026-11-15", "expense": 10000}  # transfer not counted


def test_past_month_average_uses_all_days_and_has_no_forecast(client, auth_headers, data):
    body = get(client, auth_headers, month="2026-10")
    assert body["avg_daily_expense"] == round(30000 / 31, 2)
    assert body["forecast_expense"] is None


def test_compare_with_previous_month(client, auth_headers, data):
    body = get(client, auth_headers)
    assert body["previous_expense"] == 30000
    assert body["expense_change_percent"] == 33.3  # 30 000 -> 40 000

    changes = {c["category_id"]: c for c in body["category_changes"]}
    assert changes[data["Entertainment"]]["change"] == 10000  # new this month
    assert changes[data["Food"]]["change"] == 0
    assert changes[data["Transport"]]["change"] == 0


def test_no_previous_expenses_means_no_change_percent(client, auth_headers, data):
    assert get(client, auth_headers, month="2026-10")["expense_change_percent"] is None


def test_impulse_stats(client, auth_headers, data):
    impulse = get(client, auth_headers)["impulse"]
    assert impulse == {"amount": 15000, "count": 2, "percent": 37.5}


def test_empty_month(client, auth_headers):
    body = get(client, auth_headers, month="2025-01")
    assert body["expense"] == 0
    assert body["by_category"] == []
    assert body["impulse"] == {"amount": 0, "count": 0, "percent": 0}
    assert len(body["daily"]) == 31


def test_current_month_average_and_forecast(client, auth_headers, data):
    # Pretend today is 10 November: 10 days passed, 30 days in the month
    db = next(app.dependency_overrides[get_db]())
    user_id = client.get("/auth/me", headers=auth_headers).json()["id"]
    result = month_analytics(db, user_id, "2026-11", today=date(2026, 11, 10))
    # 30 000 spent by 10 Nov (the 15 Nov expense is "in the future") / 10 days
    assert result.avg_daily_expense == 3000
    assert result.forecast_expense == 90000  # 3 000 a day * 30 days


def test_analytics_needs_token_and_valid_month(client, auth_headers):
    assert client.get("/analytics/month").status_code == 401
    assert client.get("/analytics/month?month=2026-13", headers=auth_headers).status_code == 422


def test_other_user_sees_nothing(client, other_auth_headers, data):
    body = get(client, other_auth_headers)
    assert body["expense"] == 0
    assert body["by_category"] == []