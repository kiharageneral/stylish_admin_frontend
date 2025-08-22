from django.contrib import admin

from .models import (
    Agent,
    AgentExecution,
    AgentRecommendation,
    ChatAnalytics,
    ChatFeedback,
    ChatMessage,
    ChatSession,
)

@admin.register(Agent)
class AgentAdmin(admin.ModelAdmin):
    list_display = (
        'name', 
        'agent_type', 
        'is_active', 
        'total_executions', 
        'successful_executions', 
        'success_rate', 
        'last_execution', 
        'created_at'
    )
    list_filter = (
        'agent_type', 
        'is_active'
    )
    search_fields = (
        'name', 
        'description'
    )
    
    readonly_fields = (
        'created_at', 
        'last_execution', 
        'total_executions', 
        'successful_executions', 
        'avg_execution_time', 
        'success_rate'
    )
    
    fieldsets = (
        (None, {
            'fields': ('name', 'agent_type', 'description', 'is_active', 'configuration')
        }), 
        ('Performance Metrics', {
            'fields': (
                'total_executions', 
                'successful_executions', 
                'avg_execution_time', 
                'success_rate', 
                'last_execution', 
                'last_error'
            ), 
            'classes':('collapse',)
        }), 
        ('Timestamps', {
            'fields': ('created_at',), 
            'classes': ('collapse',)
        }),
    )
    

@admin.register(AgentExecution)
class AgentExecutionAdmin(admin.ModelAdmin):
    """
    Admin configuration for the AgentExecution model.
    Allows tracking and reviewing individual agent execution instances.
    """
    list_display = (
        'agent', 
        'status', 
        'execution_time', 
        'started_at', 
        'completed_at'
    )
    list_filter = (
        'status', 
        'agent__agent_type'
    )
    search_fields = (
        'agent__name', 
        'error_message'
    )
    readonly_fields = (
        'execution_time', 
        'started_at', 
        'completed_at'
    )
    fieldsets = (
        (None, {
            'fields': ('agent', 'status', 'input_data', 'output_data', 'error_message')
        }),
        ('Execution Details', {
            'fields': ('execution_time', 'started_at', 'completed_at'),
            'classes': ('collapse',)
        }),
    )

