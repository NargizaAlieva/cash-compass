import math
from datetime import date

from sqlalchemy.orm import Session

from app.models.goal import Goal
from app.schemas.goal import GoalOut
from app.services.analytics import previous_month, totals_by_kind


def average_monthly_saving(db: Session, user_id: int, today: date) -> float:
    """Average of (income - expenses) of the last 3 full months.

    Months without any income or expenses (before the user started) are skipped.
    """
    month = today.strftime("%Y-%m")
    savings = []
    for _ in range(3):
        month = previous_month(month)
        totals = totals_by_kind(db, user_id, month)
        if totals["income"] or totals["expense"]:
            savings.append(totals["income"] - totals["expense"])
    if not savings:
        return 0.0
    return max(sum(savings) / len(savings), 0.0)


def add_months(day: date, months: int) -> date:
    """First day of the month that is [months] after [day]'s month."""
    index = day.year * 12 + (day.month - 1) + months
    return date(index // 12, index % 12 + 1, 1)


def goal_out(goal: Goal, monthly_saving: float, today: date) -> GoalOut:
    remaining = max(goal.target_amount - goal.saved_amount, 0)
    achieved = remaining == 0
    if achieved:
        months_left, forecast = 0, today
    elif monthly_saving > 0:
        months_left = math.ceil(remaining / monthly_saving)
        forecast = add_months(today, months_left)
    else:
        months_left, forecast = None, None
    return GoalOut(
        id=goal.id,
        name=goal.name,
        target_amount=goal.target_amount,
        saved_amount=goal.saved_amount,
        percent=round(min(goal.saved_amount / goal.target_amount * 100, 100), 1),
        achieved=achieved,
        months_left=months_left,
        forecast_date=forecast,
    )
