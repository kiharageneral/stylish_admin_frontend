import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/chat/presentation/bloc/chat_bloc.dart';

class ChatInputWidget extends StatefulWidget {
  final String? sessionId;
  final bool isLoading;
  final VoidCallback? onSessionCreate;
  const ChatInputWidget({
    super.key,
    this.sessionId,
    this.isLoading = false,
    this.onSessionCreate,
  });

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;
  String? _pendingMessage;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (widget.sessionId == null) {
      _pendingMessage = text;

      context.read<ChatBloc>().add(CreateChatSession());
      widget.onSessionCreate?.call();
    } else {
      context.read<ChatBloc>().add(
        SendChatQuery(text, sessionId: widget.sessionId),
      );
    }
    _controller.clear();
    setState(() {
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state.currentSession != null && _pendingMessage != null) {
          context.read<ChatBloc>().add(
            SendChatQuery(
              _pendingMessage!,
              sessionId: state.currentSession!.sessionId,
            ),
          );
          _pendingMessage = null;
        }
      },
      child: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          final isSending =
              state.status == ChatStatus.sending ||
              state.status == ChatStatus.loading ||
              widget.isLoading;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              border: Border(
                top: BorderSide(color: AppTheme.borderColor, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.1 * 255).round()),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),

            child: SafeArea(
              child: Column(
                children: [
                  if (isSending)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withAlpha(
                          (0.1 * 255).round(),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.accentBlue.withAlpha(
                            (0.3 * 255).round(),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.accentBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Processing your message...',
                            style: AppTheme.bodySmall().copyWith(
                              color: AppTheme.accentBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withAlpha(
                              (0.3 * 255).round(),
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _focusNode.hasFocus
                                  ? AppTheme.accentGold
                                  : AppTheme.borderColor,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            enabled: !isSending,
                            maxLines: null,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: widget.sessionId == null
                                  ? 'Start a new conversion...'
                                  : isSending
                                  ? 'Please wait...'
                                  : 'Type your message',
                              hintStyle: AppTheme.bodyMedium().copyWith(
                                color: AppTheme.textMuted,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            style: AppTheme.bodyMedium(),
                            onChanged: (text) {
                              setState(() {
                                _isComposing = text.trim().isNotEmpty;
                              });
                            },
                            onSubmitted: (_) => _handleSubmit,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Material(
                          color: _isComposing && !isSending
                              ? AppTheme.accentGold
                              : AppTheme.textMuted,
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: _isComposing && !isSending
                                ? _handleSubmit
                                : null,

                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: isSending
                                  ? const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppTheme.textPrimary,
                                              ),
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.send_rounded,
                                      color: _isComposing
                                          ? AppTheme.textPrimary
                                          : AppTheme.textSecondary,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
