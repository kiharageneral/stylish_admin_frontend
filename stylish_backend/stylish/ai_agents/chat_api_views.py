import json
import uuid
import logging
from datetime import datetime, timedelta
from typing import Dict, Any

from django.utils import timezone
from django.db.models import Count, Avg, Q
from django.http import StreamingHttpResponse
from django.conf import settings
from django.core.cache import cache

from rest_framework import status, viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.throttling import UserRateThrottle, AnonRateThrottle
from rest_framework.exceptions import ValidationError

from ai_agents.utils.encoders import CustomJSONEncoder

from .models import ChatMessage, ChatFeedback, ChatSession, Agent
from .chat_serializer import (
    ChatQuerySerializer,
    ChatResponseSerializer,
    ChatMessageSerializer,
    ChatSessionCreateSerializer,
    ChatFeedbackSerializer,
    ChatAnalyticsSerializer,
    ChatHealthSerializer,
    ChatSessionSerializer,
)

from ai_agents.services.chatagent.core import ProductionChatAssistantAgent
from .services.chat_agent import (
    ChatContext,
    QueryIntent,
    ChatResponse,
    RateLimitExceededError,
    ChatValidationError,
)
from ai_agents.services.chatagent.monitoring import HealthChecker
from ai_agents.services.chatagent.metrics import metrics_collector
from asgiref.sync import async_to_sync, sync_to_async

logger = logging.getLogger(__name__)


class ChatRateThrottle(UserRateThrottle):
    """Custom throttle for chat endpoints"""

    scope = "chat"
    rate = "60/min"


class ChatAnonRateThrottle(AnonRateThrottle):
    """Anonymous user throttle for chat"""

    scope = "chat_anon"
    rate = "10/min"


class ChatSessionViewSet(viewsets.ModelViewSet):
    """ViewSet for managing chat sessions"""

    serializer_class = ChatSessionSerializer
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [ChatRateThrottle, ChatAnonRateThrottle]
    lookup_field = "session_id"

    def get_queryset(self):
        """Filter sessions by authenticated user"""
        if not self.request.user.is_authenticated:
            return ChatSession.objects.none()
        return (
            ChatSession.objects.filter(user_id=self.request.user.id)
            .prefetch_related("messages")
            .order_by("-created_at")
        )

    def get_serializer_context(self):
        """Add request context to serializer"""
        context = super().get_serializer_context()
        context["include_messages"] = (
            self.action == "retrieve"
            or self.request.query_params.get("include_messages") == "true"
        )

        return context

    def create(self, request, *args, **kwargs):
        """Create a new chat session"""
        serializer = ChatSessionCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        session_id = str(uuid.uuid4())

        session = ChatSession.objects.create(
            session_id=session_id,
            user_id=request.user.id,
            metadata=serializer.validated_data.get("context", {}),
        )

        response_serializer = self.get_serializer(session)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["get"])
    def messages(self, request, session_id=None):
        """Get all messages for a session with pagination"""
        session = self.get_object()

        messages = session.messages.order_by("-created_at")

        page_size = min(int(request.query_params.get("page_size", 20)), 100)
        page = max(int(request.query_params.get("page", 1)), 1)

        start = (page - 1) * page_size
        end = start + page_size

        paginated_messages = messages[start:end]

        serializer = ChatMessageSerializer(paginated_messages, many=True)

        return Response(
            {
                "messages": serializer.data,
                "total_count": messages.count(),
                "page": page,
                "page_size": page_size,
                "has_next": end < messages.count(),
            }
        )

    @action(detail=True, methods=["delete"])
    def clear_messages(self, request, session_id=None):
        """clear all messages from a session"""
        session = self.get_object()

        deleted_count = session.messages.count()
        session.messages.all().delete()

        return Response(
            {
                "message": f"Cleared {deleted_count} messages from session",
                "session_id": session.session_id,
            }
        )


