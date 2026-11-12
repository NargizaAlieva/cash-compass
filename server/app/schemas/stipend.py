from datetime import date as Date

from pydantic import BaseModel


class StipendAllowance(BaseModel):
    """How much the student can spend today to last until the next stipend."""

    # False if the user did not set the stipend day yet.
    # Then all other fields are null.
    configured: bool
    stipend_day: int | None = None
    next_stipend_date: Date | None = None
    days_left: int | None = None  # today is counted, the stipend day is not
    balance: float | None = None  # money on all accounts now
    # Regular payments (rent, subscriptions) that come before the stipend.
    # This money is put aside and not counted in the daily budget.
    reserved_for_payments: float | None = None
    daily_allowance: float | None = None  # what can be spent each day
    spent_today: float | None = None
    left_today: float | None = None  # negative = spent more than allowed today