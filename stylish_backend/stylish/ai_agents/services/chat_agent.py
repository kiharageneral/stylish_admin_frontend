from enum import Enum
from dataclasses import asdict, dataclass, field
from datetime import datetime
from typing import Dict, Any, List, Optional
from django.utils import timezone


class QueryIntent(Enum):
    """Enumeration of all supported query intents for chat classification"""
    INVENTORY_STATUS = "inventory_status"
    SALES_DATA = 'sales_data'
    PRODUCT_PERFORMANCE = "product_performance"
    ORDER_STATUS = "order_status"
    CUSTOMER_INSIGHTS = "customer_insights"
    REVENUE_ANALYSIS = "revenue_analysis"
    GROWTH_TRENDS = "growth_trends"
    TOP_PRODUCTS = "top_products"
    USER_MANAGEMENT = "user_management"
    SYSTEM_HEALTH = "system_health"
    GENERAL_STATS = "general_stats"
    RECOMMENDATIONS_REQUEST= "recommendations_request"
    
    @classmethod
    def choices(cls):
        """Return Django model choices format."""
        return [(intent.value, intent.value.replace('-', ' ').title()) for intent in cls]
    
    @classmethod
    def get_display_name(cls, intent_value:str) -> str:
        """Get human-readable display name for intent"""
        try:
            intent = cls(intent_value)
            return intent.value.replace('-', ' ').title()
        except ValueError:
            return intent_value.replace('-', ' ').title()
        
@dataclass
class ChatContext:
    """Context object that carries user and session information throughout the chat processing pipeline."""
    user_id: str
    session_id : str
    user_permissions : List[str] = field(default_factory=list)
    rate_limit_key: str = ""
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def __post_init__(self):
        """Set default rate limit key if not provided"""
        if not self.rate_limit_key:
            self.rate_limit_key = f"user: {self.user_id}"
            
    def has_permission(self, permission: str)-> bool:
        """Check if user has specific permission"""
        return permission in self.user_permissions
    def get_metadata(self, key: str, default: Any = None) -> Any:
        """Get metadata value with fallback"""
        return self.metadata.get(key, default)
    def set_metadata(self, key:str, value: Any) -> None:
        """Set metadata value."""
        self.metadata[key] = value
        
        
    
@dataclass
class ChatResponse:
    """Standardized response object for all chat interactions. Contains both the response content and metadata about processing
    """
    
    query: str
    intent: QueryIntent
    response: str
    data: Dict[str, Any]
    timestamp: datetime
    execution_time: float
    confidence_score: float
    session_id: str
    message_id: str
    error: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def __post_init__(self):
        """Validate and normalize response data"""
        if not isinstance(self.timestamp , datetime):
            self.timestamp = timezone.now()
            
        self.confidence_score = max(0.0, min(1.0, self.confidence_score))
        self.execution_time = max(0.0, self.execution_time)
        
    @property
    def is_confident(self) -> bool:
        """Check if response has high confidence (>= 0.7)."""
        return self.confidence_score >= 0.7
    
    @property
    def is_successful(self)-> bool:
        """Check if response was successful (no error)"""
        
        return self.error is None
    
    def to_dict(self)-> Dict[str, Any]:
        """convert response to dictionary for serialization . """
        data  = asdict(self)
        
        data['intent'] = self.intent.value
        data['timestamp'] = self.timestamp.isoformat()
        
        return data
    
    @classmethod
    def from_dict(cls, data:Dict[str, Any]) -> 'ChatResponse':
        """Create ChatResponse from dictionary"""
        return cls(
            query = data['query'], 
            intent = QueryIntent(data['intent']), 
            response = data['response'], 
            data = data.get('data', {}), 
            timestamp = datetime.fromisoformat(data['timestamp']), 
            execution_time = data['execution_time'], 
            confidence_score = data['confidence_score'], 
            session_id = data['session_id'], 
            message_id = data['message_id'], 
            error = data.get('error'), 
            metadata = data.get('metadata', {})
        )
        
        
@dataclass
class QueryClassification:
    """Result of query intent classification"""
    intent : QueryIntent
    confidence: float
    alternative_intents : List[tuple[QueryIntent, float]] = field (default_factory=list)
    extracted_entities : Dict[str, Any]  = field (default_factory=dict)
    
    def __post_init__(self):
        """Validate classification data."""
        self.confidence = max(0.0, min(1.0, self.confidence))
        
        self.alternative_intents.sort(key = lambda x: x[1], reverse= True)
        
    @property
    def is_confident(self) -> bool:
        """Check if classification is confident (>= 0.6)"""
        return self.confidence >= 0.6
    
    @property
    def needs_clarification(self)-> bool:
        """check if query needs clarification (low confidence)"""
        return self.confidence < 0.4
    
    
@dataclass
class RateLimitStatus:
    """Rate limiting status information"""
    
    is_limited : bool
    remaining_requests: int
    reset_time = datetime
    limit_type : str
    
    @property
    def seconds_until_reset(self)-> int:
        """Get seconds until rate limit resets."""
        return max(0, int((self.reset_time - timezone.now()).total_seconds()))
    
    
class ChatAgentError(Exception):
    """Base exception for chat agent errors."""
    pass

class RateLimitExceededError(ChatAgentError):
    """Raised when rate limit is exceeded"""
    def __init__(self, status:RateLimitStatus):
        self.status = status
        super().__init__(f"Rate limit exceed. Reset in {status.seconds_until_reset}s")
        
class ChatValidationError(ChatAgentError):
    """Raised when chat input validation failse."""
    pass

class ChatProcessingError(ChatAgentError):
    """Raised when chat processing fails"""
    pass


# Type aliases for better code documentation
UserId  = str
SessionId = str
PermissionName = str
EntityName = str
EntityValue = Any
