from __future__ import annotations

import ipaddress
import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    environment: str
    openai_api_key: str
    openai_model: str
    api_token: str
    max_upload_bytes: int
    max_text_chars: int
    ai_provider: str = "openai"
    apple_fm_timeout_seconds: int = 90
    apple_fm_max_prompt_chars: int = 12_000
    openai_timeout_seconds: float = 30.0
    openai_max_retries: int = 2
    openai_max_output_tokens: int = 4_000
    bind_host: str = "127.0.0.1"

    @property
    def openai_configured(self) -> bool:
        return bool(self.openai_api_key.strip())

    @property
    def ai_configured(self) -> bool:
        return self.openai_configured

    @property
    def bind_is_loopback(self) -> bool:
        return is_loopback_host(self.bind_host)

    @classmethod
    def from_environment(cls) -> "Settings":
        environment = os.getenv("HOGUE_ENVIRONMENT", "development").strip().lower()
        if environment not in {"development", "test", "production"}:
            raise ValueError(
                "HOGUE_ENVIRONMENT must be exactly one of: development, test, production"
            )
        ai_provider = os.getenv("HOGUE_AI_PROVIDER", "auto").strip().lower()
        if ai_provider not in {"auto", "apple", "openai"}:
            ai_provider = "auto"
        bind_host = os.getenv("HOGUE_BIND_HOST", "127.0.0.1").strip()
        if not bind_host:
            raise ValueError("HOGUE_BIND_HOST must not be empty")
        return cls(
            environment=environment,
            openai_api_key=os.getenv("OPENAI_API_KEY", ""),
            openai_model=os.getenv("HOGUE_OPENAI_MODEL", "gpt-5.6-sol"),
            api_token=os.getenv("HOGUE_API_TOKEN", ""),
            max_upload_bytes=_bounded_int(
                "HOGUE_MAX_UPLOAD_BYTES",
                default=10_485_760,
                minimum=1_024,
                maximum=25_000_000,
            ),
            max_text_chars=_bounded_int(
                "HOGUE_MAX_TEXT_CHARS",
                default=200_000,
                minimum=1_000,
                maximum=500_000,
            ),
            ai_provider=ai_provider,
            apple_fm_timeout_seconds=_bounded_int(
                "HOGUE_APPLE_FM_TIMEOUT_SECONDS",
                default=90,
                minimum=5,
                maximum=180,
            ),
            apple_fm_max_prompt_chars=_bounded_int(
                "HOGUE_APPLE_FM_MAX_PROMPT_CHARS",
                default=12_000,
                minimum=1_000,
                maximum=30_000,
            ),
            openai_timeout_seconds=_bounded_float(
                "HOGUE_OPENAI_TIMEOUT_SECONDS",
                default=30.0,
                minimum=5.0,
                maximum=60.0,
            ),
            openai_max_retries=_bounded_int(
                "HOGUE_OPENAI_MAX_RETRIES",
                default=2,
                minimum=0,
                maximum=3,
            ),
            openai_max_output_tokens=_bounded_int(
                "HOGUE_OPENAI_MAX_OUTPUT_TOKENS",
                default=4_000,
                minimum=500,
                maximum=8_000,
            ),
            bind_host=bind_host,
        )


def is_loopback_host(host: str | None) -> bool:
    if not host:
        return False
    normalized = host.strip().strip("[]").rstrip(".").casefold()
    if normalized == "localhost":
        return True
    try:
        return ipaddress.ip_address(normalized.split("%", 1)[0]).is_loopback
    except ValueError:
        return False


def _bounded_int(name: str, *, default: int, minimum: int, maximum: int) -> int:
    try:
        value = int(os.getenv(name, str(default)))
    except ValueError:
        value = default
    return max(minimum, min(maximum, value))


def _bounded_float(name: str, *, default: float, minimum: float, maximum: float) -> float:
    try:
        value = float(os.getenv(name, str(default)))
    except ValueError:
        value = default
    return max(minimum, min(maximum, value))


settings = Settings.from_environment()
