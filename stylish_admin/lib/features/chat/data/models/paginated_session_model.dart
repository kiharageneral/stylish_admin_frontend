import 'package:stylish_admin/features/chat/data/models/chat_session_model.dart';
import 'package:stylish_admin/features/chat/domain/entities/paginated_session_entity.dart';

class PaginatedSessionModel extends PaginatedSessionEntity {
  const PaginatedSessionModel({
    required super.sessions,
    required super.totalCount,
    required super.hasNext,
  });

  factory PaginatedSessionModel.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      final results =
          (json['results'] as List<dynamic>?)
              ?.map((e) => ChatSessionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      return PaginatedSessionModel(
        sessions: results,
        totalCount: json['count'] as int? ?? 0,
        hasNext: json['next'] != null,
      );
    } else if (json is List<dynamic>) {
      final results = json
          .map((e) => ChatSessionModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return PaginatedSessionModel(
        sessions: results,
        totalCount: results.length,
        hasNext: false,
      );
    } else {
      throw FormatException(
        'Invalid JSON format for PaginatedSessionModel. Expected Map or List, but got ${json.runtimeType}',
      );
    }
  }
}
