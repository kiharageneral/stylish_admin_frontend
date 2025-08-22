import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_message_entity.dart';
import 'package:stylish_admin/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:stylish_admin/features/chat/presentation/widgets/chat_feedback_widget.dart';
import 'package:stylish_admin/features/chat/presentation/widgets/chat_input_widget.dart';
import 'package:stylish_admin/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:stylish_admin/features/chat/presentation/widgets/typing_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _currentSessionId;
  String? _feedbackMessageId;
  void _initializeChat() {
    context.read<ChatBloc>().add(GetChatHealth());
    context.read<ChatBloc>().add(GetChatSessions());
  }

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSessionCreated(String sessionId) {
    if (_currentSessionId != sessionId) {
      setState(() {
        _currentSessionId = sessionId;
      });
    }
  }

  void _retryMessage(ChatMessageEntity message) {
    if (message.intent == 'user_query') {
      context.read<ChatBloc>().add(
        SendChatQuery(message.query, sessionId: _currentSessionId),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _showFeedbackFor(String messageId) {
    setState(() {
      _feedbackMessageId = messageId;
    });
  }

  void _hideFeedback() {
    setState(() {
      _feedbackMessageId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              builder: (context, state) {
                return Column(
                  children: [
                    Expanded(child: _buildChatArea(state)),
                    if (_feedbackMessageId != null)
                      ChatFeedbackWidget(
                        messageId: _feedbackMessageId!,
                        onFeedbackSubmitted: _hideFeedback,
                      ),
                    ChatInputWidget(
                      sessionId: _currentSessionId,
                      isLoading:
                          state.messageStatus == MessageStatus.sending ||
                          state.messageStatus == MessageStatus.processing,
                      onSessionCreate: () =>
                          context.read<ChatBloc>().add(CreateChatSession()),
                    ),
                  ],
                );
              },
              listener: (context, state) {
                if (state.status == ChatStatus.failure && state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${state.error!.message}'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }

                if (state.currentSession != null) {
                  _handleSessionCreated(state.currentSession!.sessionId);
                }

                if (state.sessionMessages != null &&
                    state.sessionMessages!.messages.isNotEmpty) {
                  _scrollToBottom();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: AppTheme.accentGold,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Chat Assistant',
              style: AppTheme.headingMedium().copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),

            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.chatHealth != null) {
                  return _buildHealthIndicator(state.chatHealth!.isHealthy);
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: () => _showChatMenu(context),
              icon: Icon(Icons.more_vert, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatArea(ChatState state) {
    final isInitialLoading =
        state.status == ChatStatus.loading && state.sessions == null;
    if (isInitialLoading) {
      return _buildLoadingState();
    }

    final messages = state.sessionMessages?.messages ?? [];

    if (messages.isEmpty && state.messageStatus == null) {
      return _buildEmptyState();
    }

    if (messages.isEmpty &&
        (state.messageStatus == MessageStatus.sending ||
            state.messageStatus == MessageStatus.processing)) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
        ),
      );
    }

    return Container(
      color: AppTheme.primaryLight.withAlpha((0.05 * 255).round()),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        itemCount:
            messages.length +
            (state.messageStatus == MessageStatus.processing ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messages.length &&
              state.messageStatus == MessageStatus.processing) {
            return _buildProcessingBubble();
          }
          final message = messages[index];

          // Determine message state for the bubble
          MessageState? messageState;

          if (message.id.startsWith('temp_')) {
            switch (state.messageStatus) {
              case MessageStatus.sending:
                messageState = MessageState.sending;
                break;
              case MessageStatus.processing:
                messageState = MessageState.processing;
                break;

              case MessageStatus.failed:
                messageState = MessageState.failed;
                break;
              default:
                messageState = MessageState.sending;
            }
          }
          return ChatMessageBubble(
            message: message,
            onFeedback: () => _showFeedbackFor(message.id),
            onRetry: messageState == MessageState.failed
                ? () => _retryMessage(message)
                : null,
            showMetadata: message.intent != 'user_query',
            showProcessingIndicator: false,
          );
        },
      ),
    );
  }

  Widget _buildProcessingBubble() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.accentGreen.withAlpha(
              (0.7 * 255).round(),
            ),
            child: const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground.withAlpha((0.7 * 255).round()),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(
                  color: AppTheme.borderColor.withAlpha((0.3 * 255).round()),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withAlpha(
                        (0.1 * 255).round(),
                      ),
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusSmall,
                      ),
                      border: Border.all(
                        color: AppTheme.accentGreen.withAlpha(
                          (0.3 * 255).round(),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(
                            strokeWidth: 1,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.accentGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Processing',
                          style: AppTheme.bodySmall().copyWith(
                            color: AppTheme.accentGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TypingWidget(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.smart_toy,
                        size: 12,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Assistant is thinking...',
                        style: AppTheme.bodySmall().copyWith(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 24),
            Text(
              "Start a Conversation",
              style: AppTheme.headingMedium().copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ask me anything! I\'m here to help with your questions and provide assistance.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium().copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionCard('📊', 'Analytics Help'),
                _buildSuggestionCard('🔧', 'Technical Support'),
                _buildSuggestionCard('💡', 'Feature Guidance'),
                _buildSuggestionCard('❓', 'General Questions'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTheme.bodySmall().copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
          ),
          const SizedBox(height: 16),
          Text(
            'Initializing chat...',
            style: AppTheme.bodyMedium().copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(bool isHealthy) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHealthy
            ? AppTheme.success.withAlpha((0.1 * 255).round())
            : AppTheme.error.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHealthy ? AppTheme.success : AppTheme.error,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isHealthy ? AppTheme.success : AppTheme.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isHealthy ? 'Online' : 'Offline',
            style: AppTheme.bodySmall().copyWith(
              color: isHealthy ? AppTheme.success : AppTheme.error,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showChatMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.refresh, color: AppTheme.accentBlue),
              title: Text('New Chat Session'),
              onTap: () {
                Navigator.pop(context);
                context.read<ChatBloc>().add(CreateChatSession());
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: AppTheme.accentGreen),
              title: Text("View Chat History"),
              onTap: () {
                Navigator.pop(context);
                context.read<ChatBloc>().add(GetChatSessions());
              },
            ),

            ListTile(
              leading: Icon(Icons.analytics, color: AppTheme.accentGold),
              title: Text("Chat Analytics"),
              onTap: () {
                Navigator.pop(context);
                context.read<ChatBloc>().add(GetChatAnalytics());
              },
            ),
          ],
        ),
      ),
    );
  }
}
