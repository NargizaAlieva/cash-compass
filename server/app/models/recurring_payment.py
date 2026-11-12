import datetime as dt

from sqlalchemy import Date, DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class RecurringPayment(Base):
    """A payment that repeats every month: rent, Spotify, phone, gym...

    The server creates the expense by itself when [next_date] comes.
    """

    __tablename__ = "recurring_payments"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    name: Mapped[str] = mapped_column(String(50))
    amount: Mapped[float]
    account_id: Mapped[int] = mapped_column(ForeignKey("accounts.id"))
    category_id: Mapped[int] = mapped_column(ForeignKey("categories.id"))
    day_of_month: Mapped[int]  # 1-31, 31 in a short month = its last day
    next_date: Mapped[dt.date] = mapped_column(Date)  # when it is charged next time
    is_active: Mapped[bool] = mapped_column(default=True)  # False = paused
    created_at: Mapped[dt.datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: dt.datetime.now(dt.timezone.utc)
    )
