import 'package:equatable/equatable.dart';

class ChatFeedbackEntity extends Equatable {
  final String messageId;
  final String feedbackType;
  final int rating;
  final String? reason;
  final String? comment;

  const ChatFeedbackEntity({
    required this.messageId,
    required this.feedbackType,
    required this.rating,
    this.reason,
    this.comment,
  });
  @override
  List<Object?> get props => [messageId, feedbackType, rating, reason, comment];
}
