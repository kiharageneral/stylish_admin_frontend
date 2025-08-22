import redis.asyncio as aioredis
from django.conf import settings
import logging
import asyncio
from contextlib import asynccontextmanager
from typing import Optional, Dict, Any
import threading
from datetime import datetime 

logger = logging.getLogger(__name__)


class RedisManager:
    """Redis connection manager """
    _instance = None
    _lock = threading.Lock()
    
    def __new__(cls):
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super().__new__(cls)
                    cls._instance._initialized = False
        return cls._instance
    
    def __init__(self):
        if not hasattr(self, '_initialized') or not self._initialized:
            self._pools: Dict[int, aioredis.ConnectionPool] = {}
            self._clients : Dict[int, aioredis.Redis] = {}
            self._pool_lock = asyncio.Lock()
            self._initialized = True
            
            # Redis configuration
            self.redis_url = getattr(settings, 'REDIS_URL', 'redis://127.0.0.1:6379/1')
            self.max_connections = getattr(settings, 'REDIS_MAX_CONNECTIONS', 20)
            self.socket_timeout = getattr(settings, 'REDIS_SOCKET_TIMEOUT', 5)
            self.socket_connect_timeout = getattr(settings, 'REDIS_CONNECT_TIMEOUT', 5)
            self.health_check_interval = getattr(settings, 'REDIS_HEALTH_CHECK_INTERVAL', 30)
            
            self._creation_time = datetime.now()
            self._access_count  = 0
            
            logger.info(f"RedisManager initialized at {self._creation_time}")
            
    async def _get_loop_id(self)-> int:
        """Get the current loop ID for connection pooling"""
        try:
            loop = asyncio.get_running_loop()
            return id(loop)
        except RuntimeError:
            raise RuntimeError("Redis operations require an active event loop")
        
    async def _ensure_pool_for_loop(self, loop_id : int)-> aioredis.ConnectionPool:
        """Ensure we have a connection pool for the current event loop"""
        if loop_id not in self._pools:
            async with self._pool_lock:
                # Double-check pattern
                if loop_id not in self._pools:
                    try:
                        pool = aioredis.ConnectionPool.from_url(
                            self.redis_url, 
                            max_connections = self.max_connections, 
                            retry_on_timeout = True, 
                            socket_timeout = self.socket_timeout, 
                            socket_connect_timeout = self.socket_connect_timeout, 
                            health_check_interval = self.health_check_interval, 
                            encoding = 'utf-8', 
                            decode_responses = True
                        )
                        
                        test_client = aioredis.Redis(connection_pool= pool)
                        await test_client.ping()
                        await test_client.aclose()
                        
                        self._pools[loop_id] = pool
                        logger.info(f"Created Redis pool for event loop {loop_id}")
                    except Exception as e:
                        logger.error(f"Failed to create Redis pool for loop {loop_id} : {str(e)}")
                        raise
                    
        return self._pools[loop_id]
    
    async def get_redis(self)-> aioredis.Redis:
        """Get Redis client for the current event loop"""
        loop_id = await self._get_loop_id()
        self._access_count += 1
        
        # Check if we already have a client for this loop
        if loop_id not in self._clients:
            try:
                pool = await self._ensure_pool_for_loop(loop_id)
                client = aioredis.Redis(connection_pool=pool)
                
                await client.ping()
                self._clients[loop_id] = client
                
                logger.debug(f"Created Redis client for loop {loop_id} (access# {self._access_count})")
                
            except Exception as e:
                logger.error(f"Failed to create Redis client for loop {loop_id}: {str(e)}")
                if loop_id in self._pools:
                    try: 
                        await self._pools[loop_id].aclose()
                    except Exception: 
                        pass 
                    del self._pools[loop_id]
                raise
        return self._clients[loop_id]
    
    
    @asynccontextmanager
    async def get_connection(self):
        """Context manager for Redis operations with comprehensive error handling"""
        max_retries = 3
        retry_count = 0
        redis_client = None
        
        while retry_count < max_retries:
            try:
                redis_client = await self.get_redis()
                await redis_client.ping()
                yield redis_client
                break 
            except asyncio.CancelledError:
                logger.warning("Redis operation was cancelled")
                raise
            except Exception as e:
                retry_count += 1
                error_msg = str(e).lower()
                
                logger.error(f"Redis operation error (attempt {retry_count}/ {max_retries}): {str(e)}")
                
                
                if any(keyword in error_msg for keyword in ['connection', 'closed', 'broken', 'timeout']):
                    await self._clean_current_loop()
                    
                    if retry_count < max_retries:
                        await asyncio.sleep(0.1 * retry_count)
                        continue
                    
                if retry_count >= max_retries:
                    raise Exception(f"Redis operation failed after {max_retries} attempts : {str(e)}" )
                
    async def _clean_current_loop(self):
        """Clean up Redis connections for the current event loop"""
        try:
            loop_id= await self._get_loop_id()
            
            if loop_id in self._clients:
                try:
                    await self._clients[loop_id].aclose()
                except Exception:
                    pass
                del self._clients[loop_id]
                
            if loop_id in self._pools:
                try:
                    await self._pools[loop_id].aclose()
                except Exception:
                    pass
                del self._pools[loop_id]
                
            logger.info(f"Cleaned up Redis connections for loop {loop_id}")
            
        except Exception as e:
            logger.warning(f"Error during Redis cleanup for current loop : {str(e)}")
            
    async def cleanup_all(self):
        """Clean up all Redis connections across all event loops"""
        try:
            for loop_id , client in list(self._clients.items()):
                try:
                    await client.aclose()
                except Exception:
                    pass
            self._clients.clear()
            
            for loop_id , pool in list(self._pools.items()):
                try:
                    await pool.aclose()
                except Exception:
                    pass
                
            self._pools.clear()
            
            logger.info("All Redis connections cleaned up")
            
        except Exception as e:
            logger.warning(f"Error during Redis cleanup: {str(e)}")
            
    async def health_check (self) -> Dict[str, Any]:
        """Comprehensive health check with detailed status"""
        try: 
            loop_id = await self._get_loop_id()
            start_time = asyncio.get_event_loop().time()
            
            async with self.get_connection() as redis_client:
                await redis_client.ping()
                
                test_key = f"health_check:{loop_id}:{start_time}"
                await redis_client.set(test_key, "test", ex = 10)
                value = await redis_client.get(test_key)
                await redis_client.delete(test_key)
                
                response_time = asyncio.get_event_loop().time() - start_time
                
                return {
                    'status': 'healthy', 
                    'response_time': round(response_time, 3), 
                    'loop_id': loop_id, 
                    'active_pools': len(self._pools), 
                    'active_clients': len(self._clients), 
                    'total_accesses': self._access_count, 
                    'manager_uptime': str(datetime.now() - self._creation_time), 
                    'test_successful': value == "test"
                }
                
        except Exception as e:
            return {
                'status': 'unhealthy', 
                'error': str(e), 
                'loop_id': await self._get_loop_id() if hasattr(self, '_get_loop_id') else 'unknown', 
                'active_pools': len(self._pools), 
                'active_clients': len(self._clients), 
                'total_accesses': self._access_count
            }
            
            
        
    async def get_stats(self) -> Dict[str, Any]:
        """Get Redis manager statistics"""
        try:
            loop_id = await self._get_loop_id()
            return {
                'current_loop_id': loop_id, 
                'total_pools': len(self._pools), 
                'total_clients': len(self._clients),
                'total_accesses': self._access_count, 
                'manager_uptime': str(datetime.now() - self._creation_time), 
                'redis_url': self.redis_url, 
                'max_connections_per_pool': self.max_connections 
                
            }
            
        except Exception as e:
            return {'error': str(e)}
        
# Global instance
redis_manager = RedisManager()