
import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';

class ProductsPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onChangePage;

  const ProductsPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onChangePage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: currentPage > 1
              ? () => onChangePage(currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
          disabledColor: AppTheme.textMuted,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
          child: Text(
            'Page $currentPage of $totalPages',
            style: AppTheme.bodyMedium(),
          ),
        ),
        IconButton(
          onPressed: currentPage < totalPages
              ? () => onChangePage(currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
          disabledColor: AppTheme.textMuted,
        ),
      ],
    );
  }
}