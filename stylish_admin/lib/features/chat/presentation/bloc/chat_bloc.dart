import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:stylish_admin/core/errors/failures.dart';
import 'package:stylish_admin/core/usecases/usecase.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_analytics_entity.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_feedback_entity.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_health_entity.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_message_entity.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_response_entity.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_session_entity.dart';
import 'package:stylish_admin/features/chat/domain/entities/paginated_message_entity.dart';
import 'package:stylish_admin/features/chat/domain/usecases/chat_usecases.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetChatHealthUsecase _getChatHealthUsecase;
  final GetChatSessionUsecase _getChatSessionUsecase;
  final GetSessionMessagesUsecase _getSessionMessagesUsecase;
  final CreateChatSessionUsecase _createChatSessionUsecase;
  final SendChatFeedbackUsecase _sendChatFeedbackUsecase;
  final SendChatQueryUseCase _sendChatQueryUseCase;
  final GetChatAnalyticsUsecase _getChatAnalyticsUsecase;

  bool _isCreatingSession = false;

  ChatBloc({
    required GetChatHealthUsecase getChatHealthUsecase,
    required GetChatSessionUsecase getChatSessionUsecase,
    required GetSessionMessagesUsecase getSessionMessagesUsecase,
    required CreateChatSessionUsecase createChatSessionUsecase,
    required SendChatFeedbackUsecase sendChatFeedbackUsecase,
    required SendChatQueryUseCase sendChatQueryUseCase,
    required GetChatAnalyticsUsecase getChatAnalyticsUsecase,
  }) : _getChatHealthUsecase = getChatHealthUsecase,
       _getChatSessionUsecase = getChatSessionUsecase,
       _getSessionMessagesUsecase = getSessionMessagesUsecase,
       _createChatSessionUsecase = createChatSessionUsecase,
       _sendChatFeedbackUsecase = sendChatFeedbackUsecase,
       _sendChatQueryUseCase = sendChatQueryUseCase,
       _getChatAnalyticsUsecase = getChatAnalyticsUsecase,
       super(const ChatState()) {
    on<GetChatHealth>(_onGetChatHealth);
    on<GetChatSessions>(_onGetChatSessions);
    on<GetSessionMessages>(_onGetSessionMessages);
    on<CreateChatSession>(_onCreateChatSession);
    on<SendChatQuery>(_onSendChatQuery);
    on<SendChatFeedback>(_onSendChatFeedback);
    on<GetChatAnalytics>(_onGetChatAnalytics);
    on<GetMoreChatSessions>(_onGetMoreChatSessions);
  }

  Future<void> _onGetChatHealth(
    GetChatHealth event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _getChatHealthUsecase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(error: failure)),
      (health) => emit(state.copyWith(chatHealth: health, clearError: true)),
    );
  }

  Future<void> _onGetChatSessions(
    GetChatSessions event,
    Emitter<ChatState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ChatStatus.loading,
        sessions: [],
        sessionsPage: 1,
        hasMoreSessions: true,
      ),
    );
    final result = await _getChatSessionUsecase(
      const GetChatSessionsParams(page: 1),
    );

    result.fold(
      (failure) =>
          emit(state.copyWith(status: ChatStatus.failure, error: failure)),
      (paginatedData) => emit(
        state.copyWith(
          status: ChatStatus.success,
          sessions: paginatedData.sessions,
          hasMoreSessions: paginatedData.hasNext,
          sessionsPage: 1,
        ),
      ),
    );
  }

  Future<void> _onGetMoreChatSessions(
    GetMoreChatSessions event,
    Emitter<ChatState> emit,
  ) async {
    if (state.status == ChatStatus.loadingMore || !state.hasMoreSessions) {
      return;
    }

    emit(state.copyWith(status: ChatStatus.loadingMore));

    final nextPage = state.sessionsPage + 1;

    final result = await _getChatSessionUsecase(
      GetChatSessionsParams(page: nextPage),
    );

    result.fold(
      (failure) =>
          emit(state.copyWith(status: ChatStatus.failure, error: failure)),
      (paginatedData) {
        emit(
          state.copyWith(
            status: ChatStatus.success,
            sessions: List.of(state.sessions)..addAll(paginatedData.sessions),
            hasMoreSessions: paginatedData.hasNext,
            sessionsPage: nextPage,
          ),
        );
      },
    );
  }

  Future<void> _onGetSessionMessages(
    GetSessionMessages event,
    Emitter<ChatState> emit,
  ) async {
    if (state.sessionMessages?.messages.isEmpty ?? true) {
      emit(state.copyWith(status: ChatStatus.loading));
    }

    final params = GetSessionMessagesParams(
      sessionId: event.sessionId,
      page: event.page,
      pageSize: event.pageSize,
    );
    final result = await _getSessionMessagesUsecase(params);

    result.fold(
      (failure) =>
          emit(state.copyWith(status: ChatStatus.failure, error: failure)),
      (paginatedData) {
        final List<ChatMessageEntity> flattenedMessages = [];
        for (final aiMessage in paginatedData.messages) {
          final userMessage = ChatMessageEntity(
            id: 'user_${aiMessage.id}_query',
            query: aiMessage.query,
            response: '',
            intent: 'user_query',
            intentDisplay: 'Query',
            executionTime: 0.0,
            confidenceScore: 1.0,
            createdAt: aiMessage.createdAt.subtract(
              const Duration(milliseconds: 100),
            ),
            createdAtFormatted: DateFormat('h:mm a').format(
              aiMessage.createdAt.subtract(const Duration(milliseconds: 100)),
            ),
          );

          flattenedMessages.add(userMessage);
          flattenedMessages.add(aiMessage);
        }
        final updatedPaginatedData = paginatedData.copyWith(
          messages: flattenedMessages,
          totalCount: paginatedData.totalCount * 2,
        );

        emit(
          state.copyWith(
            status: ChatStatus.success,
            sessionMessages: updatedPaginatedData,
            isSessionInitialized: true,
          ),
        );
      },
    );
  }

  Future<void> _onCreateChatSession(
    CreateChatSession event,
    Emitter<ChatState> emit,
  ) async {
    if (_isCreatingSession) return;

    _isCreatingSession = true;

    emit(
      state.copyWith(
        status: ChatStatus.loading,
        clearError: true,
        clearMessageStatus: true,
      ),
    );

    final params = CreateChatSessionParams(context: event.context);
    final result = await _createChatSessionUsecase(params);

    _isCreatingSession = false;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ChatStatus.failure,
          error: failure,
          clearPendingQuery: true,
        ),
      ),
      (session) {
        final emptyMessages = PaginatedMessageEntity(
          messages: [],
          totalCount: 0,
          page: 1,
          pageSize: 20,
          hasNext: false,
          hasPrevious: false,
        );
        emit(
          state.copyWith(
            status: ChatStatus.success,
            currentSession: session,
            isSessionInitialized: true,
            sessionMessages: emptyMessages,
            clearError: true,
            clearMessageStatus: true,
          ),
        );

        if (state.pendingQuery != null) {
          add(
            SendChatQuery(
              state.pendingQuery!,
              sessionId: session.sessionId,
              context: event.context,
            ),
          );
        }
      },
    );
  }

  Future<void> _onSendChatQuery(
    SendChatQuery event,
    Emitter<ChatState> emit,
  ) async {
    if (!state.isSessionInitialized && !_isCreatingSession) {
      emit(
        state.copyWith(
          pendingQuery: event.query,
          messageStatus: MessageStatus.sending,
          clearError: true,
        ),
      );
      add(CreateChatSession(context: event.context));
      return;
    }
    if (_isCreatingSession) {
      emit(
        state.copyWith(
          pendingQuery: event.query,
          messageStatus: MessageStatus.sending,
        ),
      );
      return;
    }

    final sessionId = event.sessionId ?? state.currentSession?.sessionId;

    if (sessionId == null) {
      emit(
        state.copyWith(
          status: ChatStatus.failure,
          error: ServerFailure(message: 'No session available'),
          messageStatus: MessageStatus.failed,
          clearPendingQuery: true,
        ),
      );
      return;
    }
    emit(state.copyWith(clearPendingQuery: true));

    final tempUserId = 'temp_user_${DateTime.now().millisecondsSinceEpoch}';
    final userMessage = ChatMessageEntity(
      id: tempUserId,
      query: event.query,
      response: '',
      intent: 'user_query',
      intentDisplay: 'Query',
      executionTime: 0.0,
      confidenceScore: 1.0,
      createdAt: DateTime.now(),
      createdAtFormatted: DateFormat('h:mm a').format(DateTime.now()),
    );

    _addMessageToState(emit, userMessage);
    emit(
      state.copyWith(messageStatus: MessageStatus.processing, clearError: true),
    );

    final params = SendChatQueryParams(
      query: event.query,
      sessionId: sessionId,
      context: event.context,
    );

    final result = await _sendChatQueryUseCase(params);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ChatStatus.failure,
          error: failure,
          messageStatus: MessageStatus.failed,
        ),
      ),
      (responseEntity) {
        final aiMessage = ChatMessageEntity.fromResponse(responseEntity);
        final finalUserMessage = ChatMessageEntity(
          id: 'user_${responseEntity.messageId}_query',
          query: event.query,
          response: '',
          intent: 'user_query',
          intentDisplay: 'Query',
          executionTime: 0.0,
          confidenceScore: 1.0,
          createdAt: responseEntity.timestamp.subtract(
            const Duration(milliseconds: 100),
          ),
          createdAtFormatted: DateFormat('h:mm a').format(
            responseEntity.timestamp.subtract(
              const Duration(milliseconds: 100),
            ),
          ),
        );

        _replaceTemporaryMessage(emit, tempUserId, [
          finalUserMessage,
          aiMessage,
        ]);

        emit(
          state.copyWith(
            status: ChatStatus.success,
            chatResponse: responseEntity,
            messageStatus: MessageStatus.completed,
            clearError: true,
          ),
        );

        Future.delayed(const Duration(milliseconds: 500)).then((_) {
          if (!emit.isDone) {
            emit(state.copyWith(clearMessageStatus: true));
          }
        });
      },
    );
  }

  Future<void> _onSendChatFeedback(
    SendChatFeedback event,
    Emitter<ChatState> emit,
  ) async {
    final params = SendChatFeedbackParams(feedback: event.feedback);
    final result = await _sendChatFeedbackUsecase(params);

    result.fold(
      (failure) =>
          emit(state.copyWith(status: ChatStatus.failure, error: failure)),
      (_) => emit(state.copyWith(status: ChatStatus.success)),
    );
  }

  Future<void> _onGetChatAnalytics(
    GetChatAnalytics event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading));
    final params = GetChatAnalyticsParams(days: event.days);
    final result = await _getChatAnalyticsUsecase(params);

    result.fold(
      (failure) =>
          emit(state.copyWith(status: ChatStatus.failure, error: failure)),
      (analytics) => emit(
        state.copyWith(status: ChatStatus.success, analytics: analytics),
      ),
    );
  }

  void _replaceTemporaryMessage(
    Emitter<ChatState> emit,
    String tempId,
    List<ChatMessageEntity> replacementMessages,
  ) {
    final currentMessages = state.sessionMessages;
    if (currentMessages != null) {
      final updatedMessages = <ChatMessageEntity>[];
      int addedMessages = replacementMessages.length - 1;

      for (final message in currentMessages.messages) {
        if (message.id == tempId) {
          updatedMessages.addAll(replacementMessages);
        } else {
          updatedMessages.add(message);
        }
      }

      final updatedPaginatedMessages = currentMessages.copyWith(
        messages: updatedMessages,
        totalCount: currentMessages.totalCount + addedMessages,
      );

      emit(
        state.copyWith(
          sessionMessages: updatedPaginatedMessages,
          status: ChatStatus.success,
        ),
      );
    }
  }

  void _addMessageToState(Emitter<ChatState> emit, ChatMessageEntity message) {
    final currentMessages = state.sessionMessages;
    if (currentMessages != null) {
      final updatedMessages = List<ChatMessageEntity>.from(
        currentMessages.messages,
      )..add(message);

      final updatedPaginatedMessages = currentMessages.copyWith(
        messages: updatedMessages,
        totalCount: currentMessages.totalCount + 1,
      );
      emit(
        state.copyWith(
          sessionMessages: updatedPaginatedMessages,
          status: ChatStatus.success,
        ),
      );
    } else {
      final newMessages = PaginatedMessageEntity(
        messages: [message],
        totalCount: 1,
        page: 1,
        pageSize: 20,
        hasNext: false,
        hasPrevious: false,
      );
      emit(
        state.copyWith(
          sessionMessages: newMessages,
          status: ChatStatus.success,
        ),
      );
    }
  }
}
