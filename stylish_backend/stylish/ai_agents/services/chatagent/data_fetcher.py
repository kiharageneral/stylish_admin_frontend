import logging
from typing import Dict, Any

from ai_agents.services.chat_agent import QueryIntent, ChatContext
from .exceptions import DataFetchingError
from ai_agents.mcp_server.tools import EcommerceMCPTools

logger = logging.getLogger(__name__)


class DataFetcher:
    """Orchestrates data fetching by routing to MCP tools"""

    def __init__(self):
        self.mcp_tools = EcommerceMCPTools()

        # Map intents to MCP tool handers
        self.intent_handlers = {
            QueryIntent.INVENTORY_STATUS: self._handle_inventory_status,
            QueryIntent.SALES_DATA: self._handle_sales_data,
            QueryIntent.PRODUCT_PERFORMANCE: self._handle_product_performance,
            QueryIntent.ORDER_STATUS: self._handle_order_status,
            QueryIntent.CUSTOMER_INSIGHTS: self._handle_customer_insights,
            QueryIntent.REVENUE_ANALYSIS: self._handle_revenue_analysis,
            QueryIntent.GENERAL_STATS: self._handle_general_stats,
        }

    async def fetch_data(
        self, intent: QueryIntent, query: str, context: ChatContext
    ) -> Dict[str, Any]:
        """Routes data fetching to appropriate MCP tool handers"""
        handler = self.intent_handlers.get(intent)
        if not handler:
            logger.warning(f"No handler configured for intent: {intent.value}")
            return {"error": f"No handler for intent '{intent.value}'"}

        try:
            return await handler(query, context)
        except Exception as e:
            logger.error(
                f"Data fetching failed for intent {intent.value}: {str(e)}, ",
                exc_info=True,
            )
            raise DataFetchingError(f"Failed to fetch data for {intent.value}") from e

    async def _handle_inventory_status(
        self, query: str, context: ChatContext
    ) -> Dict[str, Any]:
        """Handle inventory status queries"""
        args = {"alert_level": "all", "include_recommendations": True}
        return await self.mcp_tools.handle_inventory_status(args)

    async def _handle_sales_data(
        self, query: str, context: ChatContext
    ) -> Dict[str, Any]:
        """Handle sales data queries"""
        period = self._extract_period_from_query(query)

        args = {
            "period": period,
            "metrics": ["revenue", "orders", "avg_order_value", "top_products"],
            "group_by": "day",
        }

        return await self.mcp_tools.handle_sales_analytics(args)

    async def _handle_product_performance(
        self, query: str, context: ChatContext
    ) -> Dict[str, Any]:
        """Handle product performance queries"""
        args = {"period": "30days", "metrics": ["top_products", "customer_segments"]}

        return await self.mcp_tools.handle_sales_analytics(args)

    async def _handle_order_status(
        self, query: str, context: ChatContext
    ) -> Dict[str, Any]:
        """Handle order status queries"""
        args = {"status": "all", "analytics": True}

        return await self.mcp_tools.handle_order_management(args)

    async def _handle_customer_insights(
        self, query: str, context: ChatContext
    ) -> Dict[str, Any]:
        """Handle customer insights queries"""
        args = {"segment": "all", "analysis_type": "behavior", "time_period": "90days"}

        return await self.mcp_tools.handle_customer_insights(args)

    async def _handle_revenue_analysis(
        self, query: str, context: ChatContext
    ) -> Dict[str, Any]:
        """Handle revenue analysis queries"""
        args = {"period": "30days", "metrics": ["revenue"], "group_by": "day"}

        return await self.mcp_tools.handle_sales_analytics(args)

    async def _handle_general_stats(
        self, query: str, context: ChatContext
    ) -> Dict[str, Any]:
        """Handle general statistics queries"""
        try:
            inventory_data = await self.mcp_tools.handle_inventory_status(
                {"alert_level": "all"}
            )
            sales_data = await self.mcp_tools.handle_sales_analytics(
                {"period": "30days", "metrics": ["revenue", "orders"]}
            )

            return {
                "message": "Here's your business overview",
                "inventory_summary": inventory_data.get("summary", {}),
                "sales_summary": {
                    "total_revenue": sales_data.get("revenue", {}).get("total", 0),
                    "total_orders": sales_data.get("orders", {}).get("total", 0),
                },
                "sugestions": [
                    "Show me inventory alerts",
                    "What are my top selling products?",
                    "Show me customer insights",
                    "Display order analytics",
                ],
            }

        except Exception as e:
            logger.error(f"Error in general stats: {str(e)}")
            return {
                "message": "I can provide information about sales, inventory, orders, customers, and revenue. What would you like to know?",
                "available_insights": [
                    "Sales Performance and trends",
                    "Inventory levels and stock status",
                    "Order management and tracking",
                    "Customer behavior and insights",
                    "Revenue analysis and forecasting",
                ],
            }

    def _extract_period_from_query(self, query: str) -> str:
        """Extract time period from query string"""
        query_lower = query.lower()

        if "today" in query_lower:
            return "today"
        elif "week" in query_lower or "7 days" in query_lower:
            return "7days"
        elif "month" in query_lower or "30 days" in query_lower:
            return "30days"
        elif "quarter" in query_lower or "90 days" in query_lower:
            return "90days"
        elif "year" in query_lower:
            return "1year"
        else:
            return "30days"
