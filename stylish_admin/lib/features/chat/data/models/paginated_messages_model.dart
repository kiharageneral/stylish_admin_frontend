import 'package:stylish_admin/features/chat/data/models/chat_message_model.dart';
import 'package:stylish_admin/features/chat/domain/entities/paginated_message_entity.dart';

class PaginatedMessagesModel extends PaginatedMessageEntity {
  const PaginatedMessagesModel({
    required super.messages,
    required super.totalCount,
    required super.page,
    required super.pageSize,
    required super.hasNext,
    required super.hasPrevious,
  });

  factory PaginatedMessagesModel.fromJson(Map<String, dynamic> json) {
    final page = json['page'] as int? ?? 1;
    final pageSize = json['page_size'] as int? ?? 20;
    final totalCount = json['total_count'] as int? ?? 0;

    return PaginatedMessagesModel(
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map(
                (item) =>
                    ChatMessageModel.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
      hasNext: json['has_next'] as bool? ?? false,
      hasPrevious: page > 1,
    );
  }

  factory PaginatedMessagesModel.fromEntity(PaginatedMessageEntity entity) {
    return PaginatedMessagesModel(
      messages: entity.messages,
      totalCount: entity.totalCount,
      page: entity.page,
      pageSize: entity.pageSize,
      hasNext: entity.hasNext,
      hasPrevious: entity.hasPrevious,
    );
  }
}
