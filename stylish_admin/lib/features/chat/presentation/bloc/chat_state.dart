part of 'chat_bloc.dart';

enum ChatStatus { initial, loading, sending, loadingMore, success, failure }

enum MessageStatus { sending, processing, completed, failed }

class ChatState extends Equatable {
  final ChatStatus status;
  final ChatHealthEntity? chatHealth;
  final PaginatedMessageEntity? sessionMessages;
  final ChatSessionEntity? currentSession;
  final ChatResponseEntity? chatResponse;
  final ChatAnalyticsEntity? analytics;
  final Failure? error;
  final List<ChatSessionEntity> sessions;
  final int sessionsPage;
  final bool hasMoreSessions;
  final MessageStatus? messageStatus;
  final String? pendingQuery;
  final bool isSessionInitialized;

  const ChatState({
    this.status = ChatStatus.initial,
    this.chatHealth,
    this.sessionMessages,
    this.currentSession,
    this.chatResponse,
    this.analytics,
    this.error,
    this.sessions = const [],
    this.sessionsPage = 1,
    this.hasMoreSessions = true,
    this.messageStatus,
    this.pendingQuery,
    this.isSessionInitialized = false,
  });

  ChatState copyWith({
    ChatStatus? status,
    ChatHealthEntity? chatHealth,
    List<ChatSessionEntity>? sessions,
    int? sessionsPage,
    bool? hasMoreSessions,
    PaginatedMessageEntity? sessionMessages,
    ChatSessionEntity? currentSession,
    ChatResponseEntity? chatResponse,
    ChatAnalyticsEntity? analytics,
    Failure? error,
    MessageStatus? messageStatus,
    String? pendingQuery,
    bool? isSessionInitialized,
    bool clearError = false,
    bool clearMessageStatus = false,
    bool clearPendingQuery = false,
  }) {
    return ChatState(
      status: status ?? this.status,
      chatHealth: chatHealth ?? this.chatHealth,
      sessions: sessions ?? this.sessions,
      hasMoreSessions: hasMoreSessions ?? this.hasMoreSessions,
      sessionMessages: sessionMessages ?? this.sessionMessages,
      currentSession: currentSession ?? this.currentSession,
      chatResponse: chatResponse ?? this.chatResponse,
      analytics: analytics ?? this.analytics,
      error: clearError ? null : error ?? this.error,
      messageStatus: clearMessageStatus
          ? null
          : messageStatus ?? this.messageStatus,
      pendingQuery: clearPendingQuery
          ? null
          : pendingQuery ?? this.pendingQuery,
      isSessionInitialized: isSessionInitialized ?? this.isSessionInitialized,
    );
  }

  @override
  List<Object?> get props => [
    status,
    chatHealth,
    sessions,
    sessionsPage,
    hasMoreSessions,
    sessionMessages,
    currentSession,
    chatResponse,
    analytics,
    error,
    messageStatus,
    pendingQuery,
    isSessionInitialized,
  ];
}
