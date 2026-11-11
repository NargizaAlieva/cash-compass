from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """App settings. Values are read from the .env file if it exists."""

    secret_key: str = "dev-only-secret-key-change-me-in-env-file-0123456789"
    database_url: str = "sqlite:///./cash_compass.db"
    access_token_expire_minutes: int = 1440

    model_config = SettingsConfigDict(env_file=".env")


settings = Settings()