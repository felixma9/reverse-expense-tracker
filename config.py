from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str = "sqlite:///./app.db"
    app_name: str = "Reverse Expense Tracker"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    secret_key: str

    class Config:
        env_file = ".env"

settings = Settings()   #type: ignore