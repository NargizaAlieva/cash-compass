from sqlalchemy.orm import Session

from app.models.category import Category

# (name, kind, icon, color) - icon names match Flutter's Material Icons
DEFAULT_CATEGORIES = [
    ("Food", "expense", "restaurant", "#EF6C00"),
    ("Groceries", "expense", "shopping_cart", "#43A047"),
    ("Transport", "expense", "directions_bus", "#1E88E5"),
    ("Housing", "expense", "home", "#6D4C41"),
    ("Entertainment", "expense", "movie", "#8E24AA"),
    ("Health", "expense", "medical_services", "#E53935"),
    ("Education", "expense", "school", "#3949AB"),
    ("Clothes", "expense", "checkroom", "#D81B60"),
    ("Subscriptions", "expense", "subscriptions", "#00897B"),
    ("Other", "expense", "more_horiz", "#757575"),
    ("Stipend", "income", "school", "#2E7D32"),
    ("Salary", "income", "work", "#1565C0"),
    ("Gift", "income", "card_giftcard", "#AD1457"),
    ("Other income", "income", "attach_money", "#616161"),
]


def create_default_categories(db: Session, user_id: int) -> None:
    """Give a new user a ready set of categories. They can edit or delete them."""
    for name, kind, icon, color in DEFAULT_CATEGORIES:
        db.add(Category(user_id=user_id, name=name, kind=kind, icon=icon, color=color))