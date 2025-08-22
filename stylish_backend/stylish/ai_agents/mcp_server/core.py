import json
import logging
from typing import Dict, List, Any, Optional, Union
from dataclasses import dataclass, field
from enum import Enum
from datetime import datetime

logger = logging.getLogger(__name__)


class MCPMessageType(Enum):
    """MCP message types according to the protocol spec"""

    REQUEST = "request"
    RESPONSE = "response"
    NOTIFIICATION = "notification"


class MCPMethod(Enum):
    """Standard MCP methods"""

    INITIALIZE = "initialize"
    LIST_TOOLS = "tools/list"
    CALL_TOOL = "tools/call"
    LIST_RESOURCES = "resources/list"
    READ_RESOURCE = "resources/read"
    LIST_PROMPTS = "prompts/list"
    GET_PROMPT = "prompts/get"
    COMPLETION = "completion/complete"
    LOGGING = "logging/setLevel"


@dataclass
class MCPTool:
    """MCP Tool definition"""

    name: str
    description: str
    inputSchema: Dict[str, Any]

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "description": self.description,
            "inputSchema": self.inputSchema,
        }


@dataclass
class MCPResource:
    """MCP Resource definition"""

    uri: str
    name: str
    description: str
    mimeType: str

    def to_dict(self) -> Dict[str, Any]:
        return {
            "uri": self.uri,
            "name": self.name,
            "description": self.description,
            "mimeType": self.mimeType,
        }


@dataclass
class MCPPrompt:
    """MCP Prompt definitions"""

    name: str
    description: str
    arguments: List[Dict[str, Any]] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "description": self.description,
            "arguments": self.arguments,
        }


@dataclass
class MCPMessage:
    """MCP Protocol message"""

    jsonrpc: str = "2.0"
    method: Optional[str] = None
    params: Optional[Dict[str, Any]] = None
    id: Optional[Union[str, int]] = None
    result: Optional[Any] = None
    error: Optional[Dict[str, Any]] = None

    def to_dict(self) -> Dict[str, Any]:
        msg = {"jsonrpc": self.jsonrpc}
        if self.method is not None:
            msg["method"] = self.method
        if self.params is not None:
            msg["params"] = self.params

        if self.id is not None:
            msg["id"] = self.id
        if self.result is not None:
            msg["result"] = self.result

        if self.error is not None:
            msg["error"] = self.error

        return msg


