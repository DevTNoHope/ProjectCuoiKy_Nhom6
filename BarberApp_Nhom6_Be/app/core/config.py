# app/core/config.py
from pydantic_settings import BaseSettings, SettingsConfigDict
from urllib.parse import quote_plus

class Settings(BaseSettings):
    APP_NAME: str = "Barber Booking API"
    APP_ENV: str = "dev"

    DB_HOST: str = "localhost"
    DB_PORT: int = 3306
    DB_USER: str = "root"
    DB_PASS: str = ""
    DB_NAME: str = "barber_booking"

    # JWT
    JWT_SECRET: str = "change_me"
    JWT_ALG: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    
    # OneSignal
    ONESIGNAL_APP_ID: str = ""
    ONESIGNAL_REST_API_KEY: str = ""
    
    model_config = SettingsConfigDict(env_file=".env", case_sensitive=False)

    @property
    def SQLALCHEMY_DATABASE_URI(self) -> str:
        pw = quote_plus(self.DB_PASS or "")
        return f"mysql+pymysql://{self.DB_USER}:{pw}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}?charset=utf8mb4"

settings = Settings()

  