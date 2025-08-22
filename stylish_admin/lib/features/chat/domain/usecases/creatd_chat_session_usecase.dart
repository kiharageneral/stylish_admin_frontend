import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_session_entity.dart';
import 'package:stylish_admin/features/chat/domain/repository/chat_repository.dart';

class CreateChatSessionUsecase
    implements UseCase<ChatSessionEntity, CreateChatSessionParams> {
  final ChatRepository repository;

  CreateChatSessionUsecase(this.repository);
  @override
  Future<Either<Failure, ChatSessionEntity>> call(
    CreateChatSessionParams params,
  ) async {
    return await repository.createSession(context: params.context);
  }
}

class CreateChatSessionParams extends Equatable {
  final Map<String, dynamic>? context;

  const CreateChatSessionParams({this.context});
  @override
  List<Object?> get props => [context];
}
