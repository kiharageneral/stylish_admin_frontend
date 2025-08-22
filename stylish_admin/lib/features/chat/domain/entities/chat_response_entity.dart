import 'package:equatable/equatable.dart';

abstract class ChatResponseEntity extends Equatable {
  final String query;
  final String intent;
  final String response;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final double executionTime;
  final double? confidenceScore;
  final String sessionId;
  final String? error;
  final Map<String, dynamic>? metadata;
  final String messageId;

  const ChatResponseEntity({
    required this.query,
    required this.intent,
    required this.response,
    required this.data,
    required this.timestamp,
    required this.executionTime,
    this.confidenceScore,
    required this.sessionId,
    this.error,
    this.metadata,
    required this.messageId,
  });

  bool get hasError => error != null && error!.isNotEmpty;

  @override
  List<Object?> get props => [
    query,
    intent,
    response,
    data,
    timestamp,
    executionTime,
    confidenceScore,
    sessionId,
    error,
    metadata,
    messageId,
  ];
}
