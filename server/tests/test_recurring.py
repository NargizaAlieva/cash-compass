from datetime import date

import pytest

from app.core.database import get_db
from app.main import app
from app.models.recurring_payment import RecurringPayment
from app.models.user import User
from app.services.months import next_monthly_date
from app.services.recurring import process_due_payments
from app.services.stipend import stipend_allowance


@pytest.mark.parametrize(
    ("day", "on_or_after", "expected"),
    [
        (25, date(2026, 11, 12), date(2026, 11, 25)),
        (12, date(2026, 11, 12), date(2026, 11, 12)),  # today counts
        (3, date(2026, 11, 12), date(2026, 12, 3)),
        (3, date(2026, 12, 20), date(2027, 1, 3)),
        (31, date(2026, 11, 1), date(2026, 11, 30)),  # short month
        (31, date(2027, 2, 1), date(2027, 2, 28)),
    ],
)
def test_next_monthly_date(day, on_or_after, expected):
    assert next_monthly_date(day, on_or_after) == expected


@pytest.fixture
def setup(client, auth_headers):
    card = client.post(
        "/accounts", headers=auth_headers,
        json={"name": "Card", "type": "card", "balance": 100000},
    ).json()["id"]
    cats = {c["name"]: c["id"] for c in client.get("/categories", headers=auth_headers).json()}
    db = next(app.dependency_overrides[get_db]())
    user_id = client.get("/auth/me", headers=auth_headers).json()["id"]
    return {"card": card, "cats": cats, "db": db, "user_id": user_id}


def add_payment(client, headers, setup, **data):
    body = {"name": "Spotify", "amount": 1990, "account_id": setup["card"],
            "category_id": setup["cats"]["Subscriptions"], "day_of_month": 3} | data
    return client.post("/recurring", headers=headers, json=body)


def set_next_date(setup, payment_id, next_date):
    """Move the next charge date, as if time passed."""
    db = setup["db"]
    db.get(RecurringPayment, payment_id).next_date = next_date
    db.commit()


def test_create_and_totals(client, auth_headers, setup):
    response = add_payment(client, auth_headers, setup)
    assert response.status_code == 201
    assert response.json()["next_date"] >= date.today().isoformat()
    add_payment(client, auth_headers, setup, name="Dormitory", amount=15000,
                category_id=setup["cats"]["Housing"], day_of_month=1)

    body = client.get("/recurring", headers=auth_headers).json()
    assert len(body["items"]) == 2
    assert body["monthly_total"] == 16990
    assert body["yearly_total"] == 16990 * 12


def test_due_payment_becomes_an_expense_once(client, auth_headers, setup):
    payment = add_payment(client, auth_headers, setup).json()
    set_next_date(setup, payment["id"], date(2026, 11, 3))

    created = process_due_payments(setup["db"], setup["user_id"], today=date(2026, 11, 12))
    assert created == 1
    # Running again on the same day creates nothing new
    assert process_due_payments(setup["db"], setup["user_id"], today=date(2026, 11, 12)) == 0

    transactions = client.get("/transactions", headers=auth_headers).json()
    charged = [t for t in transactions if t["recurring_payment_id"] == payment["id"]]
    assert [(t["date"], t["amount"], t["note"]) for t in charged] == [("2026-11-03", 1990, "Spotify")]
    assert client.get("/accounts", headers=auth_headers).json()["total_balance"] == 100000 - 1990


def test_missed_months_are_all_charged(client, auth_headers, setup):
    payment = add_payment(client, auth_headers, setup, day_of_month=31).json()
    set_next_date(setup, payment["id"], date(2026, 9, 30))

    created = process_due_payments(setup["db"], setup["user_id"], today=date(2026, 11, 30))
    assert created == 3
    dates = sorted(
        t["date"] for t in client.get("/transactions", headers=auth_headers).json()
        if t["recurring_payment_id"] == payment["id"]
    )
    assert dates == ["2026-09-30", "2026-10-31", "2026-11-30"]


def test_paused_payment_is_not_charged(client, auth_headers, setup):
    payment = add_payment(client, auth_headers, setup).json()
    client.put(f"/recurring/{payment['id']}", headers=auth_headers, json={"is_active": False})
    set_next_date(setup, payment["id"], date(2026, 11, 3))
    assert process_due_payments(setup["db"], setup["user_id"], today=date(2026, 11, 12)) == 0
    assert client.get("/recurring", headers=auth_headers).json()["monthly_total"] == 0


def test_resuming_does_not_charge_the_paused_months(client, auth_headers, setup):
    payment = add_payment(client, auth_headers, setup).json()
    client.put(f"/recurring/{payment['id']}", headers=auth_headers, json={"is_active": False})
    set_next_date(setup, payment["id"], date(2025, 1, 3))  # paused long ago
    body = client.put(
        f"/recurring/{payment['id']}", headers=auth_headers, json={"is_active": True}
    ).json()
    assert body["next_date"] >= date.today().isoformat()


def test_delete_keeps_created_expenses(client, auth_headers, setup):
    payment = add_payment(client, auth_headers, setup).json()
    set_next_date(setup, payment["id"], date(2026, 11, 3))
    process_due_payments(setup["db"], setup["user_id"], today=date(2026, 11, 12))

    assert client.delete(f"/recurring/{payment['id']}", headers=auth_headers).status_code == 204
    transactions = client.get("/transactions", headers=auth_headers).json()
    assert [t["note"] for t in transactions] == ["Spotify"]
    assert transactions[0]["recurring_payment_id"] is None


def test_income_category_is_not_allowed(client, auth_headers, setup):
    response = add_payment(client, auth_headers, setup, category_id=setup["cats"]["Stipend"])
    assert response.status_code == 422


def test_used_account_and_category_cannot_be_deleted(client, auth_headers, setup):
    add_payment(client, auth_headers, setup)
    assert client.delete(f"/accounts/{setup['card']}", headers=auth_headers).status_code == 409
    subscriptions = setup["cats"]["Subscriptions"]
    assert client.delete(f"/categories/{subscriptions}", headers=auth_headers).status_code == 409


def test_other_user_cannot_touch_payment(client, auth_headers, other_auth_headers, setup):
    payment = add_payment(client, auth_headers, setup).json()
    assert client.get("/recurring", headers=other_auth_headers).json()["items"] == []
    assert client.delete(f"/recurring/{payment['id']}", headers=other_auth_headers).status_code == 404


def test_stipend_budget_puts_money_aside_for_payments(client, auth_headers, setup):
    client.put("/auth/me", headers=auth_headers, json={"stipend_day": 25})
    payment = add_payment(client, auth_headers, setup, name="Dormitory", amount=13000,
                          category_id=setup["cats"]["Housing"], day_of_month=20).json()
    set_next_date(setup, payment["id"], date(2026, 11, 20))

    db = setup["db"]
    result = stipend_allowance(db, db.get(User, setup["user_id"]), today=date(2026, 11, 12))
    # 100 000 on the card, 13 000 put aside for the dormitory, 13 days left
    assert result.reserved_for_payments == 13000
    assert result.daily_allowance == round((100000 - 13000) / 13, 2)
