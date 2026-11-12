"""Fill a demo account with about 3 months of realistic data.

The script talks to the API over HTTP, like the mobile app does,
so it works with the local server and with the server on Render.

Usage (from the server folder):
    .venv\\Scripts\\python.exe scripts\\seed_demo.py
    .venv\\Scripts\\python.exe scripts\\seed_demo.py --url https://cash-compass-api.onrender.com

Only the Python standard library is used, nothing to install.
"""

import argparse
import json
import random
import urllib.error
import urllib.request
from datetime import date, timedelta

DEFAULT_URL = "http://127.0.0.1:8000"
DEFAULT_EMAIL = "demo@cashcompass.app"
DEFAULT_PASSWORD = "demo12345"


class Api:
    """Tiny HTTP client: JSON in, JSON out, token in the header."""

    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip("/")
        self.token: str | None = None

    def call(self, method: str, path: str, body: dict | None = None):
        headers = {"Content-Type": "application/json"}
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        request = urllib.request.Request(
            self.base_url + path,
            method=method,
            data=json.dumps(body).encode() if body is not None else None,
            headers=headers,
        )
        # A sleeping free server on Render may need up to a minute to wake up
        with urllib.request.urlopen(request, timeout=90) as response:
            raw = response.read()
            return json.loads(raw) if raw else None


def log_in_or_register(api: Api, email: str, password: str) -> bool:
    """Returns True if a new account was created."""
    try:
        api.token = api.call("POST", "/auth/register", {
            "email": email, "password": password, "name": "Demo Student",
        })["access_token"]
        return True
    except urllib.error.HTTPError as error:
        if error.code != 409:  # 409 = this email is already registered
            raise
    api.token = api.call("POST", "/auth/login", {
        "email": email, "password": password,
    })["access_token"]
    return False


def month_starts(today: date, count: int) -> list[date]:
    """First days of the last [count] months, oldest first, this month included."""
    starts = [today.replace(day=1)]
    for _ in range(count - 1):
        starts.insert(0, (starts[0] - timedelta(days=1)).replace(day=1))
    return starts


def build_transactions(today: date, accounts: dict, cats: dict) -> list[dict]:
    """A student's life for the last two full months and this month until yesterday.

    Today stays empty, so on the demo you can add a purchase live
    and show how "You can spend today" goes down.
    """
    rng = random.Random(42)  # the same "random" data every time
    items = []

    def expense(day, category, amount, note="", account="Kaspi Gold", impulsive=False):
        items.append({
            "kind": "expense", "amount": amount, "date": day.isoformat(),
            "account_id": accounts[account], "category_id": cats[category],
            "note": note, "is_impulsive": impulsive,
        })

    def income(day, category, amount, note, account="Kaspi Gold"):
        items.append({
            "kind": "income", "amount": amount, "date": day.isoformat(),
            "account_id": accounts[account], "category_id": cats[category], "note": note,
        })

    def transfer(day, amount, from_account, to_account, note):
        items.append({
            "kind": "transfer", "amount": amount, "date": day.isoformat(),
            "account_id": accounts[from_account], "to_account_id": accounts[to_account],
            "note": note,
        })

    first_day = month_starts(today, 3)[0]
    day = first_day
    while day < today:
        weekday = day.weekday()  # 0 = Monday

        # Monthly payments
        if day.day == 1:
            expense(day, "Housing", 15000, "Dormitory")
        if day.day == 3:
            expense(day, "Subscriptions", 1990, "Spotify", account="Halyk")
        if day.day == 12:
            expense(day, "Subscriptions", 1490, "YouTube Premium", account="Halyk")
        if day.day == 10:
            income(day, "Salary", 50000, "Part-time job")
        if day.day == 25:
            income(day, "Stipend", 45000, "Stipend")

        # Cash for the market and small things, every second Saturday
        if weekday == 5 and day.isocalendar().week % 2 == 0:
            transfer(day, 7000, "Kaspi Gold", "Cash", "ATM")

        # Lunch on study days
        if weekday < 5 and rng.random() < 0.6:
            expense(day, "Food", rng.choice([800, 1000, 1200, 1500]),
                    rng.choice(["Lunch", "Canteen", "Burger", "Coffee and bun"]))
        # Sometimes food delivery in the evening - often an impulse
        if rng.random() < 0.07:
            expense(day, "Food", rng.choice([3500, 4200, 5100]), "Food delivery",
                    impulsive=True)

        # Groceries on Sundays, the bazaar with cash on Saturdays
        if weekday == 6:
            expense(day, "Groceries", rng.randrange(3500, 5500, 100), "Magnum")
        if weekday == 5:
            expense(day, "Groceries", rng.randrange(1500, 2500, 100), "Bazaar", account="Cash")

        # Bus most days, a taxi sometimes
        if rng.random() < 0.7:
            expense(day, "Transport", 200, "Bus", account="Cash")
        if rng.random() < 0.1:
            expense(day, "Transport", rng.choice([1200, 1600, 2100]), "Yandex Go")

        # Fun on Fridays
        if weekday == 4 and rng.random() < 0.5:
            expense(day, "Entertainment", rng.choice([2500, 3500, 5000]),
                    rng.choice(["Cinema", "Bowling", "Concert"]),
                    impulsive=rng.random() < 0.4)

        # Clothes once in a while
        if day.day == 18 and rng.random() < 0.5:
            expense(day, "Clothes", rng.choice([9000, 14000, 18000]), "New sneakers",
                    impulsive=True)

        # Study and health
        if day.day == 5:
            expense(day, "Education", 4500, "Books and printing")
        if rng.random() < 0.03:
            expense(day, "Health", rng.choice([1800, 3200]), "Pharmacy")

        day += timedelta(days=1)

    return items


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--url", default=DEFAULT_URL, help=f"server address (default {DEFAULT_URL})")
    parser.add_argument("--email", default=DEFAULT_EMAIL)
    parser.add_argument("--password", default=DEFAULT_PASSWORD)
    args = parser.parse_args()

    api = Api(args.url)
    print(f"Server: {api.base_url}")
    print("Health:", api.call("GET", "/health"))

    created = log_in_or_register(api, args.email, args.password)
    print("Account:", args.email, "(new)" if created else "(already existed)")

    if api.call("GET", "/transactions?limit=1"):
        print("The account already has history: only missing extras are added.")
    else:
        add_history(api)
    add_extras(api)

    total = api.call("GET", "/accounts")["total_balance"]
    print(f"Done. Total balance {total:,.0f} som")
    print(f"Log in with {args.email} / {args.password}")


