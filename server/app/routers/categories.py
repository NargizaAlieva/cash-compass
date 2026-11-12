from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.category import Category
from app.models.transaction import Transaction
from app.models.user import User
from app.schemas.category import CategoryCreate, CategoryKind, CategoryOut, CategoryUpdate

router = APIRouter(prefix="/categories", tags=["categories"])


def get_own_category(category_id: int, user: User, db: Session) -> Category:
    """Find the category and make sure it belongs to this user."""
    category = db.get(Category, category_id)
    if category is None or category.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Category not found")
    return category


def ensure_name_is_free(
    db: Session, user_id: int, kind: str, name: str, exclude_id: int | None = None
) -> None:
    """Two categories of the same kind cannot have the same name."""
    query = select(Category).where(
        Category.user_id == user_id,
        Category.kind == kind,
        func.lower(Category.name) == name.lower(),
    )
    if exclude_id is not None:
        query = query.where(Category.id != exclude_id)
    if db.scalar(query) is not None:
        raise HTTPException(status.HTTP_409_CONFLICT, "Category with this name already exists")


@router.get("", response_model=list[CategoryOut])
def list_categories(
    kind: CategoryKind | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = select(Category).where(Category.user_id == current_user.id)
    if kind is not None:
        query = query.where(Category.kind == kind)
    return db.scalars(query.order_by(Category.id)).all()


@router.post("", response_model=CategoryOut, status_code=status.HTTP_201_CREATED)
def create_category(
    data: CategoryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    ensure_name_is_free(db, current_user.id, data.kind, data.name)
    category = Category(user_id=current_user.id, **data.model_dump())
    db.add(category)
    db.commit()
    db.refresh(category)
    return category


@router.put("/{category_id}", response_model=CategoryOut)
def update_category(
    category_id: int,
    data: CategoryUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    category = get_own_category(category_id, current_user, db)
    if data.name is not None:
        ensure_name_is_free(db, current_user.id, category.kind, data.name, exclude_id=category.id)
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(category, field, value)
    db.commit()
    db.refresh(category)
    return category


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_category(
    category_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    category = get_own_category(category_id, current_user, db)
    used = db.scalar(
        select(Transaction.id).where(Transaction.category_id == category.id).limit(1)
    )
    if used is not None:
        raise HTTPException(
            status.HTTP_409_CONFLICT, "Category is used by transactions. Delete them first."
        )
    db.delete(category)
    db.commit()