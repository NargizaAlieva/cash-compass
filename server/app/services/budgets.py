from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.budget import Budget
from app.models.transaction import Transaction
from app.schemas.budget import BudgetsOverview, BudgetStatus
from app.services.months import month_range

WARNING_PERCENT = 80


def level_for(percent: float) -> str:
    if percent >= 100:
        return "over"
    if percent >= WARNING_PERCENT:
        return "warning"
    return "ok"


def spent_by_category(db: Session, user_id: int, month: str) -> dict[int, float]:
    """{category_id: sum of expenses} for one month, in one SQL query."""
    start, end = month_range(month)
    rows = db.execute(
        select(Transaction.category_id, func.sum(Transaction.amount))
        .where(
            Transaction.user_id == user_id,
            Transaction.kind == "expense",
            Transaction.date >= start,
            Transaction.date < end,
        )
        .group_by(Transaction.category_id)
    ).all()
    return {category_id: total for category_id, total in rows}


def budgets_overview(db: Session, user_id: int, month: str) -> BudgetsOverview:
    budgets = db.scalars(
        select(Budget).where(Budget.user_id == user_id).order_by(Budget.id)
    ).all()
    spent = spent_by_category(db, user_id, month)

    items = []
    for budget in budgets:
        spent_here = spent.get(budget.category_id, 0.0)
        percent = spent_here / budget.limit_amount * 100
        items.append(
            BudgetStatus(
                category_id=budget.category_id,
                limit_amount=budget.limit_amount,
                spent=spent_here,
                remaining=budget.limit_amount - spent_here,
                # Rounded only for showing. The level uses the exact value,
                # otherwise 79.99% would round to 80% and become "warning".
                percent=round(percent, 1),
                level=level_for(percent),
            )
        )

    # The most "dangerous" limits first
    items.sort(key=lambda item: item.percent, reverse=True)

    return BudgetsOverview(
        month=month,
        items=items,
        total_limit=sum(item.limit_amount for item in items),
        total_spent=sum(item.spent for item in items),
    )