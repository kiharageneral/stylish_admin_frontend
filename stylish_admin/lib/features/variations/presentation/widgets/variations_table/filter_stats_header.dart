import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';

class FilterStatsHeader extends StatelessWidget {
  final int totalVariants;
  final int displayedVariants;
  final bool hasFilters;
  final VoidCallback onClearFilters;
  const FilterStatsHeader({
    super.key,
    required this.totalVariants,
    required this.displayedVariants,
    required this.hasFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            'Showing $displayedVariants of $totalVariants variants',
            style: TextStyle(
              color: isDark ? Colors.white70 : AppTheme.textSecondary,
            ),
          ),

          const Spacer(),
          if (hasFilters)
            TextButton.icon(
              onPressed: onClearFilters,
              label: const Text('Clear Filters'),
              icon: const Icon(Icons.clear, size: 16),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accentIvory,
              ),
            ),
        ],
      ),
    );
  }
}
