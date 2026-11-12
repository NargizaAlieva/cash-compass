from sqlalchemy.orm import Session

from app.models.account import Account
from app.models.transaction import Transaction


def apply_to_balances(db: Session, transaction: Transaction, sign: int = 1) -> None:
    """Change account balances because of a transaction.

    sign=1 applies the transaction (when it is created),
    sign=-1 reverts it (when it is deleted or before it is changed).
    """
    amount = transaction.amount * sign
    account = db.get(Account, transaction.account_id)

    if transaction.kind == "income":
        account.balance += amount
    elif transaction.kind == "expense":
        account.balance -= amount
    elif transaction.kind == "transfer":
        to_account = db.get(Account, transaction.to_account_id)
        account.balance -= amount
        to_account.balance += amount