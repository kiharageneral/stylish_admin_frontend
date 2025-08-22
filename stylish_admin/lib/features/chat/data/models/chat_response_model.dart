import 'package:stylish_admin/features/chat/domain/entities/chat_response_entity.dart';

class ChatResponseModel extends ChatResponseEntity {
  const ChatResponseModel({
    required super.query,
    required super.intent,
    required super.response,
    required super.data,
    required super.timestamp,
    required super.executionTime,
    required super.sessionId,
    super.confidenceScore,
    super.error,
    super.metadata,
    required super.messageId,
  });

  factory ChatResponseModel.fromJson(Map<String, dynamic> json) {
    return ChatResponseModel(
      query: json['query'] as String,
      intent: json['intent'] as String,
      response: json['response'] as String,
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      timestamp: DateTime.parse(json['timestamp'] as String),
      executionTime: (json['execution_time'] as num).toDouble(),
      sessionId: json['session_id'] as String,
      messageId: json['message_id'] as String,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      error: json['error'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'intent': intent,
      'response': response,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'execution_time': executionTime,
      'session_id': sessionId,
      'confidence_score': confidenceScore,
      'error': error,
      'metadata': metadata,
      'message_id': messageId,
    };
  }
}
