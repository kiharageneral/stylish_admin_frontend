import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';

class EditableColumnHeader extends StatelessWidget {
  final String title;
  final bool isEditing;
  final VoidCallback onToggle;
  final bool isDark;
  const EditableColumnHeader({
    super.key,
    required this.title,
    required this.isEditing,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacingSmall),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onToggle,
            child: Icon(
              isEditing ? Icons.edit_off : Icons.edit,
              size: 16,
              color: isEditing ? AppTheme.primaryLight : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