class ChatQueryViewSet(viewsets.GenericViewSet):
    """ViewSet for processing chat queries"""

    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [ChatAnonRateThrottle, ChatRateThrottle]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.health_checker = HealthChecker()
        self._agent_cache = {}

    def get_chat_agent(self) -> ProductionChatAssistantAgent:
        """Get or create chat agent instance"""
        cache_key = "chat_agent_active"
        if cache_key not in self._agent_cache:
            try:
                agent_model = Agent.objects.filter(
                    agent_type="chat_assistant", is_active=True
                ).first()
                if not agent_model:
                    raise ValidationError("No active chat agent available")
                self._agent_cache[cache_key] = ProductionChatAssistantAgent(agent_model)

            except Exception as e:
                logger.error(f"Failed to get chat agent: {str(e)}")
                raise ValidationError("chat agent unavailable")
        return self._agent_cache[cache_key]

    async def get_chat_agent_async(self) -> ProductionChatAssistantAgent:
        """Async version for getting the chat agent"""
        cache_key = "chat_agent_active"
        if cache_key not in self._agent_cache:
            try:
                agent_model = await sync_to_async(
                    lambda: Agent.objects.filter(
                        agent_type="chat_assistant", is_active=True
                    ).first()
                )()
                if not agent_model:
                    raise ValidationError("No active chat agent available")
                self._agent_cache[cache_key] = ProductionChatAssistantAgent(agent_model)

            except Exception as e:
                logger.error(f"Failed to get async chat agent: {str(e)}")
                raise ValidationError("chat agent unavailable")
        return self._agent_cache[cache_key]

    def create_chat_context(self, request, session_id: str = None) -> ChatContext:
        """Create ChatContext from request"""
        user_permissions = []
        if hasattr(request.user, "get_all_permissions"):
            user_permissions = list(request.user.get_all_permissions())
        return ChatContext(
            user_id=request.user.id,
            session_id=session_id or str(uuid.uuid4()),
            user_permissions=user_permissions,
            rate_limit_key=f"user:{request.user.id}",
            metadata={
                "user_agent": request.META.get("HTTP_USER_AGENT", ""),
                "ip_address": self.get_client_ip(request),
                "timestamp": timezone.now().isoformat(),
            },
        )

    def get_client_ip(self, request):
        """Extract client IP address"""
        x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
        if x_forwarded_for:
            return x_forwarded_for.split(",")[0].strip()
        return request.META.get("REMOTE_ADDR", "")

    async def _get_and_process_query(
        self, query: str, context: ChatContext
    ) -> ChatResponse:
        """Asynchronously gets the agent and processes the query ."""
        agent = await self.get_chat_agent_async()
        return await agent.process_query_async(query, context)

    @action(detail=False, methods=["post"])
    def query(self, request):
        """Process a chat query using a standard request/response"""
        serializer = ChatQuerySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        query_text = serializer.validated_data["query"]
        session_id = serializer.validated_data.get("session_id")
        context = self.create_chat_context(request, session_id)

        try:
            response_obj = async_to_sync(self._get_and_process_query)(
                query_text, context
            )

            response_serializer = ChatResponseSerializer(response_obj)
            return Response(response_serializer.data, status=status.HTTP_200_OK)

        except (RateLimitExceededError, ChatValidationError) as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        except Exception as e:
            logger.error(
                f"Chat query failed for user {request.user.id}: {str(e)}", exc_info=True
            )
            return Response(
                {"error": "Internal server error"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

    @action(detail=False, methods=["post"])
    async def stream_query(self, request):
        """Stream chat response with real-time progress events"""
        serializer = ChatQuerySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        query_text = serializer.validated_data["query"]
        session_id = serializer.validated_data.get("session_id")
        context = self.create_chat_context(request, session_id)

        async def event_stream():
            """The async generator that yields SSE events to the client"""
            try:
                agent = await self.get_chat_agent_async()
                async for event in agent.process_query_stream(query_text, context):
                    yield f"data: {json.dumps(event, cls=CustomJSONEncoder)}\n\n"
            except Exception as e:
                logger.error(
                    f"Streaming error for user {request.user.id}: {str(e)}",
                    exc_info=True,
                )

                error_event = {
                    "event": "error",
                    "data": {"message": "A critical error occurred during streaming."},
                }

                yield f"data: {json.dumps(error_event, cls = CustomJSONEncoder)} \n\n"

        response = StreamingHttpResponse(
            event_stream(), content_type="text/event-stream"
        )

        response["Cache-control"] = "no-cache"
        response["Connection"] = "keep-alive"
        response["Access-Control-Allow-Origin"] = "*"
        return response

    @action(detail=False, methods=["get"])
    def health(self, request):
        """Health check endpoint"""
        try:
            health_status = async_to_sync(self.health_checker.check_all_services)()
            overall_status = (
                "healthy"
                if all(s.status == "healthy" for s in health_status.values())
                else "unhealthy"
            )

            return Response(
                {
                    "status": overall_status,
                    "timestamp": timezone.now().isoformat(),
                    "services": {
                        name: {
                            "status": service.status,
                            "response_time": service.response_time,
                            "error": service.error,
                        }
                        for name, service in health_status.items()
                    },
                }
            )

        except Exception as e:
            logger.error(f"Health check failed: {str(e)}")
            return Response(
                {"'status': 'unhealthy', 'error': str(e)"},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

    @action(detail=False, methods=["get"])
    def metrics(self, request):
        """Get system metrics"""
        try:
            metrics = metrics_collector.get_metrics()
            return Response(
                {"timestamp": timezone.now().isoformat(), "metrics": metrics}
            )
        except Exception as e:
            logger.error(f"Metrics retrieval failed: {str(e)}")
            return Response(
                {"error": "Metrics unavailable"},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

    @action(detail=False, methods=["get"])
    def intents(self, request):
        """Get available query intents"""
        intents = [
            {
                "value": intent.value,
                "display_name": intent.value.replace("_", " ").title(),
                "description": self.get_intent_description(intent),
            }
            for intent in QueryIntent
        ]

    def get_intent_description(self, intent: QueryIntent) -> str:
        """Get human-readable description for intent"""
        descriptions = {
            QueryIntent.INVENTORY_STATUS: "Questions about stock levels and inventory",
            QueryIntent.SALES_DATA: "Questions about sales performance and trends",
            QueryIntent.PRODUCT_PERFORMANCE: "Questions about product analytics",
            QueryIntent.ORDER_STATUS: "Questions about order management and status",
            QueryIntent.CUSTOMER_INSIGHTS: "Questions about customer data and behavior",
            QueryIntent.REVENUE_ANALYSIS: "Questions bout revenue and financial performance",
            QueryIntent.GENERAL_STATS: "General Questions and statistics",
        }
        return descriptions.get(intent, "General purpose queries")


class ChatFeedbackViewSet(viewsets.ModelViewSet):
    """ViewSet for managing chat feedback"""

    serializer_class = ChatFeedbackSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """filter feedback by authenticated user"""
        if not self.request.user.is_authenticated:
            return ChatFeedback.objects.none()
        return ChatFeedback.objects.filter(
            message__session__user_id=self.request.user.id
        ).order_by("-created_at")

    def perform_create(self, serializer):
        """Create feedback with user context"""
        message_id = serializer.validated_data["message_id"]

        try:
            message = ChatMessage.objects.get(
                id=message_id, session__user_id=self.request.user.id
            )

        except ChatMessage.DoesNotExist:
            raise ValidationError("Message not found or access denied")

        serializer.save(message=message, user_id=self.request.user.id)


class ChatAnalyticsViewSet(viewsets.GenericViewSet):
    """ViewSet for chat analytics and monitoring"""

    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=["get"])
    def dashboard(self, request):
        """Get user's chat analytics dashboard"""
        period_days = min(int(request.query_params.get("days", 30)), 90)
        since_date = timezone.now() - timedelta(days=period_days)

        user_messages = ChatMessage.objects.filter(
            session__user_id=request.user.id, created_at__gte=since_date
        )

        analytics_agg = user_messages.aggregate(
            total_messages=Count("id"),
            avg_response_time=Avg("execution_time"),
            avg_confidence=Avg("confidence_score"),
            successful_messages=Count("id", filter=Q(confidence_score__gte=0.5)),
        )

        total_sessions_count = ChatSession.objects.filter(
            user_id=request.user.id, created_at__gte=since_date
        ).count()

        most_common_intents = list(
            user_messages.values("intent")
            .annotate(count=Count("intent"))
            .order_by("-count")[:5]
        )

        total_messages = analytics_agg.get("total_messages", 0)

        analytics_data = {
            "period_days": period_days,
            "total_sessions": total_sessions_count,
            "total_messages": total_messages,
            "avg_session_length": (total_messages / max(total_sessions_count, 1)),
            "avg_response_time": analytics_agg.get("avg_response_time") or 0.0,
            "most_common_intents": most_common_intents,
            "confidence_distribution": {
                "avg": analytics_agg.get("avg_confidence") or 0.0,
            },
            "success_rate": (
                analytics_agg.get("successful_messages", 0) / max(total_messages, 1)
            )
            * 100,
        }

        serializer = ChatAnalyticsSerializer(analytics_data)
        return Response(serializer.data)

    def get_confidence_stats(self, message_qs):
        """Calculate confidences score statistics"""
        scores = list(message_qs.values_list("confidence_score", flat=True))
        if not scores:
            return {"avg": 0.0, "min": 0.0, "max": 0.0}

        return {
            "avg": sum(scores) / len(scores),
            "min": min(scores),
            "max": max(scores),
            "count": len(scores),
        }

    def calculate_success_rate(sel, message_qs):
        """Calculate success rate based on confidence scores"""
        total = message_qs.count()
        if total == 0:
            return 0.0
        successful = message_qs.filter(confidence_score__gte=0.5).count()
        return (successful / total) * 100


class ChatHealthViewSet(viewsets.GenericViewSet):
    """ViewSet for system health monitoring"""

    permission_classes = [permissions.IsAdminUser]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.health_checker = HealthChecker()

    @action(detail=False, methods=["get"])
    def status(self, request):
        """Get overall system health status"""
        try:
            health_results = async_to_sync(self.health_checker.check_all_services)()

            overall_status = "healthy"

            if any(result.status == "unhealthy" for result in health_results.values()):
                overall_status = "unhealthy"
            elif any(result.status == "degraded" for result in health_results.values()):
                overall_status = "degraded"

            health_data = {
                "status": overall_status,
                "timestamp": timezone.now().isoformat(),
                "version": getattr(settings, "APP_VERSION", "1.0.0"),
                "checks": {
                    service: {
                        "status": result.status,
                        "response_time": result.response_time,
                        "error": result.error,
                    }
                    for service, result in health_results.items()
                },
                "active_sessions": self.get_active_sessions_count(),
            }

            serializer = ChatHealthSerializer(health_data)
            return Response(serializer.data)

        except Exception as e:
            logger.error(f"Health check failed: {str(e)}", exc_info=True)
            return Response(
                {
                    "status": "unhealthy",
                    "timestamp": timezone.now().isoformat(),
                    "error": "Health check failed",
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

    @action(detail=False, methods=["get"])
    def metrics(self, request):
        """Get system metrics"""
        try:
            metrics_data = metrics_collector.get_metrics()

            return Response(
                {
                    "timestamp": timezone.now().isoformat(),
                    "metrics": metrics_data,
                    "uptime": self.get_uptime(),
                    "active_sessions": self.get_active_sessions_count(),
                }
            )

        except Exception as e:
            logger.error(f"Metrics collection failed: {str(e)}", exc_info=True)
            return Response(
                {"error": "Metrics unavailable"},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

    def get_active_sessions_count(self) -> int:
        """Count active sessions (sessions with activity in last hour )"""
        one_hour_ago = timezone.now() - timedelta(hours=1)
        return (
            ChatSession.objects.filter(messages__created_at__gte=one_hour_ago)
            .distinct()
            .count()
        )

    def get_uptime(self) -> float:
        """Get application uptime in seconds"""
        uptime_key = "app_start_time"
        start_time = cache.get(uptime_key)

        if not start_time:
            start_time = timezone.now()
            cache.set(uptime_key, start_time, timeout=None)
        return (timezone.now() - start_time).total_seconds()
