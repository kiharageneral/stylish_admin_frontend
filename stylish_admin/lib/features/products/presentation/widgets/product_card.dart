import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stylish_admin/core/routes/route_names.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/core/utils/responsive_helper.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';

class ProductCard extends StatefulWidget {
  final ProductEntity product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isSelected;
  final ValueChanged<bool>? onSelect;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;
  int _currentImageIndex = 0;
  late PageController _pageController;

  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _imageUrls = _getImageUrlsList();
    _pageController = PageController(initialPage: _currentImageIndex);

    if (widget.product.primaryImage != null) {
      for (int i = 0; i < _imageUrls.length; i++) {
        if (_imageUrls[i] == widget.product.primaryImage?.imageUrl) {
          _currentImageIndex = i;
          break;
        }
      }
    }
  }

  Widget _buildImage(int index) {
    String url = _imageUrls[index];

    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppTheme.backgroundMedium,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildErrorImage(),
      );
    } else if (url.startsWith('data:image')) {
      return FutureBuilder<Uint8List>(
        future: Future.microtask(() => base64Decode(url.split(',')[1])),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          }
          return Container(
            color: AppTheme.backgroundMedium,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    } else {
      return _buildErrorImage();
    }
  }

  List<String> _getImageUrlsList() {
    if (widget.product.images.isNotEmpty) {
      return widget.product.images.map((img) => img.imageUrl).toList();
    }

    if (widget.product.primaryImage != null) {
      return [widget.product.primaryImage!.imageUrl];
    }

    if (widget.product.primaryImageUrl != null &&
        widget.product.primaryImageUrl!.isNotEmpty) {
      return [widget.product.primaryImageUrl!];
    }

    return [];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getFormattedRatingCount(int count) {
    if (count == 0) return 'No reviews';
    if (count == 1) return '(1 review)';
    return '($count reviews)';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, RouteNames.productDetails,
            arguments: widget.product);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Card(
          elevation: _isHovered ? 4 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            side: widget.isSelected
                ? BorderSide(color: AppTheme.primaryLight, width: 2)
                : BorderSide.none,
          ),
          color: AppTheme.cardBackground,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image section
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppTheme.borderRadiusMedium),
                        ),
                        child: AspectRatio(
                          aspectRatio: ResponsiveHelper.isTablet(context)
                              ? 1.2
                              : 1.5,
                          child: _imageUrls.isEmpty
                              ? _buildPlaceholderImage()
                              : _buildImage(0),
                        ),
                      ),
                      // Stock indicator
                      Positioned(
                        top: AppTheme.spacingSmall,
                        left: AppTheme.spacingSmall,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingSmall,
                            vertical: AppTheme.spacingXSmall,
                          ),
                          decoration: BoxDecoration(
                            color: _getStockStatusColor(),
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusSmall,
                            ),
                          ),
                          child: Text(
                            _getStockStatusText(),
                            style: AppTheme.bodyXSmall().copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Active/Inactive status
                      if (!widget.product.isActive)
                        Positioned.fill(
                          child: Container(
                            color: Colors.grey.withAlpha((0.6 * 255).round()),
                            child: Center(
                              child: Text(
                                'INACTIVE',
                                style: AppTheme.bodyMedium().copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Navigation arrows
                      if (_getImageCount() > 1 && _isHovered)
                        _buildImageNavigation(),
                      // Image indicator dots
                      if (_getImageCount() > 1) _buildImageIndicators(),
                      // Price tag on image
                      Positioned(
                        bottom: AppTheme.spacingSmall,
                        right: AppTheme.spacingSmall,
                        child: _buildPriceTag(),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          widget.product.name,
                          style: AppTheme.bodyLarge().copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTheme.spacingXSmall),

                        // Category
                        Text(
                          widget.product.category.name,
                          style: AppTheme.bodySmall(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTheme.spacingSmall),

                        // Ratings
                        Row(
                          children: [
                            ...List.generate(5, (index) {
                              double rating = widget.product.rating.value;
                              return Icon(
                                index < rating.floor()
                                    ? Icons.star
                                    : (index < rating
                                          ? Icons.star_half
                                          : Icons.star_border),
                                size: 16,
                                color: AppTheme.accentAmber,
                              );
                            }),
                            const SizedBox(width: AppTheme.spacingXSmall),
                            Text(
                              _getFormattedRatingCount(
                                widget.product.rating.value.toInt(),
                              ),
                              style: AppTheme.bodyXSmall(),
                            ),
                            // Profit margin indicator
                            if (widget.product.profitMargin != null)
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getProfitMarginColor(),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.borderRadiusSmall,
                                      ),
                                    ),
                                    child: Text(
                                      '${widget.product.profitMargin!.toStringAsFixed(1)}%',
                                      style: AppTheme.bodyXSmall().copyWith(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Selection checkbox for bulk operations
              if (widget.onSelect != null)
                Positioned(
                  right: AppTheme.spacingSmall,
                  top: AppTheme.spacingSmall,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground.withAlpha(
                        (0.8 * 255).round(),
                      ),
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusSmall,
                      ),
                    ),
                    child: Checkbox(
                      value: widget.isSelected,
                      onChanged: (value) =>
                          widget.onSelect?.call(value ?? false),
                      fillColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? AppTheme.primaryLight
                            : null,
                      ),
                    ),
                  ),
                ),

              // Action buttons
              if (_isHovered)
                Positioned(
                  right: AppTheme.spacingSmall,
                  bottom: AppTheme.spacingSmall,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete, size: 20),
                        tooltip: 'Delete Product',
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.cardBackground,
                          foregroundColor: AppTheme.accentRed,
                          padding: const EdgeInsets.all(AppTheme.spacingSmall),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppTheme.backgroundMedium,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 48, color: AppTheme.textSecondary),
            SizedBox(height: AppTheme.spacingSmall),
            Text(
              'No Image',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceTag() {
    final displayPrice = widget.product.displayPrice.value;
    final originalPrice = widget.product.price.value;
    final discountPrice = widget.product.discountPrice?.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (discountPrice != null && discountPrice < originalPrice)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSmall,
              vertical: AppTheme.spacingXSmall,
            ),
            decoration: BoxDecoration(
              color: AppTheme.accentRed,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            ),
            child: Text(
              '\$${originalPrice.toStringAsFixed(2)}',
              style: AppTheme.bodyXSmall().copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
        const SizedBox(height: AppTheme.spacingXSmall),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSmall,
            vertical: AppTheme.spacingXSmall,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
          child: Text(
            '\$${displayPrice.toStringAsFixed(2)}',
            style: AppTheme.bodySmall().copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorImage() {
    return Container(
      color: AppTheme.backgroundMedium,
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 40,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildImageNavigation() {
    return Positioned.fill(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left arrow
          if (_currentImageIndex > 0)
            GestureDetector(
              onTap: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                margin: const EdgeInsets.only(left: AppTheme.spacingSmall),
                padding: const EdgeInsets.all(AppTheme.spacingSmall),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground.withAlpha((0.8 * 255).round()),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_left,
                  size: 24,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),

          // Right arrow
          if (_currentImageIndex < _getImageCount() - 1)
            GestureDetector(
              onTap: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: AppTheme.spacingSmall),
                padding: const EdgeInsets.all(AppTheme.spacingSmall),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground.withAlpha((0.8 * 255).round()),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageIndicators() {
    return Positioned(
      bottom: 36,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_getImageCount(), (index) {
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentImageIndex == index
                  ? AppTheme.primaryLight
                  : AppTheme.textPrimary.withAlpha((0.5 * 255).round()),
            ),
          );
        }),
      ),
    );
  }

  int _getImageCount() {
    return _imageUrls.length;
  }

  String _getStockStatusText() {
    final status = widget.product.stockStatus;

    switch (status) {
      case StockStatus.outOfStock:
        return 'OUT OF STOCK';
      case StockStatus.lowStock:
        return 'LOW STOCK: ${widget.product.stock}';
      case StockStatus.inStock:
        return 'IN STOCK';
      
    }
  }

  Color _getStockStatusColor() {
    switch (widget.product.stockStatus) {
      case StockStatus.outOfStock:
        return AppTheme.accentRed;
      case StockStatus.lowStock:
        return AppTheme.accentOrange;
      case StockStatus.inStock:
        return AppTheme.accentGreen;
    }
  }

  Color _getProfitMarginColor() {
    final margin = widget.product.profitMargin;
    if (margin == null) return Colors.grey;

    if (margin < 15) {
      return AppTheme.accentRed;
    } else if (margin < 30) {
      return AppTheme.accentOrange;
    } else {
      return AppTheme.accentGreen;
    }
  }
}
