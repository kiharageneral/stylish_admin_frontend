import hashlib
import logging
from typing import Optional
from asgiref.sync import sync_to_async
from django.core.cache import cache
from django.conf import settings

from ai_agents.services.chat_agent import ChatResponse

logger = logging.getLogger(__name__)

class CacheManager:
    """Handles all caching logic for chat responses"""
    def __init__(self):
        self.cache_ttl = getattr(settings, 'CHAT_CACHE_TTL', 300)
        
    def generate_key(self, query:str, context)-> str:
        """Generates a consistent, permission-aware cache key. Permissions are included so users with different access levels don't see the same chace data"""
        key_data = f"{query.strip().lower()}:{':'.join(sorted(context.user_permissions))}"
        return f"chat_cache:{hashlib.md5(key_data.encode()).hexdigest()}"
    
    async def get(self, cache_key: str)-> Optional[ChatResponse]:
        """Asynchronously gets a response from the cache"""
        try:
            cached_data = await sync_to_async(cache.get)(cache_key)
            if cached_data:
                logger.info(f"Cache HIT for key: {cache_key}")
                return ChatResponse(**cached_data)
            logger.info(f"Cache MISS for key: {cache_key}")
            return None
        except Exception as e:
            logger.error(f"Cache retrieval error for key {cache_key}: {str(e)}")
            return None
        
    async def set(self, cache_key: str, response: ChatResponse):
        """Asynchronously sets a response in the cache."""
        try:
            cache_data = {
                'query': response.query, 
                'intent': response.intent, 
                'response': response.response, 
                'data': response.data, 
                'timestamp': response.timestamp, 
                'execution_time': response.execution_time, 
                'confidence_score': response.confidence_score, 
                'session_id': response.session_id, 
                'error': response.error
            }
            
            await sync_to_async(cache.set)(cache_key, cache_data, self.cache_ttl)
            logger.info(f"Cached response for key: {cache_key}")
            
        except Exception as e:
            logger.error(f"Cache storage error for key {cache_key} : {str(e)}")
            
            
    async def delete(self, cache_key:str):
        """Asynchronously deletes a cache entry."""
        try:
            await sync_to_async(cache.delete)(cache_key)
            logger.info(f"Deleted cache key: {cache_key}")
        except Exception as e:
            logger.error(f"Cache deletion error for key {cache_key}: {str(e)}")
            
    async def clear_user_cache(self, user_id: int):
        """Clear all cache entries for a specific user """
        try:
            logger.info(f"Cache clear requested for user {user_id} (not implemented for default cache backend)")
        except Exception as e:
            logger.error(f"Cache clear error for user {user_id} : {str(e)}")
            