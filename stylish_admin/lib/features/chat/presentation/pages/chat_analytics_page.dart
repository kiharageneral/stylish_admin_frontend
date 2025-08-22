import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/chat/domain/entities/chat_analytics_entity.dart';
import 'package:stylish_admin/features/chat/presentation/bloc/chat_bloc.dart';

class ChatAnalyticsPage extends StatefulWidget {
  const ChatAnalyticsPage({super.key});

  @override
  State<ChatAnalyticsPage> createState() => _ChatAnalyticsPageState();
}

class _ChatAnalyticsPageState extends State<ChatAnalyticsPage> {
  int _selectedPeriod = 30;
  final List<int> _periods = [7, 30, 90, 365];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  void _onPeriodChanged(int period) {
    setState(() {
      _selectedPeriod = period;
    });

    _loadAnalytics();
  }

  void _loadAnalytics() {
    context.read<ChatBloc>().add(GetChatAnalytics(days: _selectedPeriod));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundMedium,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.status == ChatStatus.loading) {
                  return _buildLoadingState();
                }

                if (state.status == ChatStatus.failure) {
                  return _buildErrorState(
                    state.error?.message ?? 'Failed to load analytics',
                  );
                }

                if (state.analytics == null) {
                  return _buildEmptyState();
                }

                return _buildAnalyticsContent(state.analytics!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent(ChatAnalyticsEntity analytics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildOverviewCards(analytics),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildIntentAnalysisChart(analytics),
                    const SizedBox(height: 24),
                    _buildConfidenceDistributionChart(analytics),
                  ],
                ),
              ),

              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildTopIntentsCard(analytics),
                    const SizedBox(height: 24),
                    _buildPerformanceMetricsCard(analytics),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetricsCard(ChatAnalyticsEntity analytics) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: AppTheme.borderColor.withAlpha((0.3 * 255).round()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance Metrics', style: AppTheme.subheading()),
          const SizedBox(height: 20),
          _buildPerformanceItem(
            'Messages per Session',
            (analytics.totalMessages / analytics.totalSessions).toStringAsFixed(
              1,
            ),
            Icons.message,
            AppTheme.accentBlue,
          ),
          const SizedBox(height: 16),
          _buildPerformanceItem(
            'Average Response Time',
            '${(analytics.avgResponseTime * 1000).toStringAsFixed(0)}ms',
            Icons.speed,
            AppTheme.accentOrange,
          ),
          const SizedBox(height: 16),
          _buildPerformanceItem(
            'Session Duration',
            '${analytics.avgSessionLength.toStringAsFixed(1)} minutes',
            Icons.timer,
            AppTheme.accentGreen,
          ),

          if (analytics.successRate != null) ...[
            const SizedBox(height: 16),
            _buildPerformanceItem(
              'Success Rate',
              '${(analytics.successRate! * 100).toStringAsFixed(1)}%',
              Icons.check_circle,
              AppTheme.success,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha((0.2 * 255).round()),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodySmall().copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTheme.bodyMedium().copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopIntentsCard(ChatAnalyticsEntity analyticis) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: AppTheme.borderColor.withAlpha((0.3 * 255).round()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Intents', style: AppTheme.subheading()),
          const SizedBox(height: 20),
          ...analyticis.mostCommonIntents.take(5).map((intent) {
            return _buildIntentItem(
              intent['intent'] as String,
              (intent['count'] as num).toInt(),
              analyticis.totalMessages,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildIntentItem(String intent, int count, int total) {
    final percentage = (count / total * 100);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  intent,
                  style: AppTheme.bodyMedium().copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '$count (${percentage.toStringAsFixed(1)}%)',
                style: AppTheme.bodySmall().copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: AppTheme.borderColor.withAlpha(
              (0.3 * 255).round(),
            ),
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceDistributionChart(ChatAnalyticsEntity analytics) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: AppTheme.borderColor.withAlpha((0.3 * 255).round()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confidence Score Distribution', style: AppTheme.subheading()),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: _getMaxConfidenceValue(analytics.confidenceDistribution),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value * 10).toInt()}%',
                          style: AppTheme.bodySmall().copyWith(
                            color: AppTheme.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),

                borderData: FlBorderData(show: false),
                barGroups: _buildConfidenceBarGroups(
                  analytics.confidenceDistribution,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildConfidenceBarGroups(
    Map<String, dynamic> distribution,
  ) {
    return distribution.entries.map((entry) {
      final key = entry.key;
      final value = (entry.value as num).toDouble();
      final index = int.tryParse(key.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: AppTheme.accentBlue,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxConfidenceValue(Map<String, dynamic> distribution) {
    double maxValue = 0;
    for (var value in distribution.values) {
      if (value is num && value.toDouble() > maxValue) {
        maxValue = value.toDouble();
      }
    }
    return maxValue * 1.2;
  }

  Widget _buildIntentAnalysisChart(ChatAnalyticsEntity analytics) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: AppTheme.borderColor.withAlpha((0.3 * 255).round()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Intent Distribution', style: AppTheme.subheading()),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: _buildPieChartSections(analytics.mostCommonIntents),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    List<Map<String, dynamic>> intents,
  ) {
    final colors = [
      AppTheme.accentBlue,
      AppTheme.accentGreen,
      AppTheme.accentOrange,
      AppTheme.accentPurple,
      AppTheme.accentGold,
    ];
    return intents.take(5).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final intent = entry.value;
      final percentage = (intent['count'] as num).toDouble();
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: AppTheme.bodySmall().copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Widget _buildOverviewCards(ChatAnalyticsEntity analytics) {
    return Row(
      children: [
        Expanded(
          child: _buildMetriCard(
            'Total Sessions',
            analytics.totalSessions.toString(),
            Icons.chat_bubble_outline,
            AppTheme.accentBlue,
            subtitle: 'Last ${analytics.periodDays} days',
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: _buildMetriCard(
            'Total Messages',
            analytics.totalMessages.toString(),
            Icons.message_outlined,
            AppTheme.accentGreen,
            subtitle:
                '${(analytics.totalMessages / analytics.totalSessions).toStringAsFixed(1)} per session',
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: _buildMetriCard(
            'Avg Session Length',
            '${analytics.avgSessionLength.toStringAsFixed(1)}m',
            Icons.timer_outlined,
            AppTheme.accentOrange,
            subtitle: 'Average duration',
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: _buildMetriCard(
            'Avg Response Time',
            '${(analytics.avgResponseTime * 1000).toStringAsFixed(0)}ms',
            Icons.speed_outlined,
            AppTheme.accentPurple,
            subtitle: 'Processing time',
          ),
        ),

        if (analytics.successRate != null) ...[
          const SizedBox(width: 16),
          Expanded(
            child: _buildMetriCard(
              'Success Rate',
              '${(analytics.successRate! * 100)}%',
              Icons.check_circle_outline,
              AppTheme.success,
              subtitle: 'Query resolution',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetriCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusSmall,
                  ),
                ),
                child: Icon(icon, color: color, size: 20),
              ),

              const Spacer(),
              Text(
                title,
                style: AppTheme.bodySmall().copyWith(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Text(
            value,
            style: AppTheme.headingLarge().copyWith(color: color, fontSize: 28),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTheme.bodySmall().copyWith(color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor.withAlpha((0.3 * 255).round()),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentPurple.withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            ),
            child: Icon(
              Icons.analytics_outlined,
              color: AppTheme.accentPurple,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chat Analytics', style: AppTheme.headingLarge()),
                const SizedBox(height: 4),
                Text(
                  'Detailed insights into chat performance and user engagement',
                  style: AppTheme.bodyMedium().copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),

          _buildPeriodSelector(),

          const SizedBox(width: 16),
          IconButton(
            onPressed: _loadAnalytics,
            icon: Icon(Icons.refresh, color: AppTheme.textSecondary),
            tooltip: 'Refresh Analytics',
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundMedium,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: Border.all(
          color: AppTheme.borderColor.withAlpha((0.3 * 255).round()),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _periods.map((period) {
          final isSelected = period == _selectedPeriod;
          return GestureDetector(
            onTap: () => _onPeriodChanged(period),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accentGold : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              ),
              child: Text(
                '${period}d',
                style: AppTheme.bodySmall().copyWith(
                  color: isSelected
                      ? AppTheme.primaryDark
                      : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
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
            'Loading analytics...',
            style: AppTheme.bodyMedium().copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.error),
          const SizedBox(height: 16),
          Text('Failed to load analytics', style: AppTheme.subheading()),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTheme.bodyMedium().copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAnalytics,
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGold,
              foregroundColor: AppTheme.primaryDark,
            ),
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text('No analytics data available', style: AppTheme.subheading()),
          const SizedBox(height: 8),
          Text(
            'Analytics data will appear here once chat sessions are created.',
            style: AppTheme.bodyMedium().copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
