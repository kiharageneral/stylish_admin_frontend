import 'package:stylish_admin/features/chat/domain/entities/chat_feedback_entity.dart';

class ChatFeedbackModel extends ChatFeedbackEntity {
  const ChatFeedbackModel({
    required super.messageId,
    required super.feedbackType,
    required super.rating,
    super.reason,
    super.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'feedback_type': feedbackType,
      'rating': rating,
      if (reason != null) 'reason': reason,
      if (comment != null) 'comment': comment,
    };
  }
}
