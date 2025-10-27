# app/core/config.py
from pydantic_settings import BaseSettings, SettingsConfigDict
from urllib.parse import quote_plus
import os
from dotenv import load_dotenv
from pathlib import Path
load_dotenv()
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
    
    #AI
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    AI_MODEL_ID: str = os.getenv("AI_MODEL_ID", "gemini-2.0-flash-preview-image-generation")
    AI_MAX_IMAGE_MB: int = int(os.getenv("AI_MAX_IMAGE_MB", "8"))
    AI_OUTPUT_DIR: Path = Path(os.getenv("AI_OUTPUT_DIR", "./static/ai_results")).resolve()
    BASE_URL: str = os.getenv("BASE_URL", "http://192.168.1.10:8000")
    
    model_config = SettingsConfigDict(env_file=".env", case_sensitive=False)

    @property
    def SQLALCHEMY_DATABASE_URI(self) -> str:
        pw = quote_plus(self.DB_PASS or "")
        return f"mysql+pymysql://{self.DB_USER}:{pw}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}?charset=utf8mb4"

settings = Settings()
settings.AI_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)