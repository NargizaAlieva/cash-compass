import pytest

from app.services.anomalies import unusual_categories


@pytest.fixture
def add(client, auth_headers):
    card = client.post("/accounts", headers=auth_headers,
                       json={"name": "Card", "type": "card", "balance": 1000000}).json()["id"]
    cats = {c["name"]: c["id"] for c in client.get("/categories", headers=auth_headers).json()}

    def add(category, amount, day):
        return client.post("/transactions", headers=auth_headers, json={
            "kind": "expense", "amount": amount, "account_id": card,
            "category_id": cats[category], "date": day}).json()

    add.cats = cats
    return add


def anomalies(client, headers, month="2026-11"):
    return client.get(f"/analytics/month?month={month}", headers=headers).json()["anomalies"]


def test_taxi_much_bigger_than_usual_is_found(client, auth_headers, add):
    for day, amount in [("2026-09-03", 1500), ("2026-09-20", 1700), ("2026-10-02", 1600),
                        ("2026-10-15", 1400), ("2026-10-28", 1500)]:
        add("Transport", amount, day)
    big = add("Transport", 6500, "2026-11-05")
    add("Transport", 1800, "2026-11-06")  # normal, must not be found

    found = [a for a in anomalies(client, auth_headers) if a["kind"] == "purchase"]
    assert [a["transaction_id"] for a in found] == [big["id"]]
    assert found[0]["usual"] == 1500
    assert found[0]["times"] == 4.3


def test_not_enough_history_means_no_purchase_alarm(client, auth_headers, add):
    add("Transport", 1500, "2026-10-03")
    add("Transport", 9000, "2026-11-05")
    kinds = [a["kind"] for a in anomalies(client, auth_headers)]
    # One purchase in the history is too little to judge a single purchase,
    # but the whole month (9 000 vs 1 500) is still a category spike
    assert kinds == ["category"]


def test_category_month_much_bigger_than_usual(client, auth_headers, add):
    for month in ["2026-08", "2026-09", "2026-10"]:
        add("Entertainment", 5000, f"{month}-10")
    add("Entertainment", 16000, "2026-11-10")

    found = [a for a in anomalies(client, auth_headers) if a["kind"] == "category"]
    assert found[0]["category_id"] == add.cats["Entertainment"]
    assert found[0]["usual"] == 5000
    assert found[0]["times"] == 3.2


def test_small_category_difference_is_ignored():
    # 1 000 -> 2 000 is twice as much, but only 1 000 tenge: not worth an alarm
    assert unusual_categories({1: 2000}, [{1: 1000}]) == []


def test_new_category_without_history_is_ignored():
    assert unusual_categories({1: 50000}, [{2: 1000}]) == []
