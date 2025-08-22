import 'package:equatable/equatable.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_message_entity.dart';

class ChatSessionEntity extends Equatable {
  final String sessionId;
  final int userId;
  final DateTime createdAt;
  final String createdAtFormatted;
  final int messageCount;
  final String lastActivity;
  final List<ChatMessageEntity> messages;

  const ChatSessionEntity({
    required this.sessionId,
    required this.userId,
    required this.createdAt,
    required this.createdAtFormatted,
    required this.messageCount,
    required this.lastActivity,
    this.messages = const [],
  });
  @override
  List<Object?> get props => [
    sessionId,
    userId,
    createdAt,
    createdAtFormatted,
    messageCount,
    lastActivity,
    messages,
  ];
}
