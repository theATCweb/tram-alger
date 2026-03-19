"""
Core configuration module.
Loads settings from environment variables using pydantic-settings.
"""
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql+asyncpg://user:password@localhost:5432/tram_alger"
    REDIS_URL: str = "redis://localhost:6379/0"
    SESSION_HASH_SALT: str = "tram-alger-salt-2024-replace-me"
    DEBUG: bool = False
    PORT: int = 8000
    ETA_CACHE_TTL_SEC: int = 30
    GPS_MAX_AGE_SEC: int = 90
    DEFAULT_DELAY_SEC: int = 120
    GPS_RING_BUFFER_LEN: int = 200

    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """Return cached settings instance."""
    return Settings()