class MCPServer:
    """Core MCP Server implementation"""

    def __init__(self, name: str, version: str):
        self.name = name
        self.version = version
        self.tools: Dict[str, MCPTool] = {}
        self.resources: Dict[str, MCPResource] = {}
        self.prompts: Dict[str, MCPPrompt] = {}
        self.tool_handlers: Dict[str, callable] = {}
        self.resource_handlers: Dict[str, callable] = {}
        self.prompt_handlers: Dict[str, callable] = {}
        self.initialized = False

    def register_tool(self, tool: MCPTool, handler: callable):
        """Register a tool with its handler"""
        self.tools[tool.name] = tool
        self.tool_handlers[tool.name] = handler

    def register_resources(self, resource: MCPResource, handler: callable):
        """Register a resource with its handler"""
        self.resources[resource.uri] = resource
        self.resource_handlers[resource.uri] = handler

    def register_prompt(self, prompt: MCPPrompt, handler: callable):
        """Register a prompt with its handler"""
        self.prompts[prompt.name] = prompt
        self.prompt_handlers[prompt.name] = handler

    async def handle_message(self, message: Dict[str, Any]) -> Dict[str, Any]:
        """Handle incoming MCP message"""
        try:
            msg = MCPMessage(**message)

            if msg.method == MCPMethod.INITIALIZE.value:
                return await self._handle_initialize(msg)

            elif msg.method == MCPMethod.LIST_TOOLS.value:
                return await self._handle_list_tools(msg)
            elif msg.method == MCPMethod.CALL_TOOL.value:
                return await self._handle_call_tool(msg)
            elif msg.method == MCPMethod.LIST_RESOURCES.value:
                return await self._handle_list_resources(msg)
            elif msg.method == MCPMethod.READ_RESOURCE.value:
                return await self._handle_read_resource(msg)
            elif msg.method == MCPMethod.LIST_PROMPTS.value:
                return await self._handle_list_prompts(msg)
            elif msg.method == MCPMethod.GET_PROMPT.value:
                return await self._handle_get_prompt(msg)
            else:
                return self._create_error_response(msg.id, -32601, "Method not found")

        except Exception as e:
            logger.error(f"Error handling MCP message: {str(e)}")
            return self._create_error_response(
                message.get("id"), -32603, f"Internal error: {str(e)}"
            )

    async def _handle_initialize(self, msg: MCPMessage) -> Dict[str, Any]:
        """Handle initialize request"""
        self.initialized = True
        return MCPMessage(
            id=msg.id,
            result={
                "protocolVersion": "2024-11-05",
                "capabilities": {
                    "tools": {"listChanged": True},
                    "resources": {"listchanged": True, "subscribe": True},
                    "prompts": {"listChanged": True},
                    "logging": {},
                },
                "serverInfo": {"name": self.name, "version": self.version},
            },
        ).to_dict()

    async def _handle_list_tools(self, msg: MCPMessage) -> Dict[str, Any]:
        """Handle list tools request"""
        if not self.initialized:
            return self._create_error_response(msg.id, -32002, "Server not initialized")

        tool_name = msg.params.get("name")
        arguments = msg.params.get("arguments", {})

        if tool_name not in self.tool_handlers:
            return self._create_error_response(
                msg.id, -32602, f"Tool '{tool_name}' not found"
            )

        try:
            handler = self.tool_handlers[tool_name]
            result = await handler(arguments)

            return MCPMessage(
                id=msg.id,
                result={
                    "content": [
                        {
                            "type": "text",
                            "text": json.dumps(result, indent=2, default=str),
                        }
                    ]
                },
            ).to_dict()

        except Exception as e:
            logger.error(f"Error executing tool {tool_name}: {str(e)}")
            return self._create_error_response(
                msg.id, -32603, f"Tool execution failed: {str(e)}"
            )

    async def _handle_call_tool(self, msg: MCPMessage) -> Dict[str, Any]:
        """Handle tool call request"""
        if not self.initialized:
            return self._create_error_response(msg.id, -32002, "Server not initialized")

        tool_name = msg.params.get("name")
        arguments = msg.params.get("arguments", {})

        if tool_name not in self.tool_handlers:
            return self._create_error_response(
                msg.id, -32602, f"Tool '{tool_name}' not found"
            )
        try:
            handler = self.tool_handlers[tool_name]
            result = await handler(arguments)

            return MCPMessage(
                id=msg.id,
                result={
                    "content": [
                        {
                            "type": "text",
                            "text": json.dumps(result, indent=2, default=str),
                        }
                    ]
                },
            ).to_dict()

        except Exception as e:
            logger.error(f"Error executing tool {tool_name}: {str(e)}")
            return self._create_error_response(
                msg.id, -32603, f"Tool execution failed: {str(e)}"
            )

    async def _handle_list_resources(self, msg: MCPMessage) -> Dict[str, Any]:
        """Handle list resources request"""
        if not self.initialized:
            return self._create_error_response(msg.id, -32002, "Server not initialized")

        return MCPMessage(
            id=msg.id,
            result={
                "resources": [
                    resource.do_dict() for resource in self.resources.values()
                ]
            },
        ).to_dict()

    async def _handle_read_resource(self, msg: MCPMessage) -> Dict[str, Any]:
        """Handle read read resource request"""
        if not self.initialized:
            return self._create_error_response(msg.id, -32002, "Server not initialized")

        uri = msg.params.get("uri")

        if uri not in self.resource_handlers:
            return self._create_error_response(
                msg.id, -32602, f"Resource '{uri}' not found"
            )

        try:
            handler = self.resource_handlers(uri)
            result = await handler

            return MCPMessage(
                id=msg.id,
                result={
                    "contents": [
                        {
                            "uri": uri,
                            "mimeType": self.resources[uri].mimeType,
                            "text": json.dumps(result, indent=2, default=str),
                        }
                    ]
                },
            ).to_dict()

        except Exception as e:
            logger.error(f"Error reading resources {uri}: {str(e)}")
            return self._create_error_response(
                msg.id, -32603, f"Resource read failed: {str(e)}"
            )

    async def _handle_list_prompts(self, msg: MCPMessage) -> Dict[str, Any]:
        """Handle list prompts request"""
        if not self.initialized:
            return self._create_error_response(msg.id, -32002, "Server not initialized")

        return MCPMessage(
            id=msg.id,
            result={"prompts": [prompt.to_dict() for prompt in self.prompts.values()]},
        ).to_dict()

    async def _handle_get_prompt(self, msg: MCPMessage) -> Dict[str, Any]:
        """Handle get prompt request"""
        if not self.initialized:
            return self._create_error_response(msg.id, -32002, "Server not initialized")

        prompt_name = msg.params.get("name")
        arguments = msg.params.get("arguments", {})

        if prompt_name not in self.prompt_handlers:
            return self._create_error_response(
                msg.id, -32602, f"Prompt '{prompt_name}' not found"
            )

        try:
            handler = self.prompt_handlers(prompt_name)
            result = await handler(arguments)

            return MCPMessage(
                id=msg.id,
                result={
                    "description": self.prompts[prompt_name].description,
                    "messages": result,
                },
            ).to_dict()

        except Exception as e:
            logger.error(f"Error getting prompt {prompt_name}: {str(e)}")
            return self._create_error_response(
                msg.id, -32603, f"Prompt execution failed: {str(e)}"
            )

    def _create_error_response(
        self, msg_id: Optional[Union[str, int]], code: int, message: str
    ) -> Dict[str, Any]:
        """Create an error response"""
        return MCPMessage(id=msg_id, error={"code": code, "message": message}).to_dict()
