import re
import html
import logging
from django.conf import settings

from ai_agents.services.chat_agent import ChatContext
from .exceptions import ChatValidationError

logger = logging.getLogger(__name__)


class ChatValidator:
    """Handles all input validation and sanitization"""

    def __init__(self):
        self.max_query_length = getattr(settings, "CHAT_MAX_QUERY_LENGTH", 1000)
        self.blocked_patterns = [
            r"(?i)(delete|drop|truncate)\s+table",
            r"(?i)union\s+select",
            r"(?i)<script.*?>",
            r"(?i)javascript:",
            r"(?i)data:text/html",
            r"(?i)exec\s*\(",
            r"(?i)eval\s*\(",
            r"(?i)import\s+os",
            r"(?i)__import__",
        ]

    async def validate_and_sanitize(self, query: str, context: ChatContext) -> str:
        """comprehensive validation and sanitization"""
        if not query or not query.strip():
            raise ChatValidationError("Query cannot be empty")

        if len(query) > self.max_query_length:
            raise ChatValidationError(
                f"Query too long. Max {self.max_query_length} chars"
            )
        for pattern in self.blocked_patterns:
            if re.search(pattern, query):
                logger.warning(
                    f"Blocked malicious query from the user {context.user_id}"
                )
                raise ChatValidationError("Query contains prohibited content")

        if self._contains_sensitive_keywords(query) and not self._has_admin_access(
            context
        ):
            raise ChatValidationError("Insufficient permissions")

        return html.escape(query.strip())

    def _contains_sensitive_keywords(self, query: str) -> bool:
        sensitive_words = ["password", "secret", "token", "key", "credential"]
        return any(word in query.lower() for word in sensitive_words)

    def _has_admin_access(self, context: ChatContext) -> bool:
        return (
            "admin" in context.user_permissions
            or "superuser" in context.user_permissions
        )
