from sqlalchemy import ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Budget(Base):
    """Monthly spending limit for one expense category, e.g. Food: 40 000 a month.

    The limit is the same every month. How much is spent is calculated
    from transactions for the month the user asks about.
    """

    __tablename__ = "budgets"
    # One limit per category
    __table_args__ = (UniqueConstraint("user_id", "category_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    category_id: Mapped[int] = mapped_column(ForeignKey("categories.id"))
    limit_amount: Mapped[float]