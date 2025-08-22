import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_session_entity.dart';

class ChatSessionCard extends StatelessWidget {
  final ChatSessionEntity session;
  final VoidCallback? onTap;
  final bool isSelected;
  const ChatSessionCard({
    super.key,
    required this.session,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accentGold.withAlpha((0.1 * 255).round())
                  : AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              border: Border.all(
                color: isSelected
                    ? AppTheme.accentGold.withAlpha((0.5 * 255).round())
                    : AppTheme.borderColor.withAlpha((0.3 * 255).round()),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.05 * 255).round()),
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withAlpha(
                          (0.2 * 255).round(),
                        ),
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusSmall,
                        ),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: AppTheme.accentBlue,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session ${session.sessionId.substring(0, 8)}...',
                            style: AppTheme.bodyLarge().copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.accentGold
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'User ID: ${session.userId}',
                            style: AppTheme.bodySmall().copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusIndicator(),
                  ],
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMetricChip(
                      Icons.message,
                      '${session.messageCount}',
                      AppTheme.accentPurple,
                    ),
                    const SizedBox(width: 12),
                    _buildMetricChip(
                      Icons.access_time,
                      session.lastActivity,
                      AppTheme.accentOrange,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Created: ${session.createdAtFormatted}',
                      style: AppTheme.bodySmall().copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: isSelected
                            ? AppTheme.accentGold
                            : AppTheme.textMuted,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: Border.all(color: color.withAlpha((0.3 * 255).round())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.bodySmall().copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final isRecent = _isRecentSession();

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isRecent ? AppTheme.success : AppTheme.textMuted,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isRecent ? AppTheme.success : AppTheme.textMuted).withAlpha(
              (0.3 * 255).round(),
            ),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  bool _isRecentSession() {
    final now = DateTime.now();
    final sessionTime = session.createdAt;
    final difference = now.difference(sessionTime);
    return difference.inHours < 24;
  }
}
