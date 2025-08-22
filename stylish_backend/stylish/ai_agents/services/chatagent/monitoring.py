import time
import logging
from dataclasses import dataclass
from typing import Dict, Optional
from django.conf import settings
from .redis_manager import RedisManager
from asgiref.sync import sync_to_async
from django.db import connection, close_old_connections
from .config import get_chat_config

logger = logging.getLogger(__name__)


@dataclass
class HealtStatus:
    service: str
    status: str
    response_time: float
    error: Optional[str] = None


def _perform_db_check():
    """Helper function to run the synchronous DB check"""
    try:
        close_old_connections()
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        connection.close()
        return None
    except Exception as e:
        return str(e)


class HealthChecker:
    def __init__(self):
        self.redis_manager = RedisManager()
        self.config = get_chat_config()

    async def check_all_services(self) -> Dict[str, HealtStatus]:
        checks = {
            "redis": self.check_redis(),
            "database": self.check_database(),
            "openai": self.check_openai(),
        }

        results = {}
        for service, check_coro in checks.items():
            try:
                results[service] = await check_coro
            except Exception as e:
                results[service] = HealtStatus(
                    service=service, status="unhealthy", response_time=0.0, error=str(e)
                )
        return results

    async def check_redis(self) -> HealtStatus:
        start_time = time.time()
        try:
            redis_client = await self.redis_manager.get_redis()
            await redis_client.ping()
            return HealtStatus(
                service="redis",
                status="healthy",
                response_time=time.time() - start_time,
            )

        except Exception as e:
            return HealtStatus(
                service="redis",
                status="unhealthy",
                response_time=time.time() - start_time,
                error=str(e),
            )

    async def check_database(self) -> HealtStatus:
        start_time = time.time()
        try:
            error = await sync_to_async(_perform_db_check, thread_sensitive=True)()

            if error:
                raise Exception(error)

            return HealtStatus(
                service="database",
                status="healthy",
                response_time=time.time() - start_time,
            )

        except Exception as e:
            return HealtStatus(
                service="database",
                status="unhealthy",
                response_time=time.time() - start_time,
                error=str(e),
            )

    async def check_openai(self) -> HealtStatus:
        start_time = time.time()

        try:
            from openai import AsyncOpenAI

            async with AsyncOpenAI(
                base_url=settings.OPENROUTER_BASE_URL,
                api_key=settings.OPENROUTER_API_KEY,
            ) as client:
                await client.chat.completions.create(
                    model=self.config.api_model,
                    messages=[{"role": "user", "content": "health check"}],
                    max_tokens=1,
                )
            return HealtStatus(
                service="openai",
                status="healthy",
                response_time=time.time() - start_time,
            )

        except Exception as e:
            return HealtStatus(
                service="openai",
                status="unhealthy",
                response_time=time.time() - start_time,
                error=str(e),
            )
