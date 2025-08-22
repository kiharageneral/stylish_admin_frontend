from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q, Count
from django.utils.decorators import method_decorator
from django.views.decorators.cache import never_cache
from .models import Agent, AgentExecution, AgentRecommendation
from .serializers import (
    AgentSerializer,
    AgentExecutionSerializer,
    AgentRecommendationSerializer,
)
from datetime import datetime, timedelta
from .tasks import run_agent_analysis, run_all_agents


class AgentViewSet(viewsets.ModelViewSet):
    queryset = Agent.objects.all()
    serializer_class = AgentSerializer
    permission_classes = [IsAuthenticated]

    @action(detail=True, methods=["post"])
    def execute(self, request, pk=None):
        """Trigger agent execution"""
        agent = self.get_object()

        if not agent.is_active:
            return Response(
                {"error": "Agent is not active"}, status=status.HTTP_400_BAD_REQUEST
            )

        # Queue agent for execution
        task = run_agent_analysis.delay(str(agent.id))

        return Response(
            {"message": f"Agent {agent.name} queued for execution", "task_id": task.id}
        )

    @action(detail=False, methods=["post"])
    def execute_all(self, request):
        """Execute all active agents"""
        task = run_all_agents.delay()

        return Response(
            {"message": "All agents queued for execution", "task_id": task.id}
        )

    @action(detail=False, methods=["get"])
    def dashboard_stats(self, request):
        """Get dashboard statistics"""
        total_agents = Agent.objects.count()
        active_agents = Agent.objects.filter(is_active=True).count()

        recent_executions = AgentExecution.objects.filter(
            started_at__gte=datetime.now() - timedelta(days=7)
        ).count()

        pending_recommendations = AgentRecommendation.objects.filter(
            is_approved=False
        ).count()

        return Response(
            {
                "total_agents": total_agents,
                "active_agents": active_agents,
                "recent_executions": recent_executions,
                "pending_recommendations": pending_recommendations,
            }
        )


class AgentExecutionViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for listing and retrieving agent executions"""

    queryset = AgentExecution.objects.all().order_by("-started_at")
    serializer_class = AgentExecutionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Optionally filter executions by agent_id"""
        queryset = super().get_queryset()
        agent_id = self.request.query_params.get("agent")
        if agent_id:
            queryset = queryset.filter(agent__id=agent_id)
        limit_str = self.request.query_params.get("limit")
        if limit_str and limit_str.isdigit():
            limit = int(limit_str)
            queryset = queryset[:limit]

        return queryset


class AgentRecommendationViewSet(viewsets.ModelViewSet):
    queryset = AgentRecommendation.objects.select_related("agent").all()
    serializer_class = AgentRecommendationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = super().get_queryset()

        priority = self.request.query_params.get("priority")
        if priority:
            queryset = queryset.filter(priority=priority)

        approved = self.request.query_params.get("approved")
        if approved is not None and approved.lower() in ["true", "false"]:
            queryset = queryset.filter(is_approved=approved.lower() == "true")

        rec_type = self.request.query_params.get("type")
        if rec_type:
            queryset = queryset.filter(recommendation_type=rec_type)

        return queryset.order_by("-created_at")

    @method_decorator(never_cache)
    def list(self, request, *args, **kwargs):
        return super().list(request, *args, **kwargs)

    @action(detail=True, methods=["post"])
    def approve(self, request, pk=None):
        """Approve a recommendation"""
        recommendation = self.get_object()
        recommendation.is_approved = True
        recommendation.approved_by = request.user
        recommendation.save()

        serializer = self.get_serializer(recommendation)
        return Response(serializer.data)

    @action(detail=True, methods=["post"])
    def implement(self, request, pk=None):
        """Mark recommendation as implemented"""
        recommendation = self.get_object()
        recommendation.is_implemented = True
        recommendation.save()

        serializer = self.get_serializer(recommendation)
        return Response(serializer.data)

    @method_decorator(never_cache)
    @action(detail=False, methods=["get"])
    def summary(self, request):
        """Get recommendations summary"""
        total = AgentRecommendation.objects.count()
        approved = AgentRecommendation.objects.filter(is_approved=True).count()
        pending = total - approved

        by_priority = (
            AgentRecommendation.objects.values("priority")
            .annotate(count=Count("id"))
            .order_by()
        )

        by_type = (
            AgentRecommendation.objects.values("recommendation_type")
            .annotate(count=Count("id"))
            .order_by()
        )

        return Response(
            {
                "total_recommendations": total,
                "approved_count": approved,
                "pending_count": pending,
                "by_priority": list(by_priority),
                "by_type": list(by_type),
            }
        )
