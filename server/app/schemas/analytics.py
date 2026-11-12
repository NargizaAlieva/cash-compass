from datetime import date as Date

from pydantic import BaseModel


class CategoryAmount(BaseModel):
    """How much was spent in one category (for the pie chart)."""

    category_id: int | None  # None = expense without a category
    amount: float
    percent: float  # share of all expenses this month


class DayAmount(BaseModel):
    """Expenses of one day (for the line chart and the heatmap)."""

    date: Date
    expense: float


class CategoryChange(BaseModel):
    """This month vs the previous month for one category."""

    category_id: int | None
    current: float
    previous: float
    change: float  # current - previous, negative = spent less


class ImpulseStats(BaseModel):
    """"Wanted it" purchases."""

    amount: float
    count: int
    percent: float  # share of all expenses this month


class MonthAnalytics(BaseModel):
    month: str
    income: float
    expense: float
    net: float  # income - expense
    avg_daily_expense: float
    # Expected expenses at the end of the month, only for the current month
    forecast_expense: float | None
    previous_expense: float
    # % change vs previous month, None if the previous month had no expenses
    expense_change_percent: float | None
    by_category: list[CategoryAmount]
    daily: list[DayAmount]  # every day of the month, also days with 0
    category_changes: list[CategoryChange]
    impulse: ImpulseStats