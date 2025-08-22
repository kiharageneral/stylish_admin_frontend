import 'package:dartz/dartz.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_health_entity.dart';
import 'package:stylish_admin/features/chat/domain/repository/chat_repository.dart';

class GetChatHealthUsecase implements UseCase<ChatHealthEntity, NoParams> {
  final ChatRepository repository;

  GetChatHealthUsecase(this.repository);
  @override
  Future<Either<Failure, ChatHealthEntity>> call(NoParams params) async {
    return await repository.getHealthStatus();
  }
}
