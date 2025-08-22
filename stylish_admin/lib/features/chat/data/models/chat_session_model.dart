import 'package:stylish_admin/features/chat/data/models/chat_message_model.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_session_entity.dart';

class ChatSessionModel extends ChatSessionEntity {
  const ChatSessionModel({
    required super.sessionId,
    required super.userId,
    required super.createdAt,
    required super.createdAtFormatted,
    required super.messageCount,
    required super.lastActivity,
    required super.messages,
  });

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      sessionId: json['session_id'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      createdAtFormatted: json['created_at_formatted'],
      messageCount: json['message_count'],
      lastActivity: json['last_activity'],
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
