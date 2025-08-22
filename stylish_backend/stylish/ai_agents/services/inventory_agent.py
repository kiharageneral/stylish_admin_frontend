from typing import Any, Dict, List
from .base_agent import BaseAgent
from datetime import datetime
import json
from ai_agents.utils.encoders import CustomJSONEncoder


class InventoryManagementAgent(BaseAgent):
    """Agent for intelligent inventory management, using MCP for data access"""

    def analyze(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze inventory data by calling the 'get_inventory_status' MCP tool"""
        # 1. call the MCP tool to get structured inventory data
        inventory_data = self.call_mcp_tool(
            tool_name="get_inventory_status",
            arguments={"alert_level": "all", "include_recommendations": True},
        )

        if "error" in inventory_data:
            self.fail_execution(error_message=inventory_data["error"])
            return {"error": inventory_data["error"]}
        # 2. Use the structured data from the tool to prompt the LLM for high-level insights
        prompt = f"""
        Analyze this structured inventory status report and provide insights:
        {json.dumps(inventory_data, indent=2)}
        Please provide:
        1. Key inventory patterns and trends (e.g., most common out-of-stock category). 
        2. A risk assessment based on the alerts (e.g., "High ristk of stockout for top-selling items").
        3. Recommendations for optimization beyond simple restocking (e.g., "Adjust low_stock_threshold for seasonal items")
        
        Format the response as JSON with keys: patterns, risks, optimization_suggestions. 
        """

        system_prompt = """You are an expert inventory analyst. Analyze the provided structured inventory report and provide actionable insights in JSON format"""

        llm_response = self.execute_llm_task(prompt, system_prompt)
        llm_insights = self.safe_json_parse(llm_response)

        return {
            "raw_data": inventory_data,
            "llm_insights": llm_insights,
            "analysis_timestamp": datetime.now().isoformat(),
        }

    def generate_recommendations(
        self, analysis: Dict[str, Any]
    ) -> List[Dict[str, Any]]:
        """Generate inventory recommendations based on tool data and LLM insights"""
        recommendations = []
        raw_data = analysis.get("raw_data", {})
        # Use the pre-computed recommendations fromt the tool for direct actions
        if "recommendations" in raw_data:
            for rec_data in raw_data["recommendations"]:
                product_id = rec_data.get("product_id")
                product_name = rec_data.et("product_name", "Unknown Product")

                rec = self.create_recommendation(
                    rec_type="restock",
                    title=f"Restock {product_name}",
                    description=f"Stock is low or out. Recommended reorder: {rec_data.get('recommended_quantity', 0)} units",
                    priority=rec_data.get("priority", "medium"),
                    data=rec_data,
                    confidence=0.95,
                )

                recommendations.append(rec)

        # Use LLM insights for more strategic recommendations
        llm_insights = analysis.get("llm_insights", {})
        if "optimization_suggestions" in llm_insights:
            for suggestion in llm_insights["optimization_suggestions"]:
                rec = self.create_recommendation(
                    rec_type="inventory_optimization",
                    title="Inventory Optimization Suggestion",
                    description=suggestion,
                    priority="medium",
                    data={"source": "llm_analysis"},
                    confidence=0.7,
                )

                recommendations.append(rec)

        return recommendations
