import 'package:stylish_admin/features/chat/domain/entities/chat_analytics_entity.dart';

class ChatAnalyticsModel extends ChatAnalyticsEntity {
  const ChatAnalyticsModel({
    required super.periodDays,
    required super.totalSessions,
    required super.totalMessages,
    required super.avgSessionLength,
    required super.avgResponseTime,
    required super.mostCommonIntents,
    required super.confidenceDistribution,
    required super.successRate,
  });

  factory ChatAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return ChatAnalyticsModel(
      periodDays: json['period_days'],
      totalSessions: json['total_sessions'],
      totalMessages: json['total_messages'],
      avgSessionLength: (json['avg_session_length'] as num).toDouble(),
      avgResponseTime: (json['avg_response_time'] as num).toDouble(),
      mostCommonIntents: List<Map<String, dynamic>>.from(
        json['most_common_intents'],
      ),
      confidenceDistribution: Map<String, dynamic>.from(
        json['confidence_distribution'],
      ),
      successRate: (json['success_rate'] as num).toDouble(),
    );
  }
}
