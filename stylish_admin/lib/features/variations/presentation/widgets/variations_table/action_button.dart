
import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';

class ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  const ActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label,
          style: AppTheme.bodyMedium().copyWith(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        ),
      ),
    );
  }
}
