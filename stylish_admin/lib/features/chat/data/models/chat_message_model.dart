import 'package:stylish_admin/features/chat/domain/entities/chat_message_entity.dart';

class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.query,
    required super.response,
    required super.intent,
    required super.intentDisplay,
    required super.executionTime,
    required super.confidenceScore,
    super.metadata,
    required super.createdAt,
    required super.createdAtFormatted,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'].toString(),
      query: json['query'],
      response: json['response'],
      intent: json['intent'],
      intentDisplay: json['intent_display'],
      executionTime: (json['execution_time'] as num).toDouble(),
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      createdAtFormatted: json['created_at_formatted'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }
}
