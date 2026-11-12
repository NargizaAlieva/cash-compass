from datetime import date as Date
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator

TransactionKind = Literal["income", "expense", "transfer"]


class TransactionIn(BaseModel):
    """Body for creating or fully replacing a transaction."""

    kind: TransactionKind
    amount: float = Field(gt=0, le=1_000_000_000)
    account_id: int
    to_account_id: int | None = None
    category_id: int | None = None
    date: Date = Field(default_factory=Date.today)
    note: str = Field(default="", max_length=200)
    is_impulsive: bool = False

    @model_validator(mode="after")
    def check_kind_rules(self):
        if self.kind == "transfer":
            if self.to_account_id is None:
                raise ValueError("Transfer needs to_account_id")
            if self.to_account_id == self.account_id:
                raise ValueError("Cannot transfer to the same account")
            if self.category_id is not None:
                raise ValueError("Transfer cannot have a category")
        else:
            if self.category_id is None:
                raise ValueError("Income and expense need a category")
            if self.to_account_id is not None:
                raise ValueError("Only transfers can have to_account_id")
        # Only an expense can be impulsive
        if self.kind != "expense":
            self.is_impulsive = False
        return self


class TransactionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    kind: TransactionKind
    amount: float
    account_id: int
    to_account_id: int | None
    category_id: int | None
    date: Date
    note: str
    is_impulsive: bool