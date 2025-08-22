from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AgentExecutionViewSet, AgentViewSet, AgentRecommendationViewSet
from .chat_api_views import (
    ChatSessionViewSet,
    ChatQueryViewSet,
    ChatFeedbackViewSet,
    ChatAnalyticsViewSet,
    ChatHealthViewSet
)

router = DefaultRouter()
router.register(r'agents', AgentViewSet)
router.register(r'recommendations', AgentRecommendationViewSet)
router.register(r'executions', AgentExecutionViewSet) 
router.register(r'sessions', ChatSessionViewSet, basename='chat-sessions')
router.register(r'query', ChatQueryViewSet, basename='chat-query')
router.register(r'feedback', ChatFeedbackViewSet, basename='chat-feedback')
router.register(r'analytics', ChatAnalyticsViewSet, basename='chat-analytics')
router.register(r'health', ChatHealthViewSet, basename='chat-health')


urlpatterns = [
    path('', include(router.urls)),
]

