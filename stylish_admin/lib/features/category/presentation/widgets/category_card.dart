
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/utils/responsive_helper.dart';
import 'package:stylish_admin/features/category/domain/entities/category_entity.dart';
import 'package:stylish_admin/features/category/presentation/bloc/category_bloc.dart';
import 'package:stylish_admin/features/category/presentation/widgets/edit_category_dialog.dart';

class CategoryCard extends StatefulWidget {
  final CategoryEntity category;
  final int index;

  const CategoryCard({
    super.key,
    required this.category,
    required this.index,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  Color _getCategoryColor() {
    final colors = [
      const Color(0xFF1E88E5), // Blue
      const Color(0xFF43A047), // Green
      const Color(0xFFE53935), // Red
      const Color(0xFFFFB300), // Amber
      const Color(0xFF8E24AA), // Purple
      const Color(0xFF00ACC1), // Cyan
      const Color(0xFF5E35B1), // Deep Purple
      const Color(0xFFD81B60), // Pink
    ];
    final int colorIndex = widget.category.id.hashCode.abs() % colors.length;
    return colors[colorIndex];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double cardWidth = ResponsiveHelper.isTablet(context)
          ? constraints.maxWidth * 0.95 
          : (constraints.maxWidth < 300 ? constraints.maxWidth : 240.0);

      final double minCardHeight = ResponsiveHelper.isMobile(context)
          ? 70.0 
          : 220.0;

      final bool isSmallCard = constraints.maxWidth < 260;

      final descriptionFontSize = ResponsiveHelper.getResponsiveFontSize(
        context,
        forMobile: 12,
        forTablet: 12,
        forDesktop: 14,
      );

      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _opacityAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: MouseRegion(
                onEnter: (_) => setState(() {
                  _isHovering = true;
                }),
                onExit: (_) => setState(() {
                  _isHovering = false;
                }),
                child: Container(
                  width: isSmallCard ? constraints.maxWidth : cardWidth,
                  constraints: BoxConstraints(
                    minHeight: minCardHeight,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getCategoryColor().withAlpha(
                              (_isHovering ? 1.0 * 255 : 0.9 * 255).round()),
                          _getCategoryColor().withAlpha(
                              (_isHovering ? 0.8 * 255 : 0.6 * 255).round()),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _isHovering
                              ? _getCategoryColor()
                                  .withAlpha((0.3 * 255).round())
                              : Colors.black.withAlpha((0.15 * 255).round()),
                          blurRadius: _isHovering ? 8 : 6,
                          spreadRadius: _isHovering ? 1 : 0.5,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showEditDialog(context),
                        borderRadius: BorderRadius.circular(16),
                        hoverColor: Colors.white.withAlpha((0.1 * 255).round()),
                        splashColor:
                            Colors.white.withAlpha((0.1 * 255).round()),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildCategoryIcon(isSmallCard),
                              const SizedBox(height: 12),
                              Text(
                                widget.category.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              if (widget.category.parentName != null)
                                _buildParentTag(),
                              if (widget.category.description != null) ...[
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0),
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxHeight:
                                          ResponsiveHelper.isTablet(context)
                                              ? 60.0
                                              : 40.0,
                                    ),
                                    child: Text(
                                      widget.category.description!,
                                      style: TextStyle(
                                        fontSize: descriptionFontSize,
                                        color: Colors.white70,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines:
                                          ResponsiveHelper.isTablet(context)
                                              ? 3
                                              : 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              ResponsiveHelper.isMobile(context)
                                  ? const SizedBox(
                                      height:
                                          2) 
                                  : const Spacer(flex: 1),
                              _buildStatusIndicator(),
                              const SizedBox(height: 12),
                              AnimatedOpacity(
                                opacity: _isHovering ? 1.0 : 0.8,
                                duration: const Duration(milliseconds: 200),
                                child: _buildActionButtons(isSmallCard),
                              ),
                              const SizedBox(height: 8), // Add bottom padding
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildParentTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.subdirectory_arrow_right,
            size: 12,
            color: Colors.white70,
          ),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              widget.category.parentName ?? 'Parent',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(bool isSmall) {
    const double iconSize = 20;
    const double paddingSize = 14;

    return Container(
      padding: const EdgeInsets.all(paddingSize),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withAlpha((0.2 * 255).round()),
          width: 1,
        ),
      ),
      child: Icon(
        _getCategoryIcon(),
        size: iconSize,
        color: Colors.white,
      ),
    );
  }

  IconData _getCategoryIcon() {
    final icons = [
      Icons.category,
      Icons.shopping_bag,
      Icons.style,
      Icons.local_offer,
      Icons.grid_view,
      Icons.inventory_2,
      Icons.shopping_cart,
      Icons.store,
    ];
    final int iconIndex = widget.category.id.hashCode.abs() % icons.length;
    return icons[iconIndex];
  }

  Widget _buildStatusIndicator() {
    const double dotSize = 6;
    const double fontSize = 10;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.category.isActive
                ? Colors.greenAccent
                : Colors.redAccent,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          widget.category.isActive ? 'Active' : 'Inactive',
          style: TextStyle(
            fontSize: fontSize,
            color: widget.category.isActive
                ? Colors.greenAccent
                : Colors.redAccent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isSmall) {
    if (isSmall) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IconActionButton(
            icon: Icons.edit,
            onPressed: () => _showEditDialog(context),
          ),
          const SizedBox(width: 6),
          _IconActionButton(
            icon: Icons.delete,
            color: Colors.redAccent,
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          icon: Icons.edit,
          label: 'Edit',
          onPressed: () => _showEditDialog(context),
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: Icons.delete,
          label: 'Delete',
          color: Colors.redAccent,
          onPressed: () => _showDeleteDialog(context),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: isDesktop
            ? const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0)
            : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: EditCategoryDialog(category: widget.category),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    const double dialogWidth = 450;
    const double fontSize = 16;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.isMobile(context) ? 16.0 : 40.0,
          vertical: 24.0,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: dialogWidth,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Delete Category',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize + 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete "${widget.category.name}"?',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: fontSize,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This action cannot be undone.',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: fontSize - 2,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: fontSize - 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete, size: 18),
                    label: Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: fontSize - 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () {
                      BlocProvider.of<CategoryBloc>(context).add(
                        DeleteCategoryEvent(widget.category.id),
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Category deleted'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _IconActionButton({
    required this.icon,
    required this.onPressed,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(
            icon,
            size: 10,
            color: color,
          ),
        ),
      ),
    );
  }
}
