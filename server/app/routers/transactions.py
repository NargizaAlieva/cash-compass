from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.transaction import Transaction
from app.models.user import User
from app.routers.accounts import get_own_account
from app.routers.categories import get_own_category
from app.schemas.transaction import TransactionIn, TransactionKind, TransactionOut
from app.services.balances import apply_to_balances

router = APIRouter(prefix="/transactions", tags=["transactions"])


def get_own_transaction(transaction_id: int, user: User, db: Session) -> Transaction:
    """Find the transaction and make sure it belongs to this user."""
    transaction = db.get(Transaction, transaction_id)
    if transaction is None or transaction.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Transaction not found")
    return transaction


def check_references(data: TransactionIn, user: User, db: Session) -> None:
    """Accounts and category must belong to the user, category kind must match."""
    get_own_account(data.account_id, user, db)
    if data.to_account_id is not None:
        get_own_account(data.to_account_id, user, db)
    if data.category_id is not None:
        category = get_own_category(data.category_id, user, db)
        if category.kind != data.kind:
            raise HTTPException(
                422,
                f"Category '{category.name}' is for {category.kind}, not {data.kind}",
            )


@router.get("", response_model=list[TransactionOut])
def list_transactions(
    date_from: date | None = None,
    date_to: date | None = None,
    kind: TransactionKind | None = None,
    account_id: int | None = None,
    category_id: int | None = None,
    q: str | None = Query(default=None, description="Search in the note"),
    limit: int = Query(default=100, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = select(Transaction).where(Transaction.user_id == current_user.id)
    if date_from is not None:
        query = query.where(Transaction.date >= date_from)
    if date_to is not None:
        query = query.where(Transaction.date <= date_to)
    if kind is not None:
        query = query.where(Transaction.kind == kind)
    if account_id is not None:
        # A transfer shows up for both accounts
        query = query.where(
            or_(
                Transaction.account_id == account_id,
                Transaction.to_account_id == account_id,
            )
        )
    if category_id is not None:
        query = query.where(Transaction.category_id == category_id)
    if q:
        query = query.where(Transaction.note.ilike(f"%{q}%"))

    # Newest first
    query = query.order_by(Transaction.date.desc(), Transaction.id.desc())
    return db.scalars(query.limit(limit).offset(offset)).all()


@router.get("/{transaction_id}", response_model=TransactionOut)
def read_transaction(
    transaction_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return get_own_transaction(transaction_id, current_user, db)


@router.post("", response_model=TransactionOut, status_code=status.HTTP_201_CREATED)
def create_transaction(
    data: TransactionIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    check_references(data, current_user, db)
    transaction = Transaction(user_id=current_user.id, **data.model_dump())
    db.add(transaction)
    apply_to_balances(db, transaction)
    db.commit()  # transaction and new balances are saved together
    db.refresh(transaction)
    return transaction


@router.put("/{transaction_id}", response_model=TransactionOut)
def update_transaction(
    transaction_id: int,
    data: TransactionIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    transaction = get_own_transaction(transaction_id, current_user, db)
    check_references(data, current_user, db)

    apply_to_balances(db, transaction, sign=-1)  # undo the old version
    for field, value in data.model_dump().items():
        setattr(transaction, field, value)
    apply_to_balances(db, transaction)  # apply the new version

    db.commit()
    db.refresh(transaction)
    return transaction


@router.delete("/{transaction_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transaction(
    transaction_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    transaction = get_own_transaction(transaction_id, current_user, db)
    apply_to_balances(db, transaction, sign=-1)
    db.delete(transaction)
    db.commit()