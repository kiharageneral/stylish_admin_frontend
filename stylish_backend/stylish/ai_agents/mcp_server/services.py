from .core import MCPServer
from .tools import EcommerceMCPTools
import logging

logger = logging.getLogger(__name__)


class MCPService:
    """Singleton service to manage the MCP server instance and its tools"""

    _instance = None

    def __new__(cls):
        if cls._instance is None:
            logger.info("Initializing MCP Service...")
            cls._instance = super(MCPService, cls).__new__(cls)

            # Initialize the MCP server
            cls._instance.server = MCPServer(
                name="E-commerce MCP Server", version="1.0"
            )

            cls._instance.server.initialized = True

            # Register all available tools
            cls._instance._register_tools()
            logger.info(
                f"MCP Service initialized with {len(cls._instance.server.tools)}"
            )

        return cls._instance

    def _register_tools(self):
        """Register all e-commerce tools with the server instance"""

        # Sales Analytics Tool
        self.server.register_tool(
            EcommerceMCPTools.get_sales_analytics_tool(),
            EcommerceMCPTools.handle_sales_analytics,
        )

        # Inventory Status Tool
        self.server.register_tool(
            EcommerceMCPTools.get_inventory_status_tool(),
            EcommerceMCPTools.handle_inventory_status,
        )

        # Customer Insights Tool
        self.server.register_tool(
            EcommerceMCPTools.get_customer_insights_tool(),
            EcommerceMCPTools.handle_customer_insights,
        )

        # Order management Tool
        self.server.register_tool(
            EcommerceMCPTools.get_order_management_tool(),
            EcommerceMCPTools.handle_order_management,
        )

        self.server.register_tool(
            EcommerceMCPTools.get_product_recommendations(),
            EcommerceMCPTools.handle_product_recommendations,
        )

        self.server.register_tool(
            EcommerceMCPTools.get_inventory_forecast_tool(),
            EcommerceMCPTools.handle_inventory_forecast,
        )
        
    def get_server(self)->MCPServer:
        """Return the configured MCPServer instance"""
        return self.server
        
        
        
# Create a single instance to be imported by other parts of the application
mcp_service = MCPService()

# Expose the handle_message method for convenience
handle_mcp_message = mcp_service.get_server().handle_message
