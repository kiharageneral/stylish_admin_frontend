
import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/products/presentation/widgets/product_images/product_image_carousel.dart';
import 'package:stylish_admin/features/products/presentation/widgets/product_images/product_image_picker.dart';
import 'package:stylish_admin/features/products/presentation/widgets/product_images/product_thumbnai_row.dart';

class ProductImageSection extends StatefulWidget {
  final List<String> initialImageUrls;
  final List<bool> initialIsPrimaryFlags;
  final String? primaryImageUrl;
  final Function(List<dynamic>, List<String>, List<bool>, String?)
      onImagesChanged;

  const ProductImageSection({
    super.key,
    this.initialImageUrls = const [],
    this.initialIsPrimaryFlags = const [],
    this.primaryImageUrl,
    required this.onImagesChanged,
  });

  @override
  State<ProductImageSection> createState() => _ProductImageSectionState();
}

class _ProductImageSectionState extends State<ProductImageSection> {
  late List<String> _imageUrls;
  late List<bool> _isPrimaryFlags;
  late List<dynamic> _imageFiles;
  int _currentImageIndex = 0;
  String? _primaryImageUrl;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _imageUrls = List.from(widget.initialImageUrls);
    _isPrimaryFlags = List.from(widget.initialIsPrimaryFlags);

    _imageFiles = List.generate(_imageUrls.length, (_) => null);
    _primaryImageUrl = widget.primaryImageUrl;

    if (_imageUrls.isNotEmpty && !_isPrimaryFlags.contains(true)) {
      _isPrimaryFlags[0] = true;
      _primaryImageUrl = _imageUrls[0];
    }
  }

  void _handleImagesSelected(List<dynamic> newImageFiles,
      List<String> newImageUrls, List<bool> newIsPrimaryFlags) {
    _isUpdating = true;

    setState(() {
      final List<dynamic> updatedFiles = List.from(_imageFiles);
      final List<String> updatedUrls = List.from(_imageUrls);
      final List<bool> updatedPrimaryFlags = List.from(_isPrimaryFlags);

      updatedFiles.addAll(newImageFiles);
      updatedUrls.addAll(newImageUrls);

      for (bool isPrimary in newIsPrimaryFlags) {
        updatedPrimaryFlags.add(isPrimary);
      }

      String? primaryUrl;
      if (!updatedPrimaryFlags.contains(true) && updatedUrls.isNotEmpty) {
        int indexToSetPrimary = updatedUrls.length - newImageUrls.length;

        for (int i = 0; i < updatedPrimaryFlags.length; i++) {
          updatedPrimaryFlags[i] = (i == indexToSetPrimary);
        }

        primaryUrl = updatedUrls[indexToSetPrimary];
      } else if (updatedPrimaryFlags.contains(true)) {
        int primaryIndex = updatedPrimaryFlags.indexOf(true);
        primaryUrl = updatedUrls[primaryIndex];
      }

      _imageFiles = updatedFiles;
      _imageUrls = updatedUrls;
      _isPrimaryFlags = updatedPrimaryFlags;
      _primaryImageUrl = primaryUrl;
      _currentImageIndex = updatedUrls.length - newImageUrls.length;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isUpdating = false;
      widget.onImagesChanged(
          _imageFiles, _imageUrls, _isPrimaryFlags, _primaryImageUrl);
    });
  }

  void _handleDelete(int index) {
    if (index < 0 || index >= _imageUrls.length) return;

    final isPrimary = _isPrimaryFlags[index];
    _isUpdating = true;

    setState(() {
      _imageUrls.removeAt(index);
      _isPrimaryFlags.removeAt(index);
      if (index < _imageFiles.length) {
        _imageFiles.removeAt(index);
      }

      if (_currentImageIndex >= _imageUrls.length) {
        _currentImageIndex = _imageUrls.isEmpty ? 0 : _imageUrls.length - 1;
      }

      if (isPrimary && _imageUrls.isNotEmpty) {
        _isPrimaryFlags[0] = true;
        _primaryImageUrl = _imageUrls[0];
      } else if (_imageUrls.isEmpty) {
        _primaryImageUrl = null;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isUpdating = false;
      widget.onImagesChanged(
          _imageFiles, _imageUrls, _isPrimaryFlags, _primaryImageUrl);
    });
  }

  void _handleSetPrimary(int index) {
    if (index < 0 || index >= _imageUrls.length) return;

    _isUpdating = true;

    setState(() {
      for (int i = 0; i < _isPrimaryFlags.length; i++) {
        _isPrimaryFlags[i] = false;
      }
      _isPrimaryFlags[index] = true;
      _primaryImageUrl = _imageUrls[index];
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isUpdating = false;
      widget.onImagesChanged(
          _imageFiles, _imageUrls, _isPrimaryFlags, _primaryImageUrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isUpdating) {
      return SizedBox(
        height: 400,
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryLight,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Product Images',
              style: AppTheme.headingMedium(),
            ),
            ProductImagePicker(
              key: ValueKey('product_image_picker_${_imageUrls.length}'),
              onImagesSelected: _handleImagesSelected,
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingSmall),

        if (_imageUrls.isNotEmpty)
          Column(
            children: [
              ProductImageCarousel(
                key: ValueKey(
                    'image_carousel_${_imageUrls.length}_${DateTime.now().millisecondsSinceEpoch}'),
                imageUrls: _imageUrls,
                imageFiles: _imageFiles,
                isPrimaryFlags: _isPrimaryFlags,
                initialIndex: _currentImageIndex,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                onDelete: _handleDelete,
                onSetPrimary: _handleSetPrimary,
              ),

              ProductThumbnailRow(
                key: ValueKey(
                    'thumbnail_row_${_imageUrls.length}_${DateTime.now().millisecondsSinceEpoch}'),
                imageUrls: _imageUrls,
                imageFiles: _imageFiles,
                isPrimaryFlags: _isPrimaryFlags,
                currentIndex: _currentImageIndex,
                onThumbnailTap: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                getKeyForIndex: null,
              ),
            ],
          )
        else
          EmptyImagePlaceholder(
            key: const ValueKey('empty_placeholder'),
            onTap: () {
              ProductImagePicker.pickImagesStatic(_handleImagesSelected);
            },
          ),
      ],
    );
  }
}

class EmptyImagePlaceholder extends StatelessWidget {
  final VoidCallback onTap;

  const EmptyImagePlaceholder({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 48,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              'Add product images',
              style: AppTheme.bodyMedium(),
            ),
          ],
        ),
      ),
    );
  }
}
