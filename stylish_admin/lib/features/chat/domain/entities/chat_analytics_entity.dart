import 'package:equatable/equatable.dart';

class ChatAnalyticsEntity extends Equatable {
  final int periodDays;
  final int totalSessions;
  final int totalMessages;
  final double avgSessionLength;
  final double avgResponseTime;
  final List<Map<String, dynamic>> mostCommonIntents;
  final Map<String, dynamic> confidenceDistribution;
  final double? successRate;

  const ChatAnalyticsEntity({
    required this.periodDays,
    required this.totalSessions,
    required this.totalMessages,
    required this.avgSessionLength,
    required this.avgResponseTime,
    required this.mostCommonIntents,
    required this.confidenceDistribution,
    this.successRate,
  });

  @override
  List<Object?> get props => [
    periodDays,
    totalSessions,
    totalMessages,
    avgSessionLength,
    avgResponseTime,
    mostCommonIntents,
    confidenceDistribution,
    successRate,
  ];
}
