from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.account import Account
from app.models.transaction import Transaction
from app.models.user import User
from app.schemas.account import AccountCreate, AccountOut, AccountsSummary, AccountUpdate

router = APIRouter(prefix="/accounts", tags=["accounts"])


def get_own_account(account_id: int, user: User, db: Session) -> Account:
    """Find the account and make sure it belongs to this user."""
    account = db.get(Account, account_id)
    if account is None or account.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Account not found")
    return account


@router.get("", response_model=AccountsSummary)
def list_accounts(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    accounts = db.scalars(
        select(Account).where(Account.user_id == current_user.id).order_by(Account.id)
    ).all()
    total = sum(account.balance for account in accounts)
    return AccountsSummary(accounts=accounts, total_balance=total)


@router.post("", response_model=AccountOut, status_code=status.HTTP_201_CREATED)
def create_account(
    data: AccountCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    account = Account(user_id=current_user.id, **data.model_dump())
    db.add(account)
    db.commit()
    db.refresh(account)
    return account


@router.put("/{account_id}", response_model=AccountOut)
def update_account(
    account_id: int,
    data: AccountUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    account = get_own_account(account_id, current_user, db)
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(account, field, value)
    db.commit()
    db.refresh(account)
    return account


@router.delete("/{account_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_account(
    account_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    account = get_own_account(account_id, current_user, db)
    used = db.scalar(
        select(Transaction.id)
        .where(
            or_(
                Transaction.account_id == account.id,
                Transaction.to_account_id == account.id,
            )
        )
        .limit(1)
    )
    if used is not None:
        raise HTTPException(
            status.HTTP_409_CONFLICT, "Account has transactions. Delete them first."
        )
    db.delete(account)
    db.commit()