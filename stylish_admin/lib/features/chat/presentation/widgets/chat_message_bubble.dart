import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_message_entity.dart';
import 'package:stylish_admin/features/chat/presentation/widgets/typing_widget.dart';

enum MessageState { sending, processing, sent, failed }

class ChatMessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final VoidCallback? onFeedback;
  final VoidCallback? onRetry;
  final bool showMetadata;
  final MessageState? state;
  final bool showProcessingIndicator;
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onFeedback,
    this.onRetry,
    this.showMetadata = true,
    this.state,
    this.showProcessingIndicator = false,
  });

  bool get isUserMessage => message.intent == 'user_query';

  MessageState get effectiveState {
    if (state != null) return state!;
    return MessageState.sent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isUserMessage) ...[
            _buildQueryBubble(),
            if (showProcessingIndicator) ...[
              const SizedBox(height: 16),
              _buildProgressIndicator(),
            ],
          ] else ...[
            _buildResponseBubble(context),
            if (showMetadata && effectiveState == MessageState.sent) ...[
              const SizedBox(height: 12),
              _buildMetadata(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMetadata() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withAlpha(25),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: Border.all(color: AppTheme.borderColor.withAlpha(51)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildMetricItem(
                'Confidence',
                '${(message.confidenceScore * 100).toStringAsFixed(1)}%',
                _getConfidenceColor(message.confidenceScore),
              ),

              const SizedBox(width: 24),
              _buildMetricItem(
                'Response Time',
                '${message.executionTime.toStringAsFixed(0)}ms ',
                _getResponseTimeColor(message.executionTime),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTheme.bodySmall().copyWith(
            color: AppTheme.textMuted,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTheme.bodySmall().copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildResponseBubble(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.accentGreen,
          child: const Icon(
            Icons.smart_toy,
            color: AppTheme.textPrimary,
            size: 16,
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildIntentChip(),
                    const Spacer(),
                    _buildActionButtons(context),
                  ],
                ),

                const SizedBox(height: 12),
                SelectableText(
                  message.response,
                  style: AppTheme.bodyMedium().copyWith(
                    color: AppTheme.textPrimary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 12),
                _buildResponseFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponseFooter() {
    return Row(
      children: [
        Icon(Icons.smart_toy, size: 12, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          'Assistant',
          style: AppTheme.bodySmall().copyWith(
            color: AppTheme.textMuted,
            fontSize: 10,
          ),
        ),
        const Spacer(),
        Text(
          message.createdAtFormatted,
          style: AppTheme.bodySmall().copyWith(
            color: AppTheme.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _copyToClipboard(message.response, context),
          icon: Icon(Icons.copy, size: 16, color: AppTheme.textMuted),
          tooltip: 'Copy response',
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),

        if (onFeedback != null)
          IconButton(
            onPressed: onFeedback,
            icon: Icon(
              Icons.thumb_up_alt_outlined,
              size: 16,
              color: AppTheme.textMuted,
            ),
            tooltip: 'Provide feedback',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),

        if (effectiveState == MessageState.failed && onRetry != null)
          IconButton(
            onPressed: onRetry,
            icon: Icon(Icons.refresh, size: 16, color: AppTheme.error),
            tooltip: 'Retry',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
      ],
    );
  }

  Widget _buildIntentChip() {
    final color = _getIntentColor(message.intent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Text(
        message.intentDisplay,
        style: AppTheme.bodySmall().copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
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
                  const TypingWidget(),
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

  Widget _buildQueryBubble() {
    final isActive = effectiveState == MessageState.sending;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.accentBlue.withAlpha(179)
                  : AppTheme.accentBlue.withAlpha(229),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentBlue.withAlpha(76),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message.query,
                        style: AppTheme.bodyMedium().copyWith(
                          color: AppTheme.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (isActive) ...[
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.textPrimary.withAlpha(204),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                _buildUserLabel(isActive),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),
        _buildUserAvatar(isActive),
      ],
    );
  }

  Widget _buildUserAvatar(bool isActive) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: effectiveState == MessageState.failed
          ? AppTheme.error.withAlpha(179)
          : AppTheme.accentBlue,
      child: Icon(
        effectiveState == MessageState.failed
            ? Icons.error_outline
            : Icons.person,
        size: 16,
      ),
    );
  }

  Widget _buildUserLabel(bool isActive) {
    String labelText;

    switch (effectiveState) {
      case MessageState.sending:
        labelText = 'Sending...';
        break;
      case MessageState.processing:
        labelText = 'Processing...';
      case MessageState.failed:
        labelText = 'Failed';
        break;
      default:
        labelText = 'User';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          effectiveState == MessageState.failed
              ? Icons.error_outline
              : Icons.person,
          size: 12,
          color: effectiveState == MessageState.failed
              ? AppTheme.error.withAlpha(204)
              : AppTheme.textPrimary.withAlpha(179),
        ),
        const SizedBox(width: 4),
        Text(
          labelText,
          style: AppTheme.bodySmall().copyWith(
            color: effectiveState == MessageState.failed
                ? AppTheme.error.withAlpha(204)
                : AppTheme.textPrimary.withAlpha(179),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Color _getIntentColor(String intent) {
    switch (intent.toLowerCase()) {
      case 'question':
        return AppTheme.accentBlue;
      case 'request':
        return AppTheme.accentGreen;
      case 'complaint':
        return AppTheme.accentRed;
      case 'compliment':
        return AppTheme.accentGold;
      default:
        return AppTheme.accentPurple;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return AppTheme.success;
    if (confidence >= 0.6) return AppTheme.warning;
    return AppTheme.error;
  }

  Color _getResponseTimeColor(double responseTime) {
    if (responseTime <= 500) return AppTheme.success;
    if (responseTime <= 1000) return AppTheme.warning;

    return AppTheme.error;
  }

  void _copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copied the response"),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }
}
