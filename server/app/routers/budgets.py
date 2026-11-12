from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.budget import Budget
from app.models.user import User
from app.routers.categories import get_own_category
from app.schemas.budget import MONTH_PATTERN, BudgetsOverview, BudgetSet
from app.services.budgets import budgets_overview
from app.services.months import current_month

router = APIRouter(prefix="/budgets", tags=["budgets"])


@router.get("", response_model=BudgetsOverview)
def get_budgets(
    month: str | None = Query(
        default=None,
        pattern=MONTH_PATTERN,
        description="Month like 2026-11. Default: current month",
    ),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return budgets_overview(db, current_user.id, month or current_month())


@router.put("/{category_id}", response_model=BudgetsOverview)
def set_budget(
    category_id: int,
    data: BudgetSet,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create the limit for a category, or change it if it already exists."""
    category = get_own_category(category_id, current_user, db)
    if category.kind != "expense":
        raise HTTPException(422, "Limits can be set only for expense categories")

    budget = db.scalar(
        select(Budget).where(
            Budget.user_id == current_user.id, Budget.category_id == category_id
        )
    )
    if budget is None:
        budget = Budget(user_id=current_user.id, category_id=category_id)
        db.add(budget)
    budget.limit_amount = data.limit_amount
    db.commit()
    return budgets_overview(db, current_user.id, current_month())


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_budget(
    category_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    budget = db.scalar(
        select(Budget).where(
            Budget.user_id == current_user.id, Budget.category_id == category_id
        )
    )
    if budget is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Limit not found")
    db.delete(budget)
    db.commit()