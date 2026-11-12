from datetime import date

import pytest

from app.core.database import get_db
from app.main import app
from app.models.user import User
from app.services.stipend import next_stipend_date, stipend_allowance


@pytest.mark.parametrize(
    ("stipend_day", "today", "expected"),
    [
        (25, date(2026, 11, 12), date(2026, 11, 25)),  # later this month
        (25, date(2026, 11, 25), date(2026, 12, 25)),  # today -> next month
        (5, date(2026, 11, 12), date(2026, 12, 5)),  # already passed
        (5, date(2026, 12, 20), date(2027, 1, 5)),  # over the new year
        (31, date(2026, 11, 12), date(2026, 11, 30)),  # November has 30 days
        (31, date(2027, 2, 1), date(2027, 2, 28)),  # February
    ],
)
def test_next_stipend_date(stipend_day, today, expected):
    assert next_stipend_date(stipend_day, today) == expected


@pytest.fixture
def user_with_money(client, auth_headers):
    """45 000 on two accounts, stipend on the 25th."""
    client.put("/auth/me", headers=auth_headers, json={"stipend_day": 25})
    card = client.post(
        "/accounts", headers=auth_headers,
        json={"name": "Card", "type": "card", "balance": 30000},
    ).json()["id"]
    client.post(
        "/accounts", headers=auth_headers,
        json={"name": "Cash", "type": "cash", "balance": 15000},
    )
    food = next(
        c["id"] for c in client.get("/categories", headers=auth_headers).json()
        if c["name"] == "Food"
    )

    def spend(amount, day):
        client.post(
            "/transactions", headers=auth_headers,
            json={"kind": "expense", "amount": amount, "account_id": card,
                  "category_id": food, "date": day},
        )

    db = next(app.dependency_overrides[get_db]())
    user_id = client.get("/auth/me", headers=auth_headers).json()["id"]

    def allowance(today):
        return stipend_allowance(db, db.get(User, user_id), today=today)

    return spend, allowance


def test_not_configured(client, auth_headers):
    body = client.get("/stipend/allowance", headers=auth_headers).json()
    assert body["configured"] is False
    assert body["daily_allowance"] is None


def test_endpoint_works_when_configured(client, auth_headers):
    client.put("/auth/me", headers=auth_headers, json={"stipend_day": 25})
    body = client.get("/stipend/allowance", headers=auth_headers).json()
    assert body["configured"] is True
    assert body["stipend_day"] == 25
    assert body["days_left"] >= 1


def test_daily_allowance_splits_money_between_days(user_with_money):
    _, allowance = user_with_money
    # 12 Nov -> 25 Nov: 13 days (12th..24th), 45 000 / 13
    result = allowance(date(2026, 11, 12))
    assert result.days_left == 13
    assert result.balance == 45000
    assert result.daily_allowance == round(45000 / 13, 2)
    assert result.spent_today == 0
    assert result.left_today == result.daily_allowance


def test_spending_today_lowers_left_today_but_not_the_daily_number(user_with_money):
    spend, allowance = user_with_money
    spend(1000, "2026-11-12")
    result = allowance(date(2026, 11, 12))
    # The daily number is counted from this morning's money (45 000),
    # so it does not jump after every purchase
    assert result.daily_allowance == round(45000 / 13, 2)
    assert result.spent_today == 1000
    assert result.left_today == round(45000 / 13 - 1000, 2)


def test_overspending_gives_negative_left_today(user_with_money):
    spend, allowance = user_with_money
    spend(10000, "2026-11-12")
    assert allowance(date(2026, 11, 12)).left_today < 0


def test_yesterdays_spending_lowers_todays_allowance(user_with_money):
    spend, allowance = user_with_money
    spend(6000, "2026-11-11")  # balance is now 39 000
    result = allowance(date(2026, 11, 12))
    assert result.spent_today == 0
    assert result.daily_allowance == 3000  # 39 000 / 13 days


def test_no_money_means_zero_allowance(client, auth_headers):
    client.put("/auth/me", headers=auth_headers, json={"stipend_day": 25})
    client.post(
        "/accounts", headers=auth_headers,
        json={"name": "Card", "type": "card", "balance": -5000},
    )
    body = client.get("/stipend/allowance", headers=auth_headers).json()
    assert body["daily_allowance"] == 0


def test_needs_token(client):
    assert client.get("/stipend/allowance").status_code == 401