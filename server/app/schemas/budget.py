from typing import Literal

from pydantic import BaseModel, Field

BudgetLevel = Literal["ok", "warning", "over"]

# "2026-11"
MONTH_PATTERN = r"^\d{4}-(0[1-9]|1[0-2])$"


class BudgetSet(BaseModel):
    limit_amount: float = Field(gt=0, le=1_000_000_000)


class BudgetStatus(BaseModel):
    """One limit and how much of it is already spent this month."""

    category_id: int
    limit_amount: float
    spent: float
    remaining: float  # negative when the limit is exceeded
    percent: float  # 0-100+, e.g. 85.5
    level: BudgetLevel  # ok < 80% <= warning < 100% <= over


class BudgetsOverview(BaseModel):
    month: str
    items: list[BudgetStatus]
    total_limit: float
    total_spent: float