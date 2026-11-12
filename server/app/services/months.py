import calendar
from datetime import date


def current_month() -> str:
    """Today's month as "2026-11"."""
    return date.today().strftime("%Y-%m")


def month_range(month: str) -> tuple[date, date]:
    """"2026-11" -> (2026-11-01, 2026-12-01). The end date is NOT included."""
    year, number = (int(part) for part in month.split("-"))
    start = date(year, number, 1)
    end = date(year + 1, 1, 1) if number == 12 else date(year, number + 1, 1)
    return start, end

def day_in_month(year: int, month: int, day: int) -> date:
    """Day 31 in a 30-day month (or in February) becomes the last day of that month."""
    last_day = calendar.monthrange(year, month)[1]
    return date(year, month, min(day, last_day))


def next_monthly_date(day: int, on_or_after: date) -> date:
    """The first date with this day of the month that is not earlier than [on_or_after]."""
    this_month = day_in_month(on_or_after.year, on_or_after.month, day)
    if this_month >= on_or_after:
        return this_month
    if on_or_after.month == 12:
        return day_in_month(on_or_after.year + 1, 1, day)
    return day_in_month(on_or_after.year, on_or_after.month + 1, day)
