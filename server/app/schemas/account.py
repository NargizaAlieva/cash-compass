from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

AccountType = Literal["cash", "card"]


class AccountCreate(BaseModel):
    name: str = Field(min_length=1, max_length=50)
    type: AccountType = "card"
    # Starting balance. Later it changes only through transactions.
    balance: float = 0


class AccountUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=50)
    type: AccountType | None = None


class AccountOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    type: AccountType
    currency: str
    balance: float


class AccountsSummary(BaseModel):
    accounts: list[AccountOut]
    total_balance: float