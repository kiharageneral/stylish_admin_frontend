import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_feedback_entity.dart';
import 'package:stylish_admin/features/chat/domain/repository/chat_repository.dart';

class SendChatFeedbackUsecase implements UseCase<void, SendChatFeedbackParams> {
  final ChatRepository repository;

  SendChatFeedbackUsecase(this.repository);
  @override
  Future<Either<Failure, void>> call(SendChatFeedbackParams params) async {
    return await repository.sendFeeback(params.feedback);
  }
}

class SendChatFeedbackParams extends Equatable {
  final ChatFeedbackEntity feedback;

  const SendChatFeedbackParams({required this.feedback});
  @override
  List<Object?> get props => [feedback];
}
