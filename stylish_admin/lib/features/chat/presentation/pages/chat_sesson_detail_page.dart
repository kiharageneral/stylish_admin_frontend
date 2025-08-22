import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_message_entity.dart';
import 'package:stylish_admin/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:stylish_admin/features/chat/presentation/widgets/chat_feedback_widget.dart';
import 'package:stylish_admin/features/chat/presentation/widgets/chat_input_widget.dart';
import 'package:stylish_admin/features/chat/presentation/widgets/chat_message_bubble.dart';

class ChatSessonDetailPage extends StatefulWidget {
  final String sessionId;
  const ChatSessonDetailPage({super.key, required this.sessionId});

  @override
  State<ChatSessonDetailPage> createState() => _ChatSessonDetailPageState();
}

class _ChatSessonDetailPageState extends State<ChatSessonDetailPage> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadSesionMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadSesionMessages({int page = 1}) {
    context.read<ChatBloc>().add(
      GetSessionMessages(widget.sessionId, page: page, pageSize: _pageSize),
    );
    setState(() {
      _currentPage = page;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryLight,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSessionInfo(),
          Expanded(child: _buildMessagesSection()),

          _buildInputSection(),
        ],
      ),
    );
  }

  Widget _buildMessagesSection() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state.status == ChatStatus.loading &&
            state.sessionMessages == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == ChatStatus.failure) {
          return _buildErrorView();
        }

        if (state.sessionMessages == null ||
            state.sessionMessages!.messages.isEmpty) {
          return _buildEmptyView();
        }

        return _buildMessagesList(state.sessionMessages!.messages);
      },
    );
  }

  Widget _buildInputSection() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        return ChatInputWidget(
          sessionId: widget.sessionId,
          isLoading: state.status == ChatStatus.loading,
          onSessionCreate: () {
            _loadSesionMessages(page: _currentPage);
            _scrollToBottom();
          },
        );
      },
    );
  }

  Widget _buildMessagesList(List<ChatMessageEntity> messages) {
    return Container(
      color: AppTheme.primaryLight,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return ChatMessageBubble(
            message: message,
            onFeedback: () => ChatFeedbackWidget(messageId: message.id),
            showMetadata: true,
          );
        },
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(
            color: AppTheme.borderColor.withAlpha((0.3 * 255).round()),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: AppTheme.textMuted,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No Messages Yet',
              style: AppTheme.subheading().copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              'This session doesn\'t have any messages. \nStart a conversation using the input below.',
              style: AppTheme.bodyMedium().copyWith(color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.error.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(
            color: AppTheme.error.withAlpha((0.3 * 255).round()),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppTheme.error, size: 64),
            const SizedBox(height: 16),
            Text(
              'Failed to load messages',
              style: AppTheme.subheading().copyWith(color: AppTheme.error),
            ),

            const SizedBox(height: 8),
            Text(
              'Unable to retrieve messages for this session',
              style: AppTheme.bodyMedium().copyWith(color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadSesionMessages(page: _currentPage),
              label: const Text('Retry'),
              icon: const Icon(Icons.refresh),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentBlue.withAlpha((0.1 * 255).round()),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor.withAlpha((0.3 * 255).round()),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline, color: AppTheme.accentBlue, size: 20),
          const SizedBox(width: 12),
          Text(
            'Session Details',
            style: AppTheme.bodyMedium().copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.accentBlue,
            ),
          ),
          const Spacer(),
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              final messageCount = state.sessionMessages?.totalCount ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusSmall,
                  ),
                ),
                child: Text(
                  '$messageCount messages',
                  style: AppTheme.bodySmall().copyWith(
                    color: AppTheme.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.cardBackground,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chat Session', style: AppTheme.subheading()),
          Text(
            'ID: ${widget.sessionId.substring(0, 12)}...',
            style: AppTheme.bodySmall().copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _loadSesionMessages(page: _currentPage),
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh messages',
        ),
        IconButton(
          onPressed: _scrollToBottom,
          icon: const Icon(Icons.keyboard_arrow_down),
          tooltip: 'Scroll to bottom',
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
