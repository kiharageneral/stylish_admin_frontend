from django.contrib import admin
from .models import (AnalyticsEvent, RevenueMetrics, AnalyticsSummary, UserSession, AnalyticsDashboard, UserBehavior)

@admin.register(AnalyticsEvent)
class AnalyticsEventAdmin(admin.ModelAdmin):
    list_display = ('event_type', 'user', 'created_at')
    list_filter = ('event_type',)
    
@admin.register(RevenueMetrics)
class RevenueMetricsAdmin(admin.ModelAdmin):
    list_display = ('date', 'total_revenue', 'order_count')
    list_filter = ('date',)
    
@admin.register(AnalyticsSummary)
class AnalyticsSummaryAdmin(admin.ModelAdmin):
    list_display = ('date', 'total_views', 'conversion_rate')
    list_filter = ('date',)
    
@admin.register(UserSession)
class UserSessionAdmin(admin.ModelAdmin):
    list_display = ('user', 'start_time', 'pages_viewed')
    search_fields = ('user__email',)
    
@admin.register(AnalyticsDashboard)
class AnalyticsDashboardAdmin(admin.ModelAdmin):
    list_display = ('date', 'total_revenue', 'total_orders')
    list_filter = ('date',)
    
@admin.register(UserBehavior)
class UserBehaviorAdmin(admin.ModelAdmin):
    list_display = ('user', 'page_views', 'created_at')
    search_fields = ('user__email',)