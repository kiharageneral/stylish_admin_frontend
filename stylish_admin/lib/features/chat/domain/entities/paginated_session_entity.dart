import 'package:equatable/equatable.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_session_entity.dart';

class PaginatedSessionEntity extends Equatable {
  final List<ChatSessionEntity> sessions;
  final int totalCount;
  final bool hasNext;

  const PaginatedSessionEntity({
    required this.sessions,
    required this.totalCount,
    required this.hasNext,
  });

  @override
  List<Object?> get props => [sessions, totalCount, hasNext];
}
