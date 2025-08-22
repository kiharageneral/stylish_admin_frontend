import time
import logging
from django.conf import settings
from ai_agents.services.chat_agent import RateLimitExceededError, ChatContext
from collections import defaultdict, deque
from .redis_manager import redis_manager
import asyncio
from typing import Dict, List

logger = logging.getLogger(__name__)


class RateLimiter:
    """Rate limiter"""

    def __init__(self):
        self.rate_limit_per_minute = getattr(settings, "CHAT_RATE_LIMIT_PER_MINUTE", 10)
        self.rate_limit_per_hour = getattr(settings, "CHAT_RATE_LIMIT_PER_HOUR", 100)

        self._fallback_cache: Dict[str, deque] = defaultdict(lambda: deque(maxlen=1000))
        self._redis_available = True
        self._last_redis_check = 0
        self._redis_check_interval = 30
        self._redis_failure_count = 0
        self._max_redis_failures = 3
        self._redis_circuit_open_until = 0
        self._circuit_timeout = 60

    async def check_limits(self, context: ChatContext):
        """Check rate limits with redis"""
        if self._should_try_redis():
            try:
                await self._check_redis_limits(context)
                return
            except Exception as e:
                self._on_redis_failure(e, context)

        await self._check_fallback_limits(context)

    def _should_try_redis(self) -> bool:
        """Determine if we should attempt Redis operations"""
        current_time = time.time()

        if self._redis_circuit_open_until > current_time:
            return False

        if current_time - self._last_redis_check > self._redis_check_interval:
            return True

        return self._redis_available

    def _on_redis_success(self):
        """Called when Redis operation succeeds"""
        self._redis_available = True
        self._redis_failure_count = 0
        self._redis_circuit_open_until = 0
        self._last_redis_check = time.time()

    def _on_redis_failure(self, error: Exception, context: ChatContext):
        """Called when Redis operation fails"""
        self._redis_failure_count += 1
        self._last_redis_check = time.time()

        logger.warning(
            f"Redis rate limiting failed for user {context.user_id} (failure # {self._redis_failure_count}): {str(error)}"
        )

        if self._redis_failure_count >= self._max_redis_failures:
            self._redis_available = False
            self._redis_circuit_open_until = time.time() + self._circuit_timeout

            logger.warning(
                f"Redis circuit breaker opened for {self._circuit_timeout}s after {self._redis_failure_count} consecutive failures"
            )

    async def _check_redis_limits(self, context: ChatContext):
        """Check rate limits using Redis with timeout protection"""
        try:
            await asyncio.wait_for(self._redis_rate_limit_check(context), timeout=5.0)

        except asyncio.TimeoutError:
            raise Exception("Redis operation timed out")

    async def _redis_rate_limit_check(self, context: ChatContext):
        """Actual Redis rate limiting logic"""
        async with redis_manager.get_connection() as redis_client:
            current_time = int(time.time())

            minute_key = f"rate_limit:min:{context.rate_limit_key}:{current_time//60}"
            hour_key = f"rate_limit:hour:{context.rate_limit_key}:{current_time//3600}"

            async with redis_client.pipeline(transaction=True) as pipe:
                try:
                    await pipe.watch(minute_key, hour_key)

                    current_minute = await redis_client.get(minute_key)
                    current_hour = await redis_client.get(hour_key)

                    minute_count = int(current_minute) if current_minute else 0
                    hour_count = int(current_hour) if current_hour else 0

                    if minute_count >= self.rate_limit_per_minute:
                        raise RateLimitExceededError(
                            f"Rate limit exceeded: {minute_count}/{self.rate_limit_per_minute} requests per minute"
                        )

                    if hour_count >= self.rate_limit_per_hour:
                        raise RateLimitExceededError(
                            f"Rate limit exceeded : {hour_count}/{self.rate_limit_per_hour} requests per hour"
                        )

                    # start transaction
                    pipe.multi()

                    pipe.incr(minute_key)
                    pipe.expire(minute_key, 60)
                    pipe.incr(hour_key)
                    pipe.expire(hour_key, 3600)

                    await pipe.execute()
                except Exception as e:
                    await pipe.discard()
                    raise e

    async def _check_fallback_limits(self, context: ChatContext):
        """Fallback rate limiting with time-based cleanup"""
        now = time.time()
        key = context.rate_limit_key

        request_times = self._fallback_cache[key]

        cutoff_time = now - 3600
        while request_times and request_times[0] < cutoff_time:
            request_times.popleft()

        # count recent requests
        minute_cutoff = now - 60
        minute_requests = sum(1 for t in request_times if t >= minute_cutoff)
        hour_requests = len(request_times)

        # check minute limit
        if minute_requests >= self.rate_limit_per_minute:
            raise RateLimitExceededError(
                f"Rate limit exceeded : {minute_requests}/{self.rate_limit_per_minute} requests per minute (fallback)"
            )

        # Check hour limit
        if hour_requests >= self.rate_limit_per_hour:
            raise RateLimitExceededError(
                f"Rate limit exceeded : {hour_requests}/ {self.rate_limit_per_hour} requests per hour (fallback)"
            )

        # Record this request
        request_times.append(now)

    async def get_current_usage(self, context: ChatContext) -> dict:
        """Get current rate limit usage with enhanced error handling"""
        if self._should_try_redis():
            try:
                usage = await asyncio.wait_for(
                    self._get_redis_usage(context), timeout=3.0
                )
                self._on_redis_success()
                return usage
            except Exception as e:
                self._on_redis_failure(e, context)

        return self._get_fallback_usage(context)

    async def _get_redis_usage(self, context: ChatContext) -> dict:
        """Get usage from Redis with proper error handling"""
        async with redis_manager.get_connection() as redis_client:
            current_time = int(time.time())
            minute_key = f"rate_limit:min:{context.rate_limit_key}:{current_time//60}"
            hour_key = f"rate_limit:hour:{context.rate_limit_key}:{current_time//3600}"

            async with redis_client.pipeline() as pipe:
                pipe.get(minute_key)
                pipe.get(hour_key)
                results = await pipe.execute()

            minute_count = int(results[0] or 0)
            hour_count = int(results[1] or 0)

            return {
                "minute_usage": minute_count,
                "minute_limit": self.rate_limit_per_minute,
                "minute_remaining": max(0, self.rate_limit_per_minute - minute_count),
                "hour_usage": hour_count,
                "hour_limit": self.rate_limit_per_hour,
                "hour_remaining": max(0, self.rate_limit_per_hour - hour_count),
                "source": "redis",
                "circuit_breaker_status": "closed" if self._redis_available else "open",
            }

    def _get_fallback_usage(self, context: ChatContext) -> dict:
        """Get usage from fallback cache with cleanup"""
        now = time.time()
        key = context.rate_limit_key

        request_times = self._fallback_cache.get(key, deque())

        # Clean old entries
        cutoff_time = now - 3600
        while request_times and request_times[0] < cutoff_time:
            request_times.popleft()

        minute_cutoff = now - 60
        minute_requests = sum(1 for t in request_times if t >= minute_cutoff)
        hour_requests = len(request_times)

        return {
            "minute_usage": minute_requests,
            "minute_limit": self.rate_limit_per_minute,
            "minute_remaining": max(0, self.rate_limit_per_minute - minute_requests),
            "hour_usage": hour_requests,
            "hour_limit": self.rate_limit_per_hour,
            "hour_remaining": max(0, self.rate_limit_per_hour - hour_requests),
            "source": "fallback",
            "circuit_breaker_status": (
                "open" if self._redis_circuit_open_until > now else "closed"
            ),
            "redis_failures": self._redis_failure_count,
        }

    async def reset_user_limits(self, context: ChatContext) -> bool:
        """Reset rate limits for a user (admin operation)"""
        if self._should_try_redis():
            try:
                await self._reset_redis_limits(context)
                return True
            except Exception as e:
                logger.error(f"Failed to reset Redis limits: {str(e)}")

        key = context.rate_limit_key
        if key in self._fallback_cache:
            self._fallback_cache[key].clear()

        return True

    async def _reset_redis_limits(self, context: ChatContext):
        """Reset Redis rate limits for a user"""
        async with redis_manager.get_connection() as redis_client:
            current_time = int(time.time())
            # Delete current minute and hour keys

            keys_to_delete = [
                f"rate_limit:min:{context.rate_limit_key}:{current_time//60}",
                f"rate_limit:hour:{context.rate_limit_key}:{current_time//3600}",
            ]

            if keys_to_delete:
                await redis_client.delete(*keys_to_delete)

    def get_circuit_breaker_status(self) -> dict:
        """Get circuit breaker status for monitoring"""
        current_time = time.time()
        return {
            "redis_available": self._redis_available,
            "failure_count": self._redis_failure_count,
            "max_failures": self._max_redis_failures,
            "circuit_open_until": self._redis_circuit_open_until,
            "circuit_open": self._redis_circuit_open_until < current_time,
            "seconds_until_retry": self._redis_circuit_open_until - current_time,
            "last_check": self._last_redis_check,
            "fallback_cache_size": len(self._fallback_cache),
        }
