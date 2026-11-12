"""Finds unusual spending: a purchase much bigger than usual in its category,
or a category where this month costs much more than in the previous months.

Purchases use the median and MAD (median absolute deviation) instead of the
average and standard deviation: one huge purchase in the history does not
change them much, so the detector is not "spoiled" by earlier outliers.
"""

from datetime import timedelta
from statistics import median

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.transaction import Transaction
from app.schemas.analytics import Anomaly
from app.services.months import month_range

HISTORY_DAYS = 120  # how far back we look for "usual" purchases
MIN_HISTORY = 5  # fewer purchases than this = we do not know what is usual
MAD_FACTOR = 3  # how many "typical deviations" above the median is unusual
MIN_TIMES = 2  # and at least twice the usual purchase
CATEGORY_TIMES = 1.5  # category month total vs the usual month
CATEGORY_MIN_DIFF = 5000  # ignore small differences in tenge


def _expenses(db: Session, user_id: int, start, end) -> list[Transaction]:
    return db.scalars(
        select(Transaction).where(
            Transaction.user_id == user_id,
            Transaction.kind == "expense",
            Transaction.date >= start,
            Transaction.date < end,
        )
    ).all()


def unusual_purchases(db: Session, user_id: int, month: str) -> list[Anomaly]:
    start, end = month_range(month)
    history: dict[int | None, list[float]] = {}
    for t in _expenses(db, user_id, start - timedelta(days=HISTORY_DAYS), start):
        history.setdefault(t.category_id, []).append(t.amount)

    found = []
    for t in _expenses(db, user_id, start, end):
        amounts = history.get(t.category_id, [])
        if len(amounts) < MIN_HISTORY:
            continue
        usual = median(amounts)
        # 1.4826 * MAD is comparable to a standard deviation
        spread = 1.4826 * median(abs(a - usual) for a in amounts)
        if t.amount > usual + MAD_FACTOR * spread and t.amount >= MIN_TIMES * usual:
            found.append(Anomaly(
                kind="purchase",
                category_id=t.category_id,
                transaction_id=t.id,
                date=t.date,
                amount=t.amount,
                usual=usual,
                times=round(t.amount / usual, 1),
            ))
    return found


def unusual_categories(
    current: dict[int | None, float], previous_months: list[dict[int | None, float]]
) -> list[Anomaly]:
    """[current] and every item of [previous_months] are {category_id: total}."""
    found = []
    for category_id, amount in current.items():
        usual = sum(m.get(category_id, 0.0) for m in previous_months) / max(len(previous_months), 1)
        if usual > 0 and amount >= CATEGORY_TIMES * usual and amount - usual >= CATEGORY_MIN_DIFF:
            found.append(Anomaly(
                kind="category",
                category_id=category_id,
                amount=amount,
                usual=round(usual, 2),
                times=round(amount / usual, 1),
            ))
    return found
