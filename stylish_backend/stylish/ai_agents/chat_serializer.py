from rest_framework import serializers
from django.utils import timezone
from .models import ChatAnalytics, ChatFeedback, ChatMessage, ChatSession
from .services.chat_agent import QueryIntent


class ChatQuerySerializer(serializers.Serializer):
    """Serializer for incoming chat queries"""

    query = serializers.CharField(
        max_length=2000,
        min_length=1,
        help_text="The user's natural language query",
        error_messages={
            "blank": "Query cannot be empty",
            "max_length": "Query must be under 2000 characters",
            "min_length": "Query cannot be empty",
        },
    )

    context = serializers.JSONField(
        required=False, default=dict, help_text="Additional context data for the query"
    )

    session_id = serializers.CharField(
        max_length=100,
        required=False,
        help_text="Optional session ID for conversation continuity",
    )

    def validate_query(self, value):
        """Additional query validation"""
        if not value or not value.strip():
            raise serializers.ValidationError(
                "Query cannot be empty or just whitespace"
            )
        # Check for potentially harmful patterns
        harmful_patterns = [
            "<script",
            "javascript:",
            "data:text/html",
            "DROP TABLE",
            "DELETE FROM",
        ]
        query_lower = value.lower()
        for pattern in harmful_patterns:
            if pattern.lower() in query_lower:
                raise serializers.ValidationError("Query contains prohibited content")
        return value.strip()

    def validate_context(self, value):
        """Validated context data"""
        if not isinstance(value, dict):
            raise serializers.ValidationError("Context must be a JSON object")
        # Limit context size to prevent abuse
        if len(str(value)) > 10000:
            raise serializers.ValidationError("Context data too large")
        return value


class ChatResponseSerializer(serializers.Serializer):
    """Serializer for chat responses"""

    query = serializers.CharField(help_text="The original query")
    intent = serializers.ChoiceField(
        choices=QueryIntent.choices(), help_text="Classified intent of the query"
    )
    response = serializers.CharField(help_text="AI-generated response text")
    data = serializers.JSONField(help_text="Supporting data for the response")
    timestamp = serializers.DateTimeField(help_text="Response generation timestamp")
    execution_time = serializers.FloatField(
        help_text="Query processing time in seconds"
    )
    confidence_score = serializers.FloatField(
        min_value=0.0,
        max_value=1.0,
        help_text="Confidence score for the response (0-1)",
    )

    session_id = serializers.CharField(help_text="Chat session identifier")
    error = serializers.CharField(
        required=False,
        allow_null=True,
        help_text="Error message if query processing failed",
    )
    metadata = serializers.JSONField(
        required=False, default=dict, help_text="Additional response metadata"
    )
    message_id = serializers.CharField(
        help_text="Unique identifier for the chat message"
    )


class ChatMessageSerializer(serializers.ModelSerializer):
    """Serializer for chat message model"""

    intent_display = serializers.CharField(source="get_intent_display", read_only=True)
    created_at_formatted = serializers.SerializerMethodField()

    class Meta:
        model = ChatMessage
        fields = [
            "id",
            "query",
            "response",
            "intent",
            "intent_display",
            "execution_time",
            "confidence_score",
            "metadata",
            "created_at",
            "created_at_formatted",
        ]
        read_only_fields = ["id", "created_at"]

    def get_created_at_formatted(self, obj):
        """Format creation timestamp for display"""
        return obj.created_at.strftime("%Y-%m-%d %H:%M:%S UTC")


class ChatSessionSerializer(serializers.ModelSerializer):
    """Serializer for chat sessions"""

    message_count = serializers.SerializerMethodField()
    last_activity = serializers.SerializerMethodField()
    messages = ChatMessageSerializer(many=True, read_only=True)
    created_at_formatted = serializers.SerializerMethodField()

    class Meta:
        model = ChatSession
        fields = [
            "session_id",
            "user_id",
            "created_at",
            "created_at_formatted",
            "message_count",
            "last_activity",
            "messages",
        ]
        read_only_fields = ["session_id", "user_id", "created_at"]

    def get_message_count(self, obj):
        """Get total message count for session"""
        return obj.messages.count()

    def get_last_activity(self, obj):
        """Get timestamp of last message in session"""
        last_message = obj.messages.order_by("-created_at").first()
        if last_message:
            return last_message.created_at.strftime("%Y-%m-%d %H:%M:%S UTC")
        return obj.created_at.strftime("%Y-%m-%d %H:%M:%S UTC")

    def get_created_at_formatted(self, obj):
        """Format creation timestamp for display"""
        return obj.created_at.strftime("%Y-%m-%d %H:%M:%S UTC")

    def to_representation(self, instance):
        """Conditionally include messages based on context"""
        data = super().to_representation(instance)

        if not self.context.get("include_messages", False):
            data.pop("messages", None)

        return data


class ChatFeedbackSerializer(serializers.ModelSerializer):
    """Serializer for chat feedback"""

    message_id = serializers.UUIDField(
        write_only=True, help_text="ID of the message being rated"
    )
    feedback_type = serializers.ChoiceField(
        choices=ChatFeedback.FEEDBACK_TYPES, help_text="Type of feedback"
    )
    rating = serializers.IntegerField(
        min_value=1, max_value=5, help_text="Rating from 1-5 stars"
    )
    reason = serializers.ChoiceField(
        choices=ChatFeedback.FEEDBACK_REASONS,
        required=False,
        allow_blank=True,
        help_text="Reason for the feedback",
    )
    comment = serializers.CharField(
        max_length=1000,
        required=False,
        allow_blank=True,
        help_text="Optional feedback comment",
    )

    class Meta:
        model = ChatFeedback
        fields = [
            "id",
            "message_id",
            "feedback_type",
            "rating",
            "reason",
            "comment",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]

    def validate_comment(self, value):
        """Validate feedback comment"""
        if value and len(value.strip()) == 0:
            return ""
        return value


class ChatAnalyticsSerializer(serializers.Serializer):
    """Serializer for chat analytics data"""

    period_days = serializers.IntegerField(help_text="Analysis period in days")
    total_sessions = serializers.IntegerField(help_text="Total chat sessions")
    total_messages = serializers.IntegerField(help_text="Total messages sent")
    avg_session_length = serializers.FloatField(
        help_text="Average messages per session"
    )
    avg_response_time = serializers.FloatField(
        help_text="Average response time in seconds"
    )
    most_common_intents = serializers.ListField(
        child=serializers.DictField(), help_text="Most frequently used intents"
    )
    confidence_distribution = serializers.DictField(
        help_text="Confidence score statistics"
    )
    success_rate = serializers.FloatField(
        required=False, help_text="Percentage of successful queries"
    )
    user_satisfaction = serializers.FloatField(
        required=False, help_text="Average user statisfaction score"
    )
    peak_usage_hours = serializers.ListField(
        child=serializers.IntegerField(),
        required=False,
        help_text="Hours with highest usage",
    )


class ChatHealthSerializer(serializers.Serializer):
    """Serializer for chat service health status"""

    status = serializers.ChoiceField(
        choices=[
            ("healthy", "Healthy"),
            ("degraded", "Degraded"),
            ("unhealthy", "Unhealthy"),
        ]
    )

    timestamp = serializers.DateTimeField()
    version = serializers.CharField()
    checks = serializers.DictField(help_text="Individual component health checks")
    uptime = serializers.FloatField(
        required=False, help_text="Service uptime in seconds"
    )
    active_sessions = serializers.IntegerField(
        required=False, help_text="Number of active chat sessions"
    )


class ChatSessionCreateSerializer(serializers.Serializer):
    """Serializer for creating new chat sessions"""

    context = serializers.JSONField(
        required=False, default=dict, help_text="Initial session context"
    )

    def validate_context(self, value):
        """Validate session context"""
        if not isinstance(value, dict):
            raise serializers.ValidationError("Context must be a JSON object")
        return value
