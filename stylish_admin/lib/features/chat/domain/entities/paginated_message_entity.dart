import 'package:equatable/equatable.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_message_entity.dart';

class PaginatedMessageEntity extends Equatable {
  final List<ChatMessageEntity> messages;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasNext;
  final bool hasPrevious;

  const PaginatedMessageEntity({
    required this.messages,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasNext,
    required this.hasPrevious,
  });

  /// Calculate total pages based on total count and page size
  int get totalPages => (totalCount / pageSize).ceil();

  /// Check if this is the first page
  bool get isFirstPage => page == 1;

  /// Check if this is the last page
  bool get isLastPage => !hasNext;

  /// Get the starting index for current page items
  int get startIndex => (page - 1) * pageSize + 1;

  /// Get the ending index for current page items
  int get endIndex {
    final calculated = page * pageSize;
    return calculated > totalCount ? totalCount : calculated;
  }

  PaginatedMessageEntity copyWith({
    List<ChatMessageEntity>? messages,
    int? totalCount,
    int? page,
    int? pageSize,
    bool? hasNext,
    bool? hasPrevious,
  }) {
    return PaginatedMessageEntity(
      messages: messages ?? this.messages,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasNext: hasNext ?? this.hasNext,
      hasPrevious: hasPrevious ?? this.hasPrevious,
    );
  }

  factory PaginatedMessageEntity.empty() {
    return const PaginatedMessageEntity(
      messages: [],
      totalCount: 0,
      page: 1,
      pageSize: 20,
      hasNext: false,
      hasPrevious: false,
    );
  }

  @override
  List<Object?> get props => [
    messages,
    totalCount,
    page,
    pageSize,
    hasNext,
    hasPrevious,
  ];

  @override
  String toString() {
    return 'PaginatedMessageEntity (messages: ${messages.length}, totalcount: $totalCount, page: $page, pageSize: $pageSize, hasNext: $hasNext, hasPrevious: $hasPrevious)';
  }
}
