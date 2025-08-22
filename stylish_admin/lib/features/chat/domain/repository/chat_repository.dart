import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_analytics_entity.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_feedback_entity.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_health_entity.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_response_entity.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_session_entity.dart';
import 'package:stylish_admin/features/chat/domain/entities/paginated_message_entity.dart';
import 'package:stylish_admin/features/chat/domain/entities/paginated_session_entity.dart';

abstract class ChatRepository {
  Future<Either<Failure, ChatResponseEntity>> sendQuery(
    String query, {
    String? sessionId,
    Map<String, dynamic>? context,
  });

  Future<Either<Failure, ChatSessionEntity>> createSession({
    Map<String, dynamic>? context,
  });

  Future<Either<Failure, PaginatedSessionEntity>> getSessions({
    required int page,
  });
  Future<Either<Failure, PaginatedMessageEntity>> getSessionMessages(
    String sessionId, {
    required int page,
    required int pageSize,
  });

  Future<Either<Failure, void>> clearSessionMessages(String sessionId);
  Future<Either<Failure, void>> sendFeeback(ChatFeedbackEntity feedback);
  Future<Either<Failure, ChatAnalyticsEntity>> getAnalytics({int days});
  Future<Either<Failure, ChatHealthEntity>> getHealthStatus();
}
