import 'package:stylish_admin/core/constants/api_endpoints.dart';
import 'package:stylish_admin/core/errors/exceptions.dart';
import 'package:stylish_admin/core/network/api_client.dart';
import 'package:stylish_admin/features/chat/data/models/chat_analytics_model.dart';
import 'package:stylish_admin/features/chat/data/models/chat_feedback_model.dart';
import 'package:stylish_admin/features/chat/data/models/chat_health_model.dart';
import 'package:stylish_admin/features/chat/data/models/chat_response_model.dart';
import 'package:stylish_admin/features/chat/data/models/chat_session_model.dart';
import 'package:stylish_admin/features/chat/data/models/paginated_messages_model.dart';
import 'package:stylish_admin/features/chat/data/models/paginated_session_model.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_feedback_entity.dart';

abstract class ChatRemoteDatasource {
  Future<ChatResponseModel> sendQuery(
    String query, {
    String? sessionId,
    Map<String, dynamic>? context,
  });
  Future<ChatSessionModel> createSession({Map<String, dynamic>? context});
  Future<PaginatedSessionModel> getSessions({required int page});
  Future<PaginatedMessagesModel> getSessionMessages(
    String sessionId, {
    required int page,
    required int pageSize,
  });
  Future<void> clearSessionMessages(String sessionId);
  Future<void> sendFeedback(ChatFeedbackEntity feedback);
  Future<ChatAnalyticsModel> getAnalytics({int days});
  Future<ChatHealthModel> getHealthStatus();
}

class ChatRemoteDataSourceImpl implements ChatRemoteDatasource {
  final ApiClient client;

  ChatRemoteDataSourceImpl({required this.client});
  @override
  Future<void> clearSessionMessages(String sessionId) async {
    final endpoint = '${ApiEndpoints.chatSessions}$sessionId/clear_messages/';
    await client.delete(endpoint);
  }

  @override
  Future<ChatSessionModel> createSession({
    Map<String, dynamic>? context,
  }) async {
    final data = await client.post(
      ApiEndpoints.chatSessions,
      data: {'context': context ?? {}},
    );
    return ChatSessionModel.fromJson(data);
  }

  @override
  Future<ChatAnalyticsModel> getAnalytics({int days = 30}) async {
    final endpoint = '${ApiEndpoints.chatAnalyticsDashboard}?days=$days';
    final data = await client.get(endpoint);
    return ChatAnalyticsModel.fromJson(data);
  }

  @override
  Future<ChatHealthModel> getHealthStatus() async {
    final data = await client.get(ApiEndpoints.chatHealthStatus);
    return ChatHealthModel.fromJson(data);
  }

  @override
  Future<PaginatedMessagesModel> getSessionMessages(
    String sessionId, {
    required int page,
    required int pageSize,
  }) async {
    final endpoint =
        '${ApiEndpoints.chatSessions}$sessionId/messages/?page=$page&page_size=$pageSize';
    final data = await client.get(endpoint);
    return PaginatedMessagesModel.fromJson(data);
  }

  @override
  Future<PaginatedSessionModel> getSessions({required int page}) async {
    try {
      final data = await client.get('${ApiEndpoints.chatSessions}?page=$page');
      return PaginatedSessionModel.fromJson(data);
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: 'Failed to parse chat sessions: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> sendFeedback(ChatFeedbackEntity feedback) async {
    final feedbackModel = ChatFeedbackModel(
      messageId: feedback.messageId,
      feedbackType: feedback.feedbackType,
      rating: feedback.rating,
      reason: feedback.reason,
      comment: feedback.comment,
    );
    await client.post(ApiEndpoints.chatFeedback, data: feedbackModel.toJson());
  }

  @override
  Future<ChatResponseModel> sendQuery(
    String query, {
    String? sessionId,
    Map<String, dynamic>? context,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'query': query,
        if (sessionId != null) 'session_id': sessionId,
        if (context != null) 'context': context,
      };
      final data = await client.post(ApiEndpoints.chatQuery, data: requestData);

      return ChatResponseModel.fromJson(data);
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: 'Failed to send chat query: ${e.toString()}',
      );
    }
  }
}
