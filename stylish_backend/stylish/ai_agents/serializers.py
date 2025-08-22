from rest_framework import serializers
from .models import Agent, AgentExecution, AgentRecommendation
from django.contrib.contenttypes.models import ContentType


class AgentSerializer(serializers.ModelSerializer):
    agent_type_display = serializers.CharField(
        source="get_agent_type_display", read_only=True
    )

    class Meta:
        model = Agent
        fields = [
            "id",
            "name",
            "agent_type",
            "agent_type_display",
            "description",
            "is_active",
            "last_execution",
            "created_at",
        ]


class AgentExecutionSerializer(serializers.ModelSerializer):
    agent_name = serializers.CharField(source="agent.name", read_only=True)

    class Meta:
        model = AgentExecution
        fields = [
            "id",
            "agent",
            "agent_name",
            "status",
            "input_data",
            "output_data",
            "error_message",
            "execution_time",
            "started_at",
            "completed_at",
        ]


class AgentRecommendationSerializer(serializers.ModelSerializer):
    agent_name = serializers.CharField(source="agent.name", read_only=True)
    recommendation_type_display = serializers.CharField(
        source="get_recommendation_type_display", read_only=True
    )
    priority_display = serializers.CharField(
        source="get_priority_display", read_only=True
    )

    class Meta:
        model = AgentRecommendation
        fields = [
            "id",
            "agent",
            "agent_name",
            "recommendation_type",
            "recommendation_type_display",
            "title",
            "description",
            "priority",
            "priority_display",
            "data",
            "confidence_score",
            "estimated_impact",
            "is_approved",
            "is_implemented",
            "created_at",
        ]
