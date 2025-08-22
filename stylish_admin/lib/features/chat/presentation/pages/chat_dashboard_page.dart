import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:stylish_admin/features/chat/presentation/pages/chat_all_sessions_page.dart';
import 'package:stylish_admin/features/chat/presentation/pages/chat_analytics_page.dart';
import 'package:stylish_admin/features/chat/presentation/pages/chat_screen.dart';
import 'package:stylish_admin/features/chat/presentation/pages/chat_sesson_detail_page.dart';
import 'package:stylish_admin/features/chat/presentation/widgets/chat_health_card.dart';
import 'package:stylish_admin/features/chat/presentation/widgets/chat_session_card.dart';

class ChatDashboardPage extends StatefulWidget {
  const ChatDashboardPage({super.key});

  @override
  State<ChatDashboardPage> createState() => _ChatDashboardPageState();
}

class _ChatDashboardPageState extends State<ChatDashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final chatBloc = context.read<ChatBloc>();
    chatBloc.add(GetChatHealth());
    chatBloc.add(GetChatSessions());
    chatBloc.add(const GetChatAnalytics(days: 7));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryLight,
      body: RefreshIndicator(
        onRefresh: () async => _loadInitialData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildQuickStats(),
              const SizedBox(height: 32),
              _buildMainContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat Management Dashboard', style: AppTheme.headingLarge()),
            const SizedBox(height: 8),
            Text(
              'Monitor chat service health, sessions, and analytics',
              style: AppTheme.bodyLarge().copyWith(color: AppTheme.textMuted),
            ),
          ],
        ),
        const Spacer(),

        Row(
          children: [
            _buildActionButton(
              icon: Icons.chat,
              label: 'Open Chat',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatScreen()),
              ),
            ),

            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.analytics,
              label: 'Analytics',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatAnalyticsPage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.refresh,
              label: 'Refresh',
              onPressed: _loadInitialData,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      label: Text(label),
      icon: Icon(icon, size: 18),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.cardBackground,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          side: BorderSide(color: AppTheme.borderColor),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Service Status',
                value: state.chatHealth?.status.toUpperCase() ?? 'Unknown',
                icon: Icons.health_and_safety,
                color: _getHealthColor(state.chatHealth?.status),
              ),
            ),

            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Active Sessions',
                value: state.chatHealth?.activeSessions?.toString() ?? '0',
                icon: Icons.chat_bubble,
                color: AppTheme.accentBlue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Total Sessions',
                value: state.sessions.length.toString(),
                icon: Icons.forum,
                color: AppTheme.accentPurple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Avg Response Time',
                value: state.analytics?.avgResponseTime != null
                    ? '${state.analytics!.avgResponseTime.toStringAsFixed(0)}ms'
                    : 'N/A',
                icon: Icons.speed,
                color: AppTheme.accentOrange,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: AppTheme.borderColor.withAlpha((0.3 * 255).round()),
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
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusSmall,
                  ),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppTheme.headingLarge().copyWith(fontSize: 24, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.bodyMedium().copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Service Health', style: AppTheme.subheading()),
              const SizedBox(height: 16),
              _buildHealthSection(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent Sessions', style: AppTheme.subheading()),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      // Navigate to sessions list or filter
                    },
                    icon: const Icon(Icons.filter_list, size: 18),
                    label: const Text('Filter'),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _buildSessionsList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionsList() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state.status == ChatStatus.loading && state.sessions == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == ChatStatus.failure) {
          return _buildErrorCard('Failed to load sessions');
        }
        if (state.sessions.isEmpty) {
          return _buildEmptyCard('No sessions available');
        }
        final recentSessions = state.sessions.take(5).toList();

        return Column(
          children: [
            ...recentSessions.map(
              (session) => ChatSessionCard(
                session: session,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatSessonDetailPage(sessionId: session.sessionId),
                  ),
                ),
              ),
            ),
            if (state.sessions.length > 5) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                  border: Border.all(
                    color: AppTheme.accentBlue.withAlpha((0.3 * 255).round()),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.accentBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Showing ${recentSessions.length} of ${state.sessions.length} sessions',
                        style: AppTheme.bodyMedium().copyWith(
                          color: AppTheme.accentBlue,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatAllSessionsPage(),
                          ),
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: AppTheme.borderColor.withAlpha((0.3 * 255).round()),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.chat_bubble_outline, color: AppTheme.textMuted, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.bodyLarge().copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSection() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state.status == ChatStatus.loading && state.chatHealth == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == ChatStatus.failure) {
          return _buildErrorCard('Failed to load health data');
        }

        if (state.chatHealth == null) {
          return _buildErrorCard('No health data available');
        }
        return ChatHealthCard(health: state.chatHealth!);
      },
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.error.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: AppTheme.error.withAlpha((0.3 * 255).round()),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: AppTheme.error, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.bodyLarge().copyWith(color: AppTheme.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInitialData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(String? status) {
    switch (status?.toLowerCase()) {
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
}
