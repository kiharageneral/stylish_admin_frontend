import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_response_entity.dart';

class ChatMessageEntity extends Equatable {
  final String id;
  final String query;
  final String response;
  final String intent;
  final String intentDisplay;
  final double executionTime;
  final double confidenceScore;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final String createdAtFormatted;

  const ChatMessageEntity({
    required this.id,
    required this.query,
    required this.response,
    required this.intent,
    required this.intentDisplay,
    required this.executionTime,
    required this.confidenceScore,
    this.metadata,
    required this.createdAt,
    required this.createdAtFormatted,
  });

  factory ChatMessageEntity.fromResponse(ChatResponseEntity response) {
    final display = response.intent
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
    return ChatMessageEntity(
      id: response.messageId,
      query: response.query,
      response: response.response,
      intent: response.intent,
      intentDisplay: display,
      executionTime: response.executionTime,
      confidenceScore: response.confidenceScore ?? 0.0,
      createdAt: response.timestamp,
      createdAtFormatted: DateFormat('h:mm a').format(response.timestamp),
      metadata: response.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    query,
    response,
    intent,
    intentDisplay,
    executionTime,
    confidenceScore,
    metadata,
    createdAt,
    createdAtFormatted,
  ];
}
