import calendar
from datetime import date

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.account import Account
from app.models.transaction import Transaction
from app.models.user import User
from app.schemas.stipend import StipendAllowance
from app.services.recurring import reserved_before


def _day_in_month(year: int, month: int, day: int) -> date:
    """Stipend on the 31st in a 30-day month comes on the last day instead."""
    last_day = calendar.monthrange(year, month)[1]
    return date(year, month, min(day, last_day))


def next_stipend_date(stipend_day: int, today: date) -> date:
    """The next day the stipend comes. If it is today, the next one is next month."""
    this_month = _day_in_month(today.year, today.month, stipend_day)
    if this_month > today:
        return this_month
    year, month = (today.year + 1, 1) if today.month == 12 else (today.year, today.month + 1)
    return _day_in_month(year, month, stipend_day)


def stipend_allowance(db: Session, user: User, today: date | None = None) -> StipendAllowance:
    today = today or date.today()
    if user.stipend_day is None:
        return StipendAllowance(configured=False)

    next_date = next_stipend_date(user.stipend_day, today)
    # Today counts as a day to live; the stipend day itself does not
    days_left = (next_date - today).days

    balance = db.scalar(
        select(func.coalesce(func.sum(Account.balance), 0)).where(Account.user_id == user.id)
    )
    spent_today = db.scalar(
        select(func.coalesce(func.sum(Transaction.amount), 0)).where(
            Transaction.user_id == user.id,
            Transaction.kind == "expense",
            Transaction.date == today,
        )
    )

    # Money we had this morning, shared equally between the days left.
    # This way the daily number stays the same during the day,
    # and "left today" goes down with every purchase.
    money_this_morning = balance + spent_today
    reserved = reserved_before(db, user.id, next_date)
    daily = max(money_this_morning - reserved, 0) / days_left

    return StipendAllowance(
        configured=True,
        stipend_day=user.stipend_day,
        next_stipend_date=next_date,
        days_left=days_left,
        balance=balance,
        reserved_for_payments=reserved,
        daily_allowance=round(daily, 2),
        spent_today=spent_today,
        left_today=round(daily - spent_today, 2),
    )