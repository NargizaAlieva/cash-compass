from datetime import date as Date

from pydantic import BaseModel, Field


class GoalIn(BaseModel):
    name: str = Field(min_length=1, max_length=50)
    target_amount: float = Field(gt=0, le=1_000_000_000)
    saved_amount: float = Field(default=0, ge=0, le=1_000_000_000)


class GoalUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=50)
    target_amount: float | None = Field(default=None, gt=0, le=1_000_000_000)
    saved_amount: float | None = Field(default=None, ge=0, le=1_000_000_000)


class GoalOut(BaseModel):
    id: int
    name: str
    target_amount: float
    saved_amount: float
    percent: float  # 0-100
    achieved: bool
    # How many months are left at the current saving pace and when it will be.
    # None when the user does not save anything now (spends all income).
    months_left: int | None
    forecast_date: Date | None


class GoalsOverview(BaseModel):
    # Average (income - expenses) of the last 3 full months, never below 0
    monthly_saving: float
    goals: list[GoalOut]
