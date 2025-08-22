from typing import Any, Dict, List
from .base_agent import BaseAgent
from datetime import datetime
import json
from ai_agents.utils.encoders import CustomJSONEncoder


class SalesAnalysisAgent(BaseAgent):
    """Agent for sales analysis and forecasting , using MCP for data access"""
    def analyze(self, data: Dict[str, Any])-> Dict[str, Any]:
        """Analyze sales data by calling the 'get_sales_analytics' MCP tool"""
        # 1. call the MCP tool to get sales data
        sales_data = self.call_mcp_tool(
            tool_name="get_sales_analytics", 
            arguments={
                "period": "30days", 
                "metrics": ["revenue", "orders", "top_products", "customer_segments"]
            }
        )
        
        if 'error' in sales_data:
            self.fail_execution(error_message=sales_data['error'])
            return {"error": sales_data['error']}
        
        # 2. Use the structured data from the tool to prompt the LLM
        prompt = f"""
        Analyze this structured sales report and provide insights:
        {json.dumps(sales_data, indent=2, cls = CustomJSONEncoder)}
        
        Provide:
        1. A concise sales performance assessment. 
        2. Key growth trends and patterns observed in the data. 
        3. Insights on top-performing products and top customer behavior. 
        4. Actionable revenue optimization opportunities based on the data
        5. A brief sales forecast insight for the next period. 
        
        Format as JSON wiht keys: performance , trends , product_insights, 
        optimization, forecast. 
        """
        
        system_prompt = """You are a sales analytics expert . Analyze a structured sales report and provide strategic insights in specified JSON format."""
        
        llm_response = self.execute_llm_task(prompt, system_prompt)
        llm_insights = self.safe_json_parse(llm_response)
        
        return {
            'raw_data': sales_data, 
            'llm_insights': llm_insights, 
            'analysis_timestamp': datetime.now().isoformat()
        }
        
    def generate_recommendations(self, analysis: Dict[str, Any])-> List[Dict[str, Any]]:
        """Generate sales optimization recommendations from LLM insights"""
        recommendations = []
        llm_insights = analysis.get('llm_insights', {})
        
        # Generate recommendations based on the LLM's optimization suggestions
        optimization_list = llm_insights.get('optimization', [])
        if isinstance(optimization_list, list):
            for suggestion in optimization_list:
                rec = self.create_recommendation(
                    rec_type= "marketing_campaign", 
                    title= 'Sales Optimization Opportunity', 
                    description=str(suggestion), 
                    priority='high', 
                    data = {'source': 'sales_analysis_llm'}, 
                    confidence=0.80
                )
                recommendations.append(rec)
                
        return recommendations
            
        
        