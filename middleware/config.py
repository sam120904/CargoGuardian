"""
Configuration module for the Smart Cargo Intelligence Network middleware.
Loads environment variables and provides centralized config access.
"""

import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
    """Application settings loaded from environment variables."""

    # TigerGraph Cloud
    TG_HOST: str = os.getenv("TG_HOST", "")
    TG_USERNAME: str = os.getenv("TG_USERNAME", "tigergraph")
    TG_PASSWORD: str = os.getenv("TG_PASSWORD", "")
    TG_GRAPH_NAME: str = os.getenv("TG_GRAPH_NAME", "CargoNetwork")
    TG_SECRET: str = os.getenv("TG_SECRET", "")

    # Blynk IoT
    BLYNK_AUTH_TOKEN: str = os.getenv("BLYNK_AUTH_TOKEN", "")
    BLYNK_BASE_URL: str = os.getenv(
        "BLYNK_BASE_URL", "https://blynk.cloud/external/api"
    )

    # Server
    PORT: int = int(os.getenv("PORT", "8000"))
    CORS_ORIGINS: list[str] = os.getenv(
        "CORS_ORIGINS", "http://localhost:*"
    ).split(",")

    # Sync interval (seconds)
    SYNC_INTERVAL: int = int(os.getenv("SYNC_INTERVAL", "30"))

    # Demo mode (use fake data when TigerGraph is not connected)
    DEMO_MODE: bool = os.getenv("DEMO_MODE", "true").lower() == "true"

    def is_tigergraph_configured(self) -> bool:
        """Check if TigerGraph credentials are properly configured."""
        return bool(self.TG_HOST and self.TG_PASSWORD and self.TG_SECRET)


settings = Settings()
