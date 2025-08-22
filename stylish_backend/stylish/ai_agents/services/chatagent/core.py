import time
import logging
import json
from typing import Any, Dict, List, AsyncGenerator
import uuid

from django.conf import settings
from django.utils import timezone
from asgiref.sync import sync_to_async

from ai_agents.utils.encoders import CustomJSONEncoder

from .validators import ChatValidator
from ai_agents.services.chatagent.rate_limiter import RateLimiter
from .data_fetcher import DataFetcher
from .response_generator import ResponseGenerator
from .cache_manager import CacheManager
from .analytics import AnalyticsTracker
from .exceptions import ChatValidationError, RateLimitExceededError, DataFetchingError

from ai_agents.models import ChatMessage as ChatMessageModel, ChatSession
from ai_agents.services.base_agent import BaseAgent
from ai_agents.services.chat_agent import (QueryIntent, ChatContext, ChatResponse)
from openai import AsyncOpenAI
from .config import get_chat_config


logger = logging.getLogger(__name__)

class ProductionChatAssistantAgent(BaseAgent):
    """This agent supports event streaming for a real-time UI experience"""
    
    def __init__(self, agent_model):
        super().__init__(agent_model)
        self.validator = ChatValidator()
        self.rate_limiter = RateLimiter()
        self.cache_manager = CacheManager()
        self.data_fetcher = DataFetcher()
        self.analytics = AnalyticsTracker()
        
        chat_config = get_chat_config()
        
        self.async_client = AsyncOpenAI(
            base_url=settings.OPENROUTER_BASE_URL, 
            api_key= settings.OPENROUTER_API_KEY, 
            timeout=chat_config.api_timeout, 
            max_retries=chat_config.api_max_retries
        )
        self.response_generator = ResponseGenerator(
            client= self.async_client, 
            model = chat_config.api_model, 
            config=chat_config
        )
        
    async def process_query_stream(self, query:str, context: ChatContext)-> AsyncGenerator[Dict[str, Any], None]:
        """Main query processing pipeline that yields events for real-time streaming"""
        start_time = time.time()
        
        async def yield_event(event_type: str, data: Any):
            """Helper to yield structured event."""
            yield {"event": event_type, "data": data}
        try:
            # 1. Validation and Sanitization
            sanitized_query = await self.validator.validate_and_sanitize(query, context)
            
            # 2. Rate Limiting
            await self.rate_limiter.check_limits(context)
            
            # 3. Cache Check (no streaming for cached responses, return immediately)
            cache_key = self.cache_manager.generate_key(sanitized_query, context)
            if cached_response_data:= await self.cache_manager.get(cache_key=cache_key):
                async for event in yield_event("final_response", cached_response_data.to_dict()):
                    yield event
                return 
            
            async for event in yield_event ("status_update", {"message": "Classifying query..."}):
                yield event
                
            
            # 4. Intent Classification
            intent = await self.response_generator.classify_intent(sanitized_query)
            async for event in yield_event("intent_classified", {"intent": intent.value}):
                yield event
                
            async for event in yield_event("status_update", {"message": f"Fetching data for : {intent.value.replace('_', ' ')}..."}):
                yield event
                
            # 5. Data fetching
            data = await self.data_fetcher.fetch_data(intent, sanitized_query, context)
            data_summary = f"{len(json.dumps(data, cls=CustomJSONEncoder))} bytes of data received"
            async for event in yield_event("data_fetched", {"data_summary": data_summary}):
                yield event
            
            async for event in yield_event("status_update", {"message": "Generating insights..."}):
                yield event
                
            # 6. Response Generation
            response_json_str = await self.response_generator.generate_response(sanitized_query, intent, data, context)
            
            response_dict = json.loads(response_json_str)
            
            execution_time = time.time() - start_time
            
            message_id= str(uuid.uuid4())
            
            chat_response = ChatResponse(
                query=query, 
                intent = intent, 
                response = response_dict.get('narrative', 'Response generated'), 
                data=response_dict, 
                timestamp=timezone.now(), 
                execution_time=execution_time, 
                confidence_score=self._calculate_confidence(data), 
                session_id=context.session_id, 
                message_id=message_id
            )
            
            # Yield the final, complete response object
            async for event in yield_event("final_response", chat_response.to_dict()):
                yield event
                
            # 7. Post-processing 
            await self._store_message_async(chat_response, context)
            
            await self.cache_manager.set(cache_key, chat_response.to_dict())
            await self.analytics.track_query(context, intent, execution_time)
            
        except (ChatValidationError, RateLimitExceededError, DataFetchingError) as e:
            logger.warning(f"User-facing error for user {context.user_id}: {str(e)}")
            async for event in yield_event ("error", {"message": str(e)}):
                yield event
                
        except Exception as e:
            logger.error(f"Critical error in chat pipeline for user {context.user_id}:{str(e)}", exc_info=True)
            async for event in yield_event("error", {"message": "An unexpected server error occurred"}):
                yield event
            
    async def process_query_async(self, query: str, context: ChatContext)-> ChatResponse:
        final_response_data = None
        
        async for event in self.process_query_stream(query, context):
            if event['event'] == 'final_response':
                final_response_data = event['data']
            elif event['event'] == 'error':
                return self._create_error_response(query, event['data']['message'], context)
            
        if final_response_data:
            return ChatResponse.from_dict(final_response_data)
        else:
            return self._create_error_response(query, "Failed to generate a response.", context)
        
        
    def _create_error_response(self, query: str, error_message: str, context: ChatContext)-> ChatResponse:
        """Constructs a standardized error response object"""
        return ChatResponse(
            query=query, 
            intent= QueryIntent.GENERAL_STATS, 
            response=error_message, 
            data = {"error": error_message}, 
            timestamp=timezone.now(), 
            execution_time=0.0, 
            confidence_score=0.0, 
            session_id=context.session_id, 
            error = error_message, 
            message_id=str(uuid.uuid4())
        )   
            
    def _calculate_confidence(self, data:dict)-> float:
        if not data  or 'error' in data:
            return 0.1
        score = 0.75 + (len(data)*0.05)
        return min(1.0, round(score, 2))
    

    async def _store_message_async(self, response: ChatResponse, context: ChatContext):
        """Stores the chat interaction in the database using async operations"""
        try:
            session, _ = await sync_to_async(ChatSession.objects.get_or_create)(session_id = context.session_id, defaults={'user_id': context.user_id})
            
            await sync_to_async(ChatMessageModel.objects.create)(
                id = response.message_id, 
                session = session, 
                query = response.query, 
                response = response.response, 
                metadata  = {'structured_response': response.data, 'user_permissions': context.user_permissions}, 
                intent= response.intent.value, 
                execution_time = response.execution_time, 
                confidence_score = response.confidence_score
            )
            
        except Exception as e:
            logger.error(f"Failed to store chat message for session {context.session_id}: {str(e)}")
            
    def analyze(self, data: Dict[str, Any])-> Dict[str, Any]:
        logger.info("Analyze method called but not implemented here")
        return {"analysis": "No analyis performed by this agent"}
    
    def generate_recommendations(self, analysis:Dict[str, Any])-> List[Dict[str, Any]]:
        logger.info('Generate recommendations method called but not implemented for productionchatassistanceagent')
        return []
        
            