@admin.register(AgentRecommendation)
class AgentRecommendationAdmin(admin.ModelAdmin):
    """
    Admin configuration for the AgentRecommendation model.
    Manages and tracks AI-generated recommendations, including approval and implementation.
    """
    list_display = (
        'title', 
        'agent', 
        'recommendation_type', 
        'priority', 
        'confidence_score', 
        'is_approved', 
        'is_implemented', 
        'approved_by', 
        'created_at'
    )
    list_filter = (
        'recommendation_type', 
        'priority', 
        'is_approved', 
        'is_implemented', 
        'agent__agent_type'
    )
    search_fields = (
        'title', 
        'description', 
        'agent__name'
    )
    actions = (
        'approve_recommendations', 
        'mark_implemented'
    )
    readonly_fields = (
        'created_at', 
        'approved_by'
    )
    fieldsets = (
        (None, {
            'fields': ('agent', 'recommendation_type', 'title', 'description', 'priority')
        }),
        ('Details', {
            'fields': ('data', 'confidence_score', 'estimated_impact'),
        }),
        ('Status', {
            'fields': ('is_approved', 'approved_by', 'is_implemented'),
        }),
        ('Related Object', {
            'fields': ('content_type', 'object_id'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at',),
            'classes': ('collapse',)
        }),
    )

    def approve_recommendations(self, request, queryset):
        """Action to approve selected recommendations."""
        queryset.update(is_approved=True, approved_by=request.user)
    approve_recommendations.short_description = "Approve selected recommendations"
    
    def mark_implemented(self, request, queryset):
        """Action to mark selected recommendations as implemented."""
        queryset.update(is_implemented=True)
    mark_implemented.short_description = "Mark as implemented"


@admin.register(ChatSession)
class ChatSessionAdmin(admin.ModelAdmin):
    """
    Admin configuration for the ChatSession model.
    Manages chat sessions, allowing review of session details and activity.
    """
    list_display = (
        'session_id', 
        'user', 
        'title', 
        'is_active', 
        'is_archived', 
        'message_count', 
        'last_activity', 
        'created_at'
    )
    list_filter = (
        'is_active', 
        'is_archived', 
        'user'
    )
    search_fields = (
        'session_id', 
        'title', 
        'user__username'
    )
    readonly_fields = (
        'created_at', 
        'updated_at', 
        'last_activity', 
        'archived_at', 
        'message_count'
    )
    fieldsets = (
        (None, {
            'fields': ('session_id', 'user', 'title', 'is_active', 'is_archived', 'archived_at')
        }),
        ('Settings', {
            'fields': ('context_window_size', 'metadata'),
            'classes': ('collapse',)
        }),
        ('Activity', {
            'fields': ('last_activity', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    """
    Admin configuration for the ChatMessage model.
    Provides detailed view and management of individual chat messages.
    """
    list_display = (
        'session', 
        'message_type', 
        'status', 
        'intent', 
        'response_preview', 
        'execution_time', 
        'confidence_score', 
        'is_deleted', 
        'created_at'
    )
    list_filter = (
        'message_type', 
        'status', 
        'intent', 
        'is_deleted', 
        'session__user'
    )
    search_fields = (
        'query', 
        'response', 
        'session__session_id', 
        'session__user__username'
    )
    readonly_fields = (
        'created_at', 
        'updated_at', 
        'edited_at', 
        'deleted_at', 
        'execution_time', 
        'confidence_score'
    )
    fieldsets = (
        (None, {
            'fields': ('session', 'message_type', 'status', 'intent')
        }),
        ('Content', {
            'fields': ('query', 'response', 'parent_message'),
        }),
        ('Performance & Confidence', {
            'fields': ('execution_time', 'confidence_score'),
            'classes': ('collapse',)
        }),
        ('Metadata & Errors', {
            'fields': ('metadata', 'error_details'),
            'classes': ('collapse',)
        }),
        ('Management', {
            'fields': ('is_edited', 'edited_at', 'is_deleted', 'deleted_at'),
            'classes': ('collapse',)
        }),
        ('User Info', {
            'fields': ('user_ip', 'user_agent'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

@admin.register(ChatFeedback)
class ChatFeedbackAdmin(admin.ModelAdmin):
    """
    Admin configuration for the ChatFeedback model.
    Allows review and analysis of user feedback on chat messages.
    """
    list_display = (
        'message', 
        'user', 
        'feedback_type', 
        'rating', 
        'reason', 
        'created_at'
    )
    list_filter = (
        'feedback_type', 
        'rating', 
        'reason', 
        'user'
    )
    search_fields = (
        'comment', 
        'message__query', 
        'message__response', 
        'user__username'
    )
    readonly_fields = (
        'created_at', 
        'ip_address', 
        'user_agent'
    )
    fieldsets = (
        (None, {
            'fields': ('message', 'user', 'feedback_type', 'rating', 'reason', 'comment')
        }),
        ('Metadata', {
            'fields': ('ip_address', 'user_agent', 'created_at'),
            'classes': ('collapse',)
        }),
    )

@admin.register(ChatAnalytics)
class ChatAnalyticsAdmin(admin.ModelAdmin):
    """
    Admin configuration for the ChatAnalytics model.
    Provides an interface to view aggregated chat analytics data.
    """
    list_display = (
        'date', 
        'user', 
        'total_queries', 
        'total_sessions', 
        'avg_response_time', 
        'avg_confidence_score', 
        'success_rate', 
        'error_rate', 
        'avg_rating', 
        'feedback_count', 
        'created_at'
    )
    list_filter = (
        'date', 
        'user'
    )
    search_fields = (
        'user__username',
    )
    readonly_fields = (
        'created_at', 
        'updated_at'
    )
    fieldsets = (
        (None, {
            'fields': ('date', 'user')
        }),
        ('Usage Metrics', {
            'fields': ('total_queries', 'total_sessions', 'avg_response_time', 'avg_confidence_score'),
        }),
        ('Performance', {
            'fields': ('success_rate', 'error_rate'),
        }),
        ('User Satisfaction', {
            'fields': ('avg_rating', 'feedback_count'),
        }),
        ('Intent Distribution', {
            'fields': ('intent_distribution',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

