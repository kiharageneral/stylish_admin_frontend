import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_health_entity.dart';
import 'package:stylish_admin/features/chat/domain/entities/service_check_entity.dart';

class ChatHealthCard extends StatelessWidget {
  final ChatHealthEntity health;
  const ChatHealthCard({super.key, required this.health});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: AppTheme.borderColor.withAlpha((0.3 * 255).round()),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
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
              Icon(_getStatusIcon(), color: _getStatusColor(), size: 24),
              const SizedBox(width: 12),
              Text('Chat Service Health', style: AppTheme.subheading()),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor().withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusSmall,
                  ),
                ),
                child: Text(
                  health.status.toUpperCase(),
                  style: AppTheme.bodySmall().copyWith(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Version',
                  health.version,
                  Icons.info_outline,
                  AppTheme.accentBlue,
                ),
              ),

              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricItem(
                  'Active Sessions',
                  health.activeSessions?.toString() ?? 'N/A',
                  Icons.people_outline,
                  AppTheme.accentGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Service checks',
            style: AppTheme.bodyMedium().copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...health.checks.entries.map(
            (entry) => _buildCheckItem(entry.key, entry.value),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 8),
              Text(
                'Last Updated: ${_formatTimestamp(health.timestamp)}',
                style: AppTheme.bodySmall().copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String checkName, dynamic checkValue) {
    bool isHealthy = false;
    if (checkValue is ServiceCheckEntity) {
      isHealthy = checkValue.status == ServiceStatus.healthy;
    }
    final color = isHealthy ? AppTheme.success : AppTheme.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isHealthy ? Icons.check_circle : Icons.error,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              checkName,
              style: AppTheme.bodyMedium().copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            isHealthy ? 'Healthy' : 'Failed',
            style: AppTheme.bodySmall().copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: Border.all(color: color.withAlpha((0.3 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.bodySmall().copyWith(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.bodyLarge().copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (health.status.toLowerCase()) {
      case 'healthy':
        return AppTheme.success;
      case 'degraded':
        return AppTheme.warning;
      case 'unhealthy':
        return AppTheme.error;
      default:
        return AppTheme.textMuted;
    }
  }

  IconData _getStatusIcon() {
    switch (health.status.toLowerCase()) {
      case 'healthy':
        return Icons.check_circle;
      case 'degraded':
        return Icons.warning;
      case 'unhealthy':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
