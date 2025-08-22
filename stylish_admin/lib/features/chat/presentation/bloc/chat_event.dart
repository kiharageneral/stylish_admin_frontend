part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class GetChatHealth extends ChatEvent {}

class GetChatSessions extends ChatEvent {
  final bool isRefresh;

  const GetChatSessions({this.isRefresh = false});
  @override
  List<Object?> get props => [isRefresh];
}

class GetMoreChatSessions extends ChatEvent {}

class GetSessionMessages extends ChatEvent {
  final String sessionId;
  final int page;
  final int pageSize;

  const GetSessionMessages(this.sessionId, {this.page = 1, this.pageSize = 20});

  @override
  List<Object?> get props => [sessionId, page, pageSize];
}

class CreateChatSession extends ChatEvent {
  final Map<String, dynamic>? context;

  const CreateChatSession({this.context});

  @override
  List<Object?> get props => [context];
}

class SendChatQuery extends ChatEvent {
  final String query;
  final String? sessionId;
  final Map<String, dynamic>? context;

  const SendChatQuery(this.query, {this.sessionId, this.context});

  @override
  List<Object?> get props => [query, sessionId, context];
}

class SendChatFeedback extends ChatEvent {
  final ChatFeedbackEntity feedback;

  const SendChatFeedback(this.feedback);

  @override
  List<Object?> get props => [feedback];
}

class GetChatAnalytics extends ChatEvent {
  final int days;

  const GetChatAnalytics({this.days = 30});

  @override
  List<Object?> get props => [days];
}
