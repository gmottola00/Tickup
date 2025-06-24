from dotenv import load_dotenv
load_dotenv()

from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import SecretStr, Field
import logging
import os

logging.basicConfig(
    level=logging.INFO, 
    format="%(asctime)s %(levelname)s %(name)s | %(message)s",
)
logger = logging.getLogger(__name__)
logger.info("ENV vars loaded: %r", {
    k: os.getenv(k) for k in
    ["DATABASE_URL","SUPABASE_URL","SUPABASE_KEY","SUPABASE_JWT", "SUPABASE_PSW"] 
})

class Settings(BaseSettings):
    # carica .env, ignora eventuali chiavi non dichiarate
    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore",
    )
    logger.info(model_config)
    # valori di default
    PROJECT_NAME: str = "Tickup API"
    VERSION: str = "1.0.0"

    # qui mappi esattamente le chiavi che hai nel .env
    DATABASE_URL: str       = Field(..., env="DATABASE_URL")
    SUPABASE_PSW: str       = Field(..., env="SUPABASE_PSW")
    SUPABASE_URL: str       = Field(..., env="SUPABASE_URL")
    SUPABASE_KEY: SecretStr = Field(..., env="SUPABASE_KEY")
    SUPABASE_JWT: str       = Field(..., env="SUPABASE_JWT")

settings = Settings()
