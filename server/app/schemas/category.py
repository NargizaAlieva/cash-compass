from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

CategoryKind = Literal["income", "expense"]

# Color must look like "#1E88E5"
HEX_COLOR = r"^#[0-9A-Fa-f]{6}$"


class CategoryCreate(BaseModel):
    name: str = Field(min_length=1, max_length=50)
    kind: CategoryKind = "expense"
    icon: str = Field(default="category", min_length=1, max_length=50)
    color: str = Field(default="#607D8B", pattern=HEX_COLOR)


class CategoryUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=50)
    icon: str | None = Field(default=None, min_length=1, max_length=50)
    color: str | None = Field(default=None, pattern=HEX_COLOR)


class CategoryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    kind: CategoryKind
    icon: str
    color: str