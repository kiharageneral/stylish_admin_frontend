import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';

class ProductImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final List<dynamic> imageFiles;
  final List<bool> isPrimaryFlags;
  final int initialIndex;
  final Function(int) onPageChanged;
  final Function(int) onDelete;
  final Function(int) onSetPrimary;

  const ProductImageCarousel({
    super.key,
    required this.imageUrls,
    required this.imageFiles,
    required this.isPrimaryFlags,
    required this.initialIndex,
    required this.onPageChanged,
    required this.onDelete,
    required this.onSetPrimary,
  });

  @override
  State<ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void didUpdateWidget(ProductImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _pageController.jumpToPage(widget.initialIndex);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            child: PageView.builder(
              itemCount: widget.imageUrls.length,
              controller: _pageController,
              onPageChanged: widget.onPageChanged,
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImagePreview(
                      widget.imageUrls[index],
                      index < widget.imageFiles.length
                          ? widget.imageFiles[index]
                          : null,
                    ),

                    // Delete button
                    Positioned(
                      top: AppTheme.spacingSmall,
                      right: AppTheme.spacingSmall,
                      child: IconButton(
                        onPressed: () => widget.onDelete(index),
                        icon: Icon(Icons.delete, color: AppTheme.negative),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.backgroundDark.withAlpha(
                            (0.7 * 255).round(),
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: AppTheme.spacingSmall,
                      left: AppTheme.spacingSmall,
                      child: IconButton(
                        onPressed: () => widget.onSetPrimary(index),
                        icon: Icon(
                          widget.isPrimaryFlags[index]
                              ? Icons.star
                              : Icons.star_border,
                          color: widget.isPrimaryFlags[index]
                              ? AppTheme.accentAmber
                              : AppTheme.textSecondary,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.backgroundDark.withAlpha(
                            (0.7*255).round(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(String imageUrl, dynamic imageFile) {
    final errorWidget = Center(
      child: Text(
        'Failed to load image',
        style: AppTheme.bodyMedium().copyWith(color: AppTheme.negative),
      ),
    );

    if (imageFile != null) {
      if (imageFile is Uint8List) {
        return Image.memory(
          imageFile,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => errorWidget,
        );
      } else if (imageFile is File) {
        return Image.file(
          imageFile,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => errorWidget,
        );
      }
    }

    if (imageUrl.startsWith('data:')) {
      try {
        final parts = imageUrl.split(',');
        if (parts.length > 1) {
          return Image.memory(
            base64Decode(parts[1]),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => errorWidget,
          );
        }
      } catch (e) {
        debugPrint('Error parsing data URL: $e');
      }
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => errorWidget,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            color: AppTheme.accentBlue,
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }
}
