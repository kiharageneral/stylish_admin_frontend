
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_feedback_entity.dart';
import 'package:stylish_admin/features/chat/presentation/bloc/chat_bloc.dart';

class ChatFeedbackWidget extends StatefulWidget {
  final String messageId;
  final VoidCallback? onFeedbackSubmitted;
  const ChatFeedbackWidget({
    super.key,
    required this.messageId,
    this.onFeedbackSubmitted,
  });

  @override
  State<ChatFeedbackWidget> createState() => _ChatFeedbackWidgetState();
}

class _ChatFeedbackWidgetState extends State<ChatFeedbackWidget>
    with SingleTickerProviderStateMixin {
  bool _showDetailedFeedback = false;
  int _selectedRating = 0;
  String? _selectedReasonKey;
  final TextEditingController _commentController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  final Map<String, String> _feedbackReasons = {
    'helpful': 'Response was helpful',
    'accurate': 'Information was accurate',
    'fast': 'Response was fast',
    'complete': 'Response was complete',
    'irrelevant': 'Response was irrelevant',
    'inaccurate': 'Information was inaccurate',
    'slow': 'Response was too slow',
    'incomplete': 'Response was incomplete',
    'unclear': 'Response was unclear',
    'other': 'Other reason',
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onQuickFeedback(bool isPositive) {
    final rating = isPositive ? 5 : 1;
    final feedbackType = isPositive ? 'positive' : 'negative';

    _submitFeedback(rating: rating, feedbackType: feedbackType);
  }

  void _showDetailedForm() {
    setState(() {
      _showDetailedFeedback = true;
    });
    _animationController.forward();
  }

  void _hideDetailedForm() {
    _animationController.reverse().then((_) {
      setState(() {
        _showDetailedFeedback = false;
        _selectedRating = 0;
        _selectedReasonKey = null;
        _commentController.clear();
      });
    });
  }

  void _submitFeedback({
    required int rating,
    required String feedbackType,
    String? reason,
    String? comment,
  }) {
    final feedback = ChatFeedbackEntity(
      messageId: widget.messageId,
      feedbackType: feedbackType,
      rating: rating,
      comment: comment,
      reason: reason,
    );
    context.read<ChatBloc>().add(SendChatFeedback(feedback));
    widget.onFeedbackSubmitted?.call();

    if (_showDetailedFeedback) {
      _hideDetailedForm();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Thank you for your feedback!'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withAlpha((0.3 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_showDetailedFeedback) _buildQuickFeedback(),
          if (_showDetailedFeedback) _buildDetailedFeedback(),
        ],
      ),
    );
  }

  Widget _buildQuickFeedback() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Was this response helpful?',
          style: AppTheme.bodySmall().copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildQuickFeedbackButton(
              icon: Icons.thumb_up_outlined,
              label: 'Yes',
              isPositive: true,
              onTap: () => _onQuickFeedback(true),
            ),
            const SizedBox(width: 8),
            _buildQuickFeedbackButton(
              icon: Icons.thumb_down_outlined,
              label: 'No',
              isPositive: false,
              onTap: () => _onQuickFeedback(false),
            ),

            const Spacer(),
            TextButton.icon(
              onPressed: _showDetailedForm,
              label: Text(
                'Detailed feedback',
                style: AppTheme.bodySmall().copyWith(
                  color: AppTheme.accentGold,
                ),
              ),
              icon: Icon(
                Icons.rate_review_outlined,
                size: 16,
                color: AppTheme.accentGold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickFeedbackButton({
    required IconData icon,
    required String label,
    required bool isPositive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isPositive ? AppTheme.success : AppTheme.error,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTheme.bodySmall().copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedFeedback() {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Detailed Feedback',
                style: AppTheme.bodyMedium().copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _hideDetailedForm,
                icon: Icon(Icons.close, size: 18, color: AppTheme.textMuted),
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                padding: EdgeInsets.zero,
              ),
            ],
          ),

          const SizedBox(height: 12),
          Text(
            'Rating',
            style: AppTheme.bodySmall().copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final rating = index + 1;
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = rating),
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: Icon(
                    rating <= _selectedRating ? Icons.star : Icons.star_border,
                    color: rating <= _selectedRating
                        ? AppTheme.accentGold
                        : AppTheme.textMuted,
                    size: 20,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),
          Text(
            'Reason (optional)',
            style: AppTheme.bodySmall().copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _feedbackReasons.entries.map((entry) {
              final reasonKey = entry.key;
              final reasonText = entry.value;
              final isSelected = _selectedReasonKey == reasonKey;

              return GestureDetector(
                onTap: () => setState(() => _selectedReasonKey = reasonKey),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentGold.withAlpha((0.2 * 255).round())
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentGold
                          : AppTheme.borderColor,
                      width: 1,
                    ),
                  ),

                  child: Text(
                    reasonText,
                    style: AppTheme.bodySmall().copyWith(
                      color: isSelected
                          ? AppTheme.accentGold
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          Text(
            'Additional comments (optional)',
            style: AppTheme.bodySmall().copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tell us more about your experience...',
              hintStyle: AppTheme.bodySmall().copyWith(
                color: AppTheme.textMuted,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.borderColor, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.borderColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.accentGold, width: 2),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: AppTheme.bodySmall(),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedRating > 0
                  ? () => _submitFeedback(
                      rating: _selectedRating,
                      feedbackType: _selectedRating >= 4
                          ? 'positive'
                          : 'negative',
                      reason: _selectedReasonKey,
                      comment: _commentController.text.trim().isEmpty
                          ? null
                          : _commentController.text.trim(),
                    )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: AppTheme.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Submit Feedback',
                style: AppTheme.bodyMedium().copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
