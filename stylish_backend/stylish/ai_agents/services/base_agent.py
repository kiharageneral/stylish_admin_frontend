from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional
from ai_agents.models import Agent, AgentExecution, AgentRecommendation
import openai
import json
import logging
from datetime import datetime
from django.conf import settings
from django.utils import timezone
from django.contrib.contenttypes.models import ContentType
from asgiref.sync import async_to_sync
from ai_agents.mcp_server.services import handle_mcp_message

logger = logging.getLogger(__name__)


class BaseAgent(ABC):
    """Base class for all AI agents with complete error handling and execution tracking"""

    def __init__(self, agent_model: "Agent"):
        self.agent_model = agent_model
        self.client = openai.OpenAI(
            base_url=settings.OPENROUTER_BASE_URL,
            api_key=settings.OPENROUTER_API_KEY,
        )
        self.model = getattr(
            settings, "DEEPSEEK_MODEL", "deepseek/deepseek-r1-0528:free"
        )
        self.excution_record = None

    def call_mcp_tool(
        self, tool_name: str, arguments: Dict[str, Any]
    ) -> Dict[str, Any]:
        """contructs and executes a 'tools/call' request to the central MCP server. Handles the sync-to-async"""
        logger.info(
            f"Agent '{self.agent_model.name}' calling MCP tool '{tool_name}'..."
        )

        # 1. Contruct the MCP request message
        mcp_request = {
            "jsonrpc": "2.0",
            "method": "tools/call",
            "params": {"name": tool_name, "arguments": arguments},
            "id": f"agent-{self.agent_model.id} - {timezone.now().timestamp()}",
        }

        try:
            # 2. Call the async message handler from our sync code
            response = async_to_sync(handle_mcp_message)(mcp_request)

            # 3. process the response
            if "error" in response:
                error_info = response["error"]
                logger.error(f"MCP tool call failed: {error_info.get('message')}")
                return {"error": f"Tool call failed: {error_info.get('message')}"}
            tool_content_str = (
                response.get("result", {}).get("content", [{}])[0].get("text", "{}")
            )
            return self.safe_json_parse(tool_content_str)

        except Exception as e:
            logger.error(
                f"Critical error calling MCP tool '{tool_name}' : {str(e)}",
                exc_info=True,
            )
            return {"error": f"Failed to communicate with MCP server: {str(e)}"}

    def start_execution(self, input_data: Dict[str, Any] = None) -> "AgentExecution":
        """Start tracking agent execution"""
        self.excution_record = AgentExecution.objects.create(
            agent=self.agent_model,
            status="running",
            input_data=input_data or {},
            started_at=timezone.now(),
        )
        return self.excution_record

    def complete_execution(
        self, output_data: Dict[str, Any] = None, execution_time: float = None
    ):
        """Complete agent execution tracking"""
        if self.excution_record:
            self.excution_record.status = "completed"
            self.excution_record.output_data = output_data or {}
            self.excution_record.completed_at = timezone.now()
            if execution_time:
                self.excution_record.execution_time = execution_time
            self.excution_record.save()

            self.agent_model.last_execution = timezone.now()
            self.agent_model.save()

    def fail_execution(self, error_message: str):
        """Mark execution as failed"""
        if self.excution_record:
            self.excution_record.status = "failed"
            self.excution_record.error_message = error_message
            self.excution_record.completed_at = timezone.now()
            self.excution_record.save()

    @abstractmethod
    def analyze(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze data and return insights"""

        pass

    @abstractmethod
    def generate_recommendations(
        self, analysis: Dict[str, Any]
    ) -> List[Dict[str, Any]]:
        """Generate actionable recommendations"""
        pass

    def execute_llm_task(
        self,
        prompt: str,
        system_prompt: str = None,
        temperature: float = 0.7,
        max_tokens: int = 2000,
    ) -> str:
        """Execute LLM task with comprehensive error handling"""
        try:
            messages = []
            if system_prompt:
                messages.append({"role": "system", "content": system_prompt})
            messages.append({"role": "user", "content": prompt})

            # Add OpenRouter specific headers
            extra_headers = {
                "HTTP-Referer": getattr(settings, "SITE_URL", ""),
                "X-Title": getattr(settings, "COMPANY_NAME", ""),
            }

            response = self.client.chat.completions.create(
                model=self.model,
                messages=messages,
                temperature=temperature,
                max_tokens=max_tokens,
                extra_headers=extra_headers,
            )

            return response.choices[0].message.content

        except openai.RateLimitError as e:
            logger.error(f"OpenAI rate limit exceeded : {str(e)}")
            raise Exception("AI service temporarily unavailable due to high demand")
        except openai.AuthenticationError as e:
            logger.error(f"OpenAI authentication failed: {str(e)}")
            raise Exception("AI service authentication failed")
        except openai.APIError as e:
            logger.error(f"OpenAI API error: {str(e)}")
            raise Exception(f"AI service error: {str(e)}")
        except Exception as e:
            logger.error(f"Unexpected error in LLM execution: {str(e)}")
            raise Exception(f"AI analysis failed: {str(e)}")
        
    def create_recommendation(self,rec_type: str, title: str, description : str, priority: str = 'medium', data: dict = None, related_object = None, confidence: float = 0.0, estimated_impact: Dict=None)-> 'AgentRecommendation':
        """Create a recommendation record with full data"""
        content_type = None
        object_id = None
        if related_object:
            content_type = ContentType.objects.get_for_model(related_object)
            object_id = str(related_object.pk)
            
        return AgentRecommendation.objects.create(
            agent = self.agent_model,
            recommendation_type = rec_type, 
            title = title, 
            description = description, 
            priority = priority, 
            data = data or {}, 
            content_type = content_type, 
            object_id= object_id, 
            confidence_score = confidence, 
            estimated_impact = estimated_impact or {}
        )

    def safe_json_parse(self, json_string: str, fallback: Dict = None) -> Dict:
        """Safely parse JSON with fallback"""
        try:
            return json.loads(json_string)
        except json.JSONDecodeError as e:
            logger.warning(f"Failed to parse JSON from LLM: {str(e)}")
            return fallback or {
                "error": "Failed to parse AI response",
                "raw_response": json_string,
            }
    def validate_config(self)-> bool:
        """Validate agent configuration for OpenRouter"""
        if not settings.OPENROUTER_API_KEY or settings.OPENROUTER_API_KEY == '<YOUR_OPENROUTER_API_KEY>':
            raise Exception("OpenRouter API key not configured")
        
        if not self.agent_model.is_active:
            raise Exception(f"Agent {self.agent_model.name} is not active")
        
        return True