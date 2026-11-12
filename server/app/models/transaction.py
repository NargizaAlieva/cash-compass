import datetime as dt

from sqlalchemy import Date, DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Transaction(Base):
    """Money in, money out, or money moved between two accounts."""

    __tablename__ = "transactions"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    kind: Mapped[str] = mapped_column(String(10))  # "income", "expense", "transfer"
    amount: Mapped[float]  # always positive, kind says the direction
    account_id: Mapped[int] = mapped_column(ForeignKey("accounts.id"), index=True)
    # Only for transfers: where the money goes
    to_account_id: Mapped[int | None] = mapped_column(
        ForeignKey("accounts.id"), default=None
    )
    # Not used for transfers
    category_id: Mapped[int | None] = mapped_column(
        ForeignKey("categories.id"), default=None, index=True
    )
    date: Mapped[dt.date] = mapped_column(Date, index=True)
    note: Mapped[str] = mapped_column(String(200), default="")
    # "Wanted it" instead of "needed it" - only for expenses
    is_impulsive: Mapped[bool] = mapped_column(default=False)
    # Set when the server created this expense from a regular payment
    recurring_payment_id: Mapped[int | None] = mapped_column(
        ForeignKey("recurring_payments.id", name="fk_transactions_recurring_payment_id"),
        default=None,
    )
    created_at: Mapped[dt.datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: dt.datetime.now(dt.timezone.utc)
    )