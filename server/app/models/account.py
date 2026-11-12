from datetime import datetime, timezone

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Account(Base):
    """A place where money is kept: cash, a bank card, etc."""

    __tablename__ = "accounts"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    name: Mapped[str] = mapped_column(String(50))
    type: Mapped[str] = mapped_column(String(10))  # "cash" or "card"
    currency: Mapped[str] = mapped_column(String(3), default="KGS")
    balance: Mapped[float] = mapped_column(default=0)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )