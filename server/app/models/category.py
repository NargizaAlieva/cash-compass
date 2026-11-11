from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Category(Base):
    """Income or expense category, e.g. Food or Stipend."""

    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    name: Mapped[str] = mapped_column(String(50))
    kind: Mapped[str] = mapped_column(String(10))  # "income" or "expense"
    icon: Mapped[str] = mapped_column(String(50))  # Material icon name
    color: Mapped[str] = mapped_column(String(7))  # "#RRGGBB"