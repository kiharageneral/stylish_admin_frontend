
import 'package:flutter/material.dart';
import 'package:stylish_admin/features/category/domain/entities/category_entity.dart';

class CategoryStats extends StatefulWidget {
  final List<CategoryEntity> categories;

  const CategoryStats({
    super.key,
    required this.categories,
  });

  @override
  State<CategoryStats> createState() => _CategoryStatsState();
}

class _CategoryStatsState extends State<CategoryStats>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final activeCategories = widget.categories.where((c) => c.isActive).length;
    final inactiveCategories = widget.categories.length - activeCategories;

    return FadeTransition(
      opacity: _animation,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF0F3460),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).round()),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.analytics,
              color: Colors.white70,
              size: 16,
            ),
            const SizedBox(width: 8),
            const Text(
              'Statistics:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CompactStatItem(
                    label: 'Total',
                    value: widget.categories.length,
                    icon: Icons.category,
                    color: Colors.blue,
                    animation: _animation,
                  ),
                  _CompactStatItem(
                    label: 'Active',
                    value: activeCategories,
                    icon: Icons.check_circle,
                    color: Colors.green,
                    animation: _animation,
                  ),
                  _CompactStatItem(
                    label: 'Inactive',
                    value: inactiveCategories,
                    icon: Icons.cancel,
                    color: Colors.red,
                    animation: _animation,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _CompactStatItem extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Animation<double> animation;

  const _CompactStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final calculatedValue = (value * animation.value).round();

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: color.withAlpha((0.2 * 255).round()), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 12),
                const SizedBox(width: 4),
                Text(
                  '$calculatedValue $label',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          );
        });
  }
}
