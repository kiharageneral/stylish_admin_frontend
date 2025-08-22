from ai_agents.utils.encoders import CustomJSONEncoder
from .circuit_breaker import CircuitBreaker
from .config import get_chat_config
from django.conf import settings
from openai import AsyncOpenAI
from ai_agents.services.chat_agent import QueryIntent, ChatContext
import logging
import json

logger = logging.getLogger(__name__)

class ResponseGenerator:
    def __init__(self, client: AsyncOpenAI, model: str, config: dict):
        self.client = client
        self.config = config
        self.model = model
        self.api_headers = {
            'HTTP-Refereer': getattr(settings, 'SITE_URL', 'http://localhost'), 
            'X-Title': getattr(settings, 'COMPANY_NAME', 'Stylish'),
            
        }
        self.circuit_breaker = CircuitBreaker(
            failure_threshold=self.config.circuit_breaker_failure_threshold,
            recovery_timeout= self.config.circuit_breaker_recovery_timeout
        )
        
    async def classify_intent(self, query:str) -> QueryIntent:
        """Classify intent using a JSON mode. This forces the LLM to return a scructured response"""
        try:
            return await self.circuit_breaker.call(self._classify_intent_internal, query)
        except Exception as e:
            logger.error(f"Intent classification failed catastrophically: {str(e)}")
            return QueryIntent.GENERAL_STATS
        
    async def _classify_intent_internal(self, query: str)-> QueryIntent:
        intent_description = {
            intent.value: intent.value.replace('_', ' ').title() for intent in QueryIntent
        }
        
        prompt = f"""
        You are an expert e-commerce analytics query classifier. Your task is to analyze the user's query and classify it into one the predefined intents. You must respond in JSON format.
        Available intents:
        {json.dumps(intent_description,indent=2)}
        
        Analyze the following user query and determine the single most appropriate intent.
        ----
        Examples:
        1. Query: "How many black t-shirts do we have in stock?"
            Corrent Intent : "inventory_status"  
        2. Query: "what wer our total sales last month?"
            Corrent Intent: "sales_data"  
        3. Query: "Who are our top 10 customers by spending?" 
            Correct Intent: "customer_insights"  
        4. Query: "show me our revenue for Q2" 
            Correct Intent: "revenue_analysis"  
        ----
        User Query to classify:
        "{query}"  
        Respond with a JSON object containing a single key "intent". 
        Example Response Format:
        {{
            "intent": "sales_data"
        }}
        """
        
        try:
            response = await self.client.chat.completions.create(
                model = self.model, 
                response_format={"type": "json_object"}, 
                messages= [
                    {"role": "system", "content": "You aare an expert intent classifier..."}, 
                    {"role": "user", "content": prompt}
                ], 
                temperature= 0.0, 
                max_tokens=150, 
                extra_headers= self.api_headers
            )
            
            result = json.loads(response.choices[0].message.content)
            intent_str = result.get("intent")
            
            if not intent_str:
                logger.warning(f"LLM returned valid JSON but no intent key for query:{query} ")
                return QueryIntent.GENERAL_STATS
            
            return QueryIntent(intent_str)
        except (json.JSONDecodeError, KeyError, ValueError) as e:
            logger.error(f"Failed to parse or map intent from LLM response: {str(e)}")
            return QueryIntent.GENERAL_STATS
        
        except Exception as e:
            logger.error(f"Unexpected error during intent classification LLM call: {str(e)}")
            raise
        
    async def generate_response(self, query: str, intent: QueryIntent, data: dict, context: ChatContext)-> str:
        """Generate a structured JSON response, not just text. """
        try:
            response_json = await self.circuit_breaker.call(
                self._generate_response_internal, query, intent, data, context
            )
            return json.dumps(response_json, cls = CustomJSONEncoder)
        except Exception as e:
            logger.error(f"Response generation failed: {str(e)}")
            error_response = {
                "narrative": "I apologize , but I'm having trouble generating a response right now. Please try again.", 
                "data": None, 
                "ui_components": []
            }
            return json.dumps(error_response, cls=CustomJSONEncoder)
        
    async def _generate_response_internal(self, query: str, intent: QueryIntent, data: dict, context: ChatContext)->dict:
        if 'error' in data:
            return {
                "narrative": f"I encountered an issue retrieving the data: {data['error']}. Please try rephrasing your question", 
                "data": data, 
                "ui_components": []
            }
            
        data_summary = self._format_data_for_prompt(data)
        
        system_prompt = """
        You are a world-class e-commerce analytics assistant. Your role is to transform raw data into clear, actionable, and structured JSON response for a business intelligence dashboard. 
        
        You must respond with a JSON object with three keys: "narrative", "data", and "ui_components". 
        1. 'narrative': A concise (2-4 sentences) summary of the key insights from the data. Be conversational but professional. 
        2. 'data': The raw or processed data used for the narrative. This should be a JSON object or arrary. 
        3. 'ui_components': An array of suggested UI components to visualize the data. Valid types are "table", "bar_chart", "line_chart", "kpi".
        
            - For "table", include 'headers' (an array of strings) and 'rows' (an array of arrays). 
            - for "bar_chart" or "line_chart", include 'x_axis_key' and 'y_axis_key' that correspond to keys in the 'data' object. 
            - For 'kpi', include a 'label' and a 'value_key' corresponding to a key in the 'data' object
            
        Always base your response on the provided data.if data is missing or incomplete , acknowledge this limitation in the narrative. 
        """
        
        user_prompt = f"""
        Based on the following e-commerce data , Please answer the user's question. 
        User Question: "{query}"
        Classified Intent: {intent.value}
        Data provided:
        '''json
        {data_summary}
        '''
        
        Generate the JSON response according to the system instructions
        """ 
        
        response = await self.client.chat.completions.create(
            model= self.model, 
            response_format={"type": "json_object"}, 
            messages= [
                {"role": "system", "content": system_prompt}, 
                {"role": "user", "content": user_prompt}
            ], 
            temperature= 0.3, 
            max_tokens=1500, 
            extra_headers=self.api_headers
        )
        
        try:
            return json.loads(response.choices[0].message.content)
        except json.JSONDecodeError:
            logger.error("Failed to parse JSON from response generateion LLM.")
            return {
                "narrative": "I generated a response , but it was formatted incorrectly. This may indicate a problem with the data provided.", 
                "data": {"raw_response": response.choices[0].message.content}, 
                "ui_components": []
            }
        
        
    def _format_data_for_prompt(self, data: dict)-> str:
        if not data:
            return "{}"
        return json.dumps(data, indent=2, cls=CustomJSONEncoder)