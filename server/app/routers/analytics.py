from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.schemas.analytics import MonthAnalytics
from app.schemas.budget import MONTH_PATTERN
from app.services.analytics import month_analytics
from app.services.months import current_month

router = APIRouter(prefix="/analytics", tags=["analytics"])


@router.get("/month", response_model=MonthAnalytics)
def get_month_analytics(
    month: str | None = Query(
        default=None,
        pattern=MONTH_PATTERN,
        description="Month like 2026-11. Default: current month",
    ),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Summary, pie chart, daily chart, comparison and impulse stats for a month."""
    return month_analytics(db, current_user.id, month or current_month())