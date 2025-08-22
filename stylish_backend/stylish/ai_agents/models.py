from django.db import models
from django.contrib.contenttypes.models import ContentType
from django.contrib.contenttypes.fields import GenericForeignKey
from django.conf import settings
import uuid
import json

from .services.chat_agent import QueryIntent


class Agent(models.Model):
    """Core agenet model that defines different AI agents"""

    AGENT_TYPES = [
        ("inventory_manager", "Inventory Management Agent"),
        ("sales_analyst", "Sales Analysis Agent"),
        ("customer_insights", "Customer Insights Agent"),
        ("pricing_optimizer", "Pricing Optimization Agent"),
        ("marketing_strategist", "Marketing Strategy Agent"),
        ("supply_chain", "Supply Chain Agent"),
        ("fraud_detector", "Fraud Detection Agent"),
        ("chat_agent", "Chat Assistant Agent"),
        ("recommendation_engine", "Recommendation Engine"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    agent_type = models.CharField(max_length=50, choices=AGENT_TYPES)
    description = models.TextField()
    is_active = models.BooleanField(default=True)
    configuration = models.JSONField(default=dict)
    last_execution = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    total_executions = models.IntegerField(default=0)
    successful_executions = models.IntegerField(default=0)
    avg_execution_time = models.FloatField(default=0.0)
    last_error = models.TextField(blank=True)

    def success_rate(self):
        """Calculate success rate percentage"""
        if self.total_executions == 0:
            return 0.0
        return (self.successful_executions / self.total_executions) * 100

    def __str__(self):
        return f"{self.name} ({self.get_agent_type_display()})"


class AgentExecution(models.Model):
    """Track agent executions and results"""

    EXECUTION_STATUS = [
        ("pending", "Pending"),
        ("running", "Running"),
        ("completed", "Completed"),
        ("failed", "Failed"),
        ("cancelled", "Cancelled"),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    agent = models.ForeignKey(
        Agent, on_delete=models.CASCADE, related_name="executions"
    )
    status = models.CharField(
        max_length=20, choices=EXECUTION_STATUS, default="pending"
    )
    input_data = models.JSONField(default=dict)
    output_data = models.JSONField(default=dict)
    error_message = models.TextField(blank=True)
    execution_time = models.FloatField(null=True, help_text="Execution time in seconds")
    started_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-started_at"]


class ChatSession(models.Model):
    """Chat session model to group related messages"""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    session_id = models.CharField(max_length=100, unique=True, db_index=True)
    user = models.ForeignKey(
        "authentication.CustomUser", on_delete=models.CASCADE, db_index=True
    )

    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Session metadata
    metadata = models.JSONField(default=dict, blank=True)
    is_active = models.BooleanField(default=True)

    # Session management fields
    title = models.CharField(
        max_length=200, blank=True, help_text="User-defined session title"
    )
    last_activity = models.DateTimeField(auto_now=True, db_index=True)
    is_archived = models.BooleanField(default=True)
    archived_at = models.DateTimeField(null=True, blank=True)

    # Session settins
    context_window_size = models.IntegerField(
        default=10, help_text="Number of previous messages to include in context"
    )

    class Meta:
        ordering = ["-last_activity"]
        indexes = [
            models.Index(fields=["user", "-last_activity"]),
            models.Index(fields=["session_id"]),
            models.Index(fields=["is_active", "-last_activity"]),
            models.Index(fields=["is_archived", "-last_activity"]),
            models.Index(fields=["user", "is_active", "-last_activity"]),
        ]

    def __str__(self):
        return f"Chat Session {self.session_id} - {self.user.username}"

    @property
    def message_count(self):
        """Get total message count for this session"""
        return self.messages.filter(is_deleted=False).count()

    def get_context_messages(self):
        """Get recent messages for AI context"""
        return self.messages.filter(is_deleted=False).order_by("-created_at")[
            : self.context_window_size
        ]

    def mark_inactive(self):
        """Mark session as inactive"""
        self.is_active = False
        self.save(update_fields=["is_active", "updated_at"])


class ChatMessage(models.Model):
    """Individual chat messages within sessions"""

    INTENT_CHOICES = QueryIntent.choices()

    # Message type choices
    MESSAGE_TYPE_CHOICES = [
        ("user", "User Message"),
        ("assistant", "Assistant Response"),
        ("system", "System Message"),
        ("error", "Error Response"),
    ]

    STATUS_CHOICES = [
        ("pending", "Pending"),
        ("processing", "Processing"),
        ("completed", "Completed"),
        ("failed", "Failed"),
        ("cancelled", "Cancelled"),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    session = models.ForeignKey(
        ChatSession, on_delete=models.CASCADE, related_name="messages", db_index=True
    )

    message_type = models.CharField(
        max_length=20, choices=MESSAGE_TYPE_CHOICES, default="user", db_index=True
    )
    status = models.CharField(
        max_length=20, choices=STATUS_CHOICES, default="pending", db_index=True
    )

    # Message content
    query = models.TextField(help_text="User's original query")
    response = models.TextField(help_text="AI-generated response")
    intent = models.CharField(
        max_length=50,
        choices=INTENT_CHOICES,
        db_index=True,
        help_text="Classified intent of the query",
    )

    # Message threading
    parent_message = models.ForeignKey(
        "self", on_delete=models.CASCADE, null=True, blank=True, related_name="replies"
    )
    execution_time = models.FloatField(
        default=0.0, help_text="Query processing time in seconds"
    )
    confidence_score = models.FloatField(
        default=0.0, help_text="AI confidence score (0-1)"
    )

    error_details = models.JSONField(
        default=dict, blank=True, help_text="Error details if processing failed"
    )

    metadata = models.JSONField(
        default=dict, blank=True, help_text="Additional message metadata"
    )

    is_edited = models.BooleanField(default=False)
    edited_at = models.DateTimeField(null=True, blank=True)
    is_deleted = models.BooleanField(default=False)
    deleted_at = models.DateTimeField(null=True, blank=True)

    user_ip = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["session", "-created_at"]),
            models.Index(fields=["session", "message_type", "-created_at"]),
            models.Index(fields=["intent", "-created_at"]),
            models.Index(fields=["confidence_score"]),
            models.Index(fields=["status", "-created_at"]),
            models.Index(fields=["user_ip", "-created_at"]),
            models.Index(fields=["is_deleted", "-created_at"]),
            models.Index(fields=["session", "is_deleted", "-created_at"]),
        ]

    def __str__(self):
        return f"Message {self.id} - {self.message_type} - {self.intent} - {self.created_at}"

    def get_intent_display(self):
        """Get human-readable intent name"""
        return QueryIntent.get_display_name(self.intent)

    @property
    def response_preview(self):
        """Get truncated response for display"""
        return (
            self.response[:100] + "..." if len(self.response) > 100 else self.response
        )


class ChatFeedback(models.Model):
    """User feedback on chat responses"""

    FEEDBACK_TYPES = [
        ("positive", "Positive"),
        ("negative", "Negative"),
        ("neutral", "Neutral"),
    ]

    FEEDBACK_REASONS = [
        ("heplful", "Response was helpful"),
        ("accurate", "Information was accurate"),
        ("fast", "Response was fast"),
        ("complete", "Response was complete"),
        ("irrelevant", "Response was irrelevant"),
        ("inaccurate", "Information was inaccurate"),
        ("slow", "Response was too slow"),
        ("incomplete", "Response was incomplete"),
        ("unclear", "Response was unclear"),
        ("other", "Other reason"),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    message = models.ForeignKey(
        ChatMessage, on_delete=models.CASCADE, related_name="feedback"
    )
    user = models.ForeignKey(
        "authentication.CustomUser",
        on_delete=models.CASCADE,
        related_name="chat_feedback",
    )

    # Feedback content
    feedback_type = models.CharField(max_length=20, choices=FEEDBACK_TYPES)
    rating = models.IntegerField(
        choices=[(i, f"{i} Star{'s' if i != 1 else '' }") for i in range(1, 6)],
        help_text="Rating from 1-5 stars",
    )

    reason = models.CharField(
        max_length=50,
        choices=FEEDBACK_REASONS,
        blank=True,
        help_text="Reason for the feedback",
    )
    comment = models.TextField(
        blank=True, max_length=1000, help_text="Optional detailed feedback comment"
    )

    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)

    class Meta:
        ordering = ["-created_at"]
        unique_together = ["message", "user"]
        indexes = [
            models.Index(fields=["feedback_type", "-created_at"]),
            models.Index(fields=["rating", "-created_at"]),
            models.Index(fields=["message", "user"]),
            models.Index(fields=["user", "-created_at"]),
        ]

    def __str__(self):
        return f"Feedback {self.feedback_type} ({self.rating}'*') - {self.message.id}"


class ChatAnalytics(models.Model):
    """Aggregated chat analytics data"""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    date = models.DateField(db_index=True)
    user = models.ForeignKey(
        "authentication.CustomUser",
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="chat_analytics",
    )

    # Usage metrics
    total_queries = models.IntegerField(default=0)
    total_sessions = models.IntegerField(default=0)
    avg_response_time = models.FloatField(default=0.0)
    avg_confidence_score = models.FloatField(default=0.0)

    # Intent distribution
    intent_distribution = models.JSONField(default=dict)

    # Performance metrics
    success_rate = models.FloatField(default=0.0)
    error_rate = models.FloatField(default=0.0)

    # User statisfaction
    avg_rating = models.FloatField(null=True, blank=True)
    feedback_count = models.IntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ["date", "user"]
        ordering = ["-date"]
        indexes = [
            models.Index(fields=["date", "user"]),
            models.Index(fields=["-date"]),
            models.Index(fields=["user", "-date"]),
        ]

    def __str__(self):
        user_str = f"- User {self.user.username}" if self.user else "- Global"

        return f"Analytics {self.data}{user_str}"


class AgentRecommendation(models.Model):
    """Store agent recommendations and actions"""

    RECOMMENDATION_TYPES = [
        ("restock", "Restock Recommendation"),
        ("price_change", "Price Change Suggestion"),
        ("marketing_campaign", "Marketing Campaign"),
        ("inventory_optimization", "Inventory Optimization"),
        ("customer_retention", "Customer Retection Action"),
        ("fraud_alert", "Fraud Alert"),
        ("content_update", "Content Update"),
    ]

    PRIORITY_LEVELS = [
        ("low", "Low"),
        ("medium", "Medium"),
        ("high", "High"),
        ("critical", "Critical"),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    agent = models.ForeignKey(
        Agent, on_delete=models.CASCADE, related_name="recommendations"
    )
    recommendation_type = models.CharField(max_length=50, choices=RECOMMENDATION_TYPES)
    title = models.CharField(max_length=200)
    description = models.TextField()
    priority = models.CharField(
        max_length=20, choices=PRIORITY_LEVELS, default="medium"
    )
    # Generic relation to any model
    content_type = models.ForeignKey(
        ContentType, on_delete=models.CASCADE, null=True, blank=True
    )
    object_id = models.CharField(max_length=100, null=True, blank=True)
    related_object = GenericForeignKey("content_type", "object_id")

    data = models.JSONField(default=dict)
    confidence_score = models.FloatField(default=0.0)
    estimated_impact = models.JSONField(default=dict)

    is_approved = models.BooleanField(default=False)
    is_implemented = models.BooleanField(default=False)

    approved_by = models.ForeignKey(
        "authentication.CustomUser",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="approved_recommendations",
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-priority", "-created_at"]