def add_history(api: Api) -> None:
    """Accounts, stipend, limits and 3 months of transactions for a new account."""
    accounts = {}
    for name, kind, balance in [
        ("Kaspi Gold", "card", 120000),
        ("Halyk", "card", 25000),
        ("Cash", "cash", 5000),
    ]:
        accounts[name] = api.call("POST", "/accounts", {
            "name": name, "type": kind, "balance": balance,
        })["id"]
    cats = {c["name"]: c["id"] for c in api.call("GET", "/categories")}

    api.call("PUT", "/auth/me", {"stipend_day": 25, "stipend_amount": 45000})
    for category, limit in [("Food", 20000), ("Entertainment", 8000), ("Transport", 10000)]:
        api.call("PUT", f"/budgets/{cats[category]}", {"limit_amount": limit})

    transactions = build_transactions(date.today(), accounts, cats)
    for number, transaction in enumerate(transactions, start=1):
        api.call("POST", "/transactions", transaction)
        if number % 25 == 0:
            print(f"  {number}/{len(transactions)} transactions...")


def add_extras(api: Api) -> None:
    """Data for the newer features. Each part is added only if it is missing,
    so the script can be run again on an old demo account."""
    accounts = {a["name"]: a["id"] for a in api.call("GET", "/accounts")["accounts"]}
    cats = {c["name"]: c["id"] for c in api.call("GET", "/categories")}
    today = date.today()

    # Regular payments. The first charge is today or later,
    # so there are no duplicates with the history (it ends yesterday).
    if not api.call("GET", "/recurring")["items"]:
        for name, amount, account, category, day in [
            ("Dormitory", 15000, "Kaspi Gold", "Housing", 1),
            ("Spotify", 1990, "Halyk", "Subscriptions", 3),
            ("YouTube Premium", 1490, "Halyk", "Subscriptions", 12),
        ]:
            api.call("POST", "/recurring", {
                "name": name, "amount": amount, "account_id": accounts[account],
                "category_id": cats[category], "day_of_month": day,
            })
        print("  + regular payments")

    # Freelance income in the last two full months: the student saves money,
    # so goals get a forecast
    if not api.call("GET", "/transactions?q=Freelance%20project"):
        first_of_month = today.replace(day=1)
        for months_back in (1, 2):
            day = first_of_month
            for _ in range(months_back):
                day = (day - timedelta(days=1)).replace(day=1)
            api.call("POST", "/transactions", {
                "kind": "income", "amount": 30000, "date": day.replace(day=20).isoformat(),
                "account_id": accounts["Kaspi Gold"], "category_id": cats["Other income"],
                "note": "Freelance project",
            })
        print("  + freelance income")

    if not api.call("GET", "/goals")["goals"]:
        for name, target, saved in [("Laptop", 400000, 60000), ("Trip to Almaty", 90000, 30000)]:
            api.call("POST", "/goals", {
                "name": name, "target_amount": target, "saved_amount": saved,
            })
        print("  + goals")

    # One unusual purchase this month for the detector (also breaks the
    # Entertainment limit, so Home shows a red warning)
    if not api.call("GET", "/transactions?q=Concert%20VIP"):
        day = today - timedelta(days=1) if today.day > 1 else today
        api.call("POST", "/transactions", {
            "kind": "expense", "amount": 15000, "date": day.isoformat(),
            "account_id": accounts["Kaspi Gold"], "category_id": cats["Entertainment"],
            "note": "Concert VIP", "is_impulsive": True,
        })
        print("  + unusual purchase")


if __name__ == "__main__":
    main()
