import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/chat/domain/entities/paginated_message_entity.dart';
import 'package:stylish_admin/features/chat/domain/repository/chat_repository.dart';

class GetSessionMessagesUsecase
    implements UseCase<PaginatedMessageEntity, GetSessionMessagesParams> {
  final ChatRepository repository;

  GetSessionMessagesUsecase(this.repository);
  @override
  Future<Either<Failure, PaginatedMessageEntity>> call(
    GetSessionMessagesParams params,
  ) async {
    return await repository.getSessionMessages(
      params.sessionId,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}

class GetSessionMessagesParams extends Equatable {
  final String sessionId;
  final int page;
  final int pageSize;

  const GetSessionMessagesParams({
    required this.sessionId,
    required this.page,
    required this.pageSize,
  });

  @override
  List<Object?> get props => [sessionId, page, pageSize];
}
