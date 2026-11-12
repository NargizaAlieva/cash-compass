from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.schemas.stipend import StipendAllowance
from app.services.stipend import stipend_allowance

router = APIRouter(prefix="/stipend", tags=["stipend"])


@router.get("/allowance", response_model=StipendAllowance)
def get_allowance(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """How much can be spent today to last until the next stipend.

    The stipend day is set with PUT /auth/me {"stipend_day": 25}.
    """
    return stipend_allowance(db, current_user)