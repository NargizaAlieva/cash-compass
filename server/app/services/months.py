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