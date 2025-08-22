from dataclasses import dataclass
from typing import List, Optional
from django.conf import settings

@dataclass
class ChatAgentConfig:
    # Rate limiting
    rate_limit_per_minute: int = 10
    rate_limit_per_hour : int = 100
    
    # caching
    cache_ttl : int = 300
    
    # Query limits
    max_query_length : int = 1000
    
    # API settings
    api_timeout:float = 30.0
    api_max_retries : int = 3
    api_model: str = 'deepseek/deepseek-r1-0528:free'
    
    # Circuit breaker 
    circuit_breaker_failure_threshold : int = 5
    circuit_breaker_recovery_timeout : int = 60
    
    # Redis
    redis_max_connections : int = 20
    redis_retry_on_timeout: bool = True
    
    # security
    blocked_patterns: List[str] = None
    sensitive_keywords : List[str] = None
    
    def __post_init__(self):
        if self.blocked_patterns is None:
            self.blocked_patterns = [
                r'(?i)(delete|drop|truncate)\s+table', 
                 r'(?i)union\s+select', 
                 r'(?i)<script.*?>', 
                 r'(?i)javascript:', 
                 r'(?i)data:text/html', 
                 r'(?i)exec\s*\(', 
                 r'(?i)eval\s*\(', 
                 r'(?i)import\s+os', 
                 r'(?i)__import__'
                 
            ]
        if self.sensitive_keywords is None:
            self.sensitive_keywords = [
                'password', 'secret', 'token', 'key', 'credential', 
                'api_key', 'private_key', 'auth_token'
            ]
            
        
def get_chat_config()-> ChatAgentConfig:
    """Factory function to create configuration from Django settings"""
    return ChatAgentConfig(
        rate_limit_per_minute=getattr(settings, 'CHAT_RATE_LIMIT_PER_MINUTE', 10), 
        rate_limit_per_hour= getattr(settings, 'CHAT_RATE_LIMIT_PER_HOUR', 100), 
        cache_ttl= getattr(settings, 'CHAT_CACHE_TTL', 300),
        max_query_length=getattr(settings, 'CHAT_MAX_QUERY_LENGTH', 1000), 
        api_timeout= getattr(settings, 'OPENAI_TIMEOUT', 30.0), 
        api_max_retries=getattr(settings, 'OPENAI_MAX_RETRIES', 3), 
        api_model= getattr(settings, 'DEEPSEEK_MODEL', 'deepseek/deepseek-r1-0528:free'), 
        circuit_breaker_failure_threshold=getattr(settings, 'CIRCUIT_BREAKER_FAILURE_THRESHOLD', 5), 
        circuit_breaker_recovery_timeout=getattr(settings, 'CIRCUIT_BREAKER_RECOVERY_TIMEOUT', 60), 
        redis_max_connections=getattr(settings, 'REDIS_MAX_CONNECTIONS', 20), 
        
    )