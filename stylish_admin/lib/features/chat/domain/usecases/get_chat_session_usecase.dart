import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/chat/domain/entities/paginated_session_entity.dart';
import 'package:stylish_admin/features/chat/domain/repository/chat_repository.dart';

class GetChatSessionUsecase
    implements UseCase<PaginatedSessionEntity, GetChatSessionsParams> {
  final ChatRepository repository;

  GetChatSessionUsecase(this.repository);
  @override
  Future<Either<Failure, PaginatedSessionEntity>> call(
    GetChatSessionsParams params,
  ) async {
    return await repository.getSessions(page: params.page);
  }
}

class GetChatSessionsParams extends Equatable {
  final int page;

  const GetChatSessionsParams({required this.page});

  @override
  List<Object?> get props => [page];
}
