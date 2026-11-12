from datetime import date

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.recurring_payment import RecurringPayment
from app.models.transaction import Transaction
from app.models.user import User
from app.routers.accounts import get_own_account
from app.routers.categories import get_own_category
from app.schemas.recurring import RecurringIn, RecurringOut, RecurringSummary, RecurringUpdate
from app.services.months import next_monthly_date

router = APIRouter(prefix="/recurring", tags=["recurring payments"])


def get_own_payment(payment_id: int, user: User, db: Session) -> RecurringPayment:
    payment = db.get(RecurringPayment, payment_id)
    if payment is None or payment.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Regular payment not found")
    return payment


def check_references(user: User, db: Session, account_id: int, category_id: int) -> None:
    get_own_account(account_id, user, db)
    category = get_own_category(category_id, user, db)
    if category.kind != "expense":
        raise HTTPException(422, "A regular payment needs an expense category")


@router.get("", response_model=RecurringSummary)
def list_payments(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    payments = db.scalars(
        select(RecurringPayment)
        .where(RecurringPayment.user_id == current_user.id)
        .order_by(RecurringPayment.next_date, RecurringPayment.id)
    ).all()
    monthly = sum(p.amount for p in payments if p.is_active)
    return RecurringSummary(items=payments, monthly_total=monthly, yearly_total=monthly * 12)


@router.post("", response_model=RecurringOut, status_code=status.HTTP_201_CREATED)
def create_payment(
    data: RecurringIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    check_references(current_user, db, data.account_id, data.category_id)
    payment = RecurringPayment(
        user_id=current_user.id,
        # The first charge: this day this month, or next month if it already passed
        next_date=next_monthly_date(data.day_of_month, date.today()),
        **data.model_dump(),
    )
    db.add(payment)
    db.commit()
    db.refresh(payment)
    return payment


@router.put("/{payment_id}", response_model=RecurringOut)
def update_payment(
    payment_id: int,
    data: RecurringUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    payment = get_own_payment(payment_id, current_user, db)
    changes = data.model_dump(exclude_unset=True)
    check_references(
        current_user,
        db,
        changes.get("account_id", payment.account_id),
        changes.get("category_id", payment.category_id),
    )

    today = date.today()
    was_paused = not payment.is_active
    for field, value in changes.items():
        setattr(payment, field, value)

    if "day_of_month" in changes or (was_paused and payment.is_active):
        # Never charge twice in one month: if this month was already paid,
        # the next date stays in the month of the old next date or later
        start = max(today, payment.next_date.replace(day=1))
        payment.next_date = next_monthly_date(payment.day_of_month, start)

    db.commit()
    db.refresh(payment)
    return payment


@router.delete("/{payment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_payment(
    payment_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    payment = get_own_payment(payment_id, current_user, db)
    # Expenses that were already created stay in the history
    db.execute(
        update(Transaction)
        .where(Transaction.recurring_payment_id == payment.id)
        .values(recurring_payment_id=None)
    )
    db.delete(payment)
    db.commit()
