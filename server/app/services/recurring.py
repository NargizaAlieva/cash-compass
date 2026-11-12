from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.recurring_payment import RecurringPayment
from app.models.transaction import Transaction
from app.services.balances import apply_to_balances
from app.services.months import next_monthly_date


def process_due_payments(db: Session, user_id: int, today: date | None = None) -> int:
    """Create the expenses of all regular payments that are due by today.

    A free server sleeps and has no clock jobs, so instead of a timer this runs
    on every request of the user (see get_current_user). If the user did not
    open the app for 2 months, both missed payments are created with their
    real dates. Returns how many expenses were created.
    """
    today = today or date.today()
    due = db.scalars(
        select(RecurringPayment).where(
            RecurringPayment.user_id == user_id,
            RecurringPayment.is_active.is_(True),
            RecurringPayment.next_date <= today,
        )
    ).all()

    created = 0
    for payment in due:
        while payment.next_date <= today:
            transaction = Transaction(
                user_id=user_id,
                kind="expense",
                amount=payment.amount,
                account_id=payment.account_id,
                category_id=payment.category_id,
                date=payment.next_date,
                note=payment.name,
                recurring_payment_id=payment.id,
            )
            db.add(transaction)
            apply_to_balances(db, transaction)
            created += 1
            payment.next_date = next_monthly_date(
                payment.day_of_month, payment.next_date + timedelta(days=1)
            )

    if created:
        db.commit()
    return created


def reserved_before(db: Session, user_id: int, before: date) -> float:
    """Sum of active regular payments that will be charged before [before]."""
    payments = db.scalars(
        select(RecurringPayment).where(
            RecurringPayment.user_id == user_id,
            RecurringPayment.is_active.is_(True),
            RecurringPayment.next_date < before,
        )
    ).all()
    return sum(payment.amount for payment in payments)
