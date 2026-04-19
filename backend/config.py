from pydantic_settings import BaseSettings
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent

class Settings(BaseSettings):
    database_url: str = f"sqlite:///{BASE_DIR}/app.db"
    app_name: str = "Reverse Expense Tracker"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    secret_key: str

    class Config:
        env_file = BASE_DIR / ".env"

settings = Settings()   #type: ignore