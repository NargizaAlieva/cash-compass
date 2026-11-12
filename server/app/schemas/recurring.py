from datetime import date as Date

from pydantic import BaseModel, ConfigDict, Field


class RecurringIn(BaseModel):
    name: str = Field(min_length=1, max_length=50)
    amount: float = Field(gt=0, le=1_000_000_000)
    account_id: int
    category_id: int  # must be an expense category
    day_of_month: int = Field(ge=1, le=31)


class RecurringUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=50)
    amount: float | None = Field(default=None, gt=0, le=1_000_000_000)
    account_id: int | None = None
    category_id: int | None = None
    day_of_month: int | None = Field(default=None, ge=1, le=31)
    is_active: bool | None = None


class RecurringOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    amount: float
    account_id: int
    category_id: int
    day_of_month: int
    next_date: Date
    is_active: bool


class RecurringSummary(BaseModel):
    items: list[RecurringOut]  # the next payment first
    monthly_total: float  # active payments only
    yearly_total: float
