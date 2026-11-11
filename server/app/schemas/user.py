from pydantic import BaseModel, ConfigDict, EmailStr, Field


class RegisterRequest(BaseModel):
    email: EmailStr
    # bcrypt only uses the first 72 bytes, so we limit the length
    password: str = Field(min_length=6, max_length=64)
    name: str = Field(min_length=1, max_length=100)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    name: str
    stipend_day: int | None
    stipend_amount: float | None


class UserUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    stipend_day: int | None = Field(default=None, ge=1, le=31)
    stipend_amount: float | None = Field(default=None, ge=0)