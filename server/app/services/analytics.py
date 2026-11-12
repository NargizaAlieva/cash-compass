from datetime import date, timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.transaction import Transaction
from app.schemas.analytics import (
    CategoryAmount,
    CategoryChange,
    DayAmount,
    ImpulseStats,
    MonthAnalytics,
)
from app.services.months import month_range


def previous_month(month: str) -> str:
    """"2026-01" -> "2025-12"."""
    start, _ = month_range(month)
    return (start - timedelta(days=1)).strftime("%Y-%m")


def percent_of(part: float, whole: float) -> float:
    return round(part / whole * 100, 1) if whole else 0.0


def _in_month(user_id: int, month: str):
    """SQL conditions: this user's transactions inside the month."""
    start, end = month_range(month)
    return (
        Transaction.user_id == user_id,
        Transaction.date >= start,
        Transaction.date < end,
    )


def totals_by_kind(db: Session, user_id: int, month: str) -> dict[str, float]:
    """{"income": ..., "expense": ...}. Transfers are not income or spending."""
    rows = db.execute(
        select(Transaction.kind, func.sum(Transaction.amount))
        .where(*_in_month(user_id, month), Transaction.kind != "transfer")
        .group_by(Transaction.kind)
    ).all()
    totals = {"income": 0.0, "expense": 0.0}
    totals.update({kind: amount for kind, amount in rows})
    return totals


def expense_by_category(db: Session, user_id: int, month: str) -> dict[int | None, float]:
    rows = db.execute(
        select(Transaction.category_id, func.sum(Transaction.amount))
        .where(*_in_month(user_id, month), Transaction.kind == "expense")
        .group_by(Transaction.category_id)
    ).all()
    return {category_id: amount for category_id, amount in rows}


def expense_by_day(db: Session, user_id: int, month: str) -> dict[date, float]:
    rows = db.execute(
        select(Transaction.date, func.sum(Transaction.amount))
        .where(*_in_month(user_id, month), Transaction.kind == "expense")
        .group_by(Transaction.date)
    ).all()
    return {day: amount for day, amount in rows}


def impulse_stats(db: Session, user_id: int, month: str, expense: float) -> ImpulseStats:
    amount, count = db.execute(
        select(func.coalesce(func.sum(Transaction.amount), 0), func.count())
        .where(
            *_in_month(user_id, month),
            Transaction.kind == "expense",
            Transaction.is_impulsive.is_(True),
        )
    ).one()
    return ImpulseStats(amount=amount, count=count, percent=percent_of(amount, expense))


def month_analytics(
    db: Session, user_id: int, month: str, today: date | None = None
) -> MonthAnalytics:
    """Everything the Analytics screen needs for one month, in one response."""
    today = today or date.today()
    start, end = month_range(month)

    totals = totals_by_kind(db, user_id, month)
    expense = totals["expense"]

    # Pie chart: biggest category first
    by_category_raw = expense_by_category(db, user_id, month)
    by_category = sorted(
        (
            CategoryAmount(
                category_id=category_id,
                amount=amount,
                percent=percent_of(amount, expense),
            )
            for category_id, amount in by_category_raw.items()
        ),
        key=lambda item: item.amount,
        reverse=True,
    )

    # Every day of the month, so the chart and heatmap have no gaps
    per_day = expense_by_day(db, user_id, month)
    days_in_month = (end - start).days
    daily = [
        DayAmount(date=day, expense=per_day.get(day, 0.0))
        for day in (start + timedelta(days=i) for i in range(days_in_month))
    ]

    # For the current month count only the days that already passed
    # (and only expenses up to today, in case some are dated in the future)
    is_current = start <= today < end
    if is_current:
        days_passed = (today - start).days + 1
        spent_so_far = sum(d.expense for d in daily if d.date <= today)
    else:
        days_passed = days_in_month
        spent_so_far = expense
    avg_daily = spent_so_far / days_passed
    forecast = round(avg_daily * days_in_month, 2) if is_current else None

    # Compare with the previous month
    prev_month = previous_month(month)
    prev_expense = totals_by_kind(db, user_id, prev_month)["expense"]
    change_percent = (
        round((expense - prev_expense) / prev_expense * 100, 1) if prev_expense else None
    )
    prev_by_category = expense_by_category(db, user_id, prev_month)
    category_changes = sorted(
        (
            CategoryChange(
                category_id=category_id,
                current=by_category_raw.get(category_id, 0.0),
                previous=prev_by_category.get(category_id, 0.0),
                change=by_category_raw.get(category_id, 0.0)
                - prev_by_category.get(category_id, 0.0),
            )
            for category_id in by_category_raw.keys() | prev_by_category.keys()
        ),
        # The biggest change (up or down) first
        key=lambda item: abs(item.change),
        reverse=True,
    )

    return MonthAnalytics(
        month=month,
        income=totals["income"],
        expense=expense,
        net=totals["income"] - expense,
        avg_daily_expense=round(avg_daily, 2),
        forecast_expense=forecast,
        previous_expense=prev_expense,
        expense_change_percent=change_percent,
        by_category=by_category,
        daily=daily,
        category_changes=category_changes,
        impulse=impulse_stats(db, user_id, month, expense),
    )