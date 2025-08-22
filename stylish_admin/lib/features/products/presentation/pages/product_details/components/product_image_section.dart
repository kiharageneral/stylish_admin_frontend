import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/core/utils/responsive_helper.dart';
import 'package:stylish_admin/features/products/domain/entities/products_entity.dart';


class ProductImagesSection extends StatefulWidget {
  final ProductEntity product;

  const ProductImagesSection({
    super.key,
    required this.product,
  });

  @override
  State<ProductImagesSection> createState() => _ProductImagesSectionState();
}

class _ProductImagesSectionState extends State<ProductImagesSection> {
  int _currentImageIndex = 0;
  PageController? _pageController;
  bool _isDisposed = false;
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeImageUrls();
  }

  @override
  void didUpdateWidget(ProductImagesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product != widget.product) {
      _initializeImageUrls();
      // Reset to first image when product changes
      if (_currentImageIndex >= _imageUrls.length) {
        _currentImageIndex = 0;
        _pageController?.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _initializeImageUrls() {
    final urls = <String>[];
    
    for (final image in widget.product.images) {
      if (image.imageUrl.isNotEmpty && _isValidImageUrl(image.imageUrl)) {
        urls.add(image.imageUrl);
      }
    }
    
    if (widget.product.primaryImage != null && 
        widget.product.primaryImage!.imageUrl.isNotEmpty &&
        _isValidImageUrl(widget.product.primaryImage!.imageUrl) &&
        !urls.contains(widget.product.primaryImage!.imageUrl)) {
      urls.insert(0, widget.product.primaryImage!.imageUrl);
    }
    
    if (widget.product.primaryImageUrl != null && 
        widget.product.primaryImageUrl!.isNotEmpty &&
        _isValidImageUrl(widget.product.primaryImageUrl!) &&
        !urls.contains(widget.product.primaryImageUrl!)) {
      urls.add(widget.product.primaryImageUrl!);
    }
    
    setState(() {
      _imageUrls = urls;
    });
  }

  bool _isValidImageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pageController?.dispose();
    _pageController = null;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageUrls.isEmpty) {
      return _buildNoImagePlaceholder();
    }

    final isSmallScreen = ResponsiveHelper.isMobile(context);
    final aspectRatio = ResponsiveHelper.getResponsiveAspectRatio(
      context,
      forMobile: 1.0,
      forTablet: 1.0,
      forDesktop: 1.2,
      forLargeDesktop: 1.3,
    );

    final thumbnailHeight = ResponsiveHelper.getResponsiveWidth(
      context,
      forMobile: 70,
      forTablet: 80,
      forDesktop: 90,
      forLargeDesktop: 100,
    );
    final thumbnailWidth = thumbnailHeight * 0.75;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: aspectRatio,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _imageUrls.length,
                  onPageChanged: (index) {
                    _safeSetState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildMainImageItem(_imageUrls[index]);
                  },
                ),
              ),
              
              // Navigation arrows
              if (_imageUrls.length > 1) ...[
                _buildNavigationArrows(isSmallScreen),
                _buildImageIndicators(isSmallScreen),
              ],
              
              // Zoom button
              Positioned(
                top: AppTheme.spacingSmall,
                right: AppTheme.spacingSmall,
                child: _buildZoomButton(),
              ),
            ],
          ),

          // Thumbnail gallery
          if (_imageUrls.length > 1)
            _buildThumbnailGallery(thumbnailHeight, thumbnailWidth),
        ],
      ),
    );
  }

  Widget _buildMainImageItem(String imageUrl) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(imageUrl),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        placeholder: (context, url) => _buildImagePlaceholder(),
        errorWidget: (context, url, error) => _buildErrorImage(),
        fadeInDuration: const Duration(milliseconds: 200),
        memCacheWidth: 800, 
        memCacheHeight: 800,
      ),
    );
  }

  Widget _buildNavigationArrows(bool isSmallScreen) {
    return Positioned.fill(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentImageIndex > 0)
            _buildNavigationButton(
              icon: Icons.chevron_left,
              onPressed: () => _pageController?.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              isSmallScreen: isSmallScreen,
            ),
          if (_currentImageIndex < _imageUrls.length - 1)
            _buildNavigationButton(
              icon: Icons.chevron_right,
              onPressed: () => _pageController?.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              isSmallScreen: isSmallScreen,
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isSmallScreen,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: isSmallScreen ? 20 : 24,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageIndicators(bool isSmallScreen) {
    return Positioned(
      bottom: AppTheme.spacingMedium,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_imageUrls.length, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _currentImageIndex == index ? (isSmallScreen ? 20 : 24) : (isSmallScreen ? 6 : 8),
            height: isSmallScreen ? 6 : 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentImageIndex == index
                  ? AppTheme.primaryLight
                  : Colors.white.withOpacity(0.5),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildZoomButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showFullScreenImage(_imageUrls[_currentImageIndex]),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.zoom_in,
            size: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailGallery(double thumbnailHeight, double thumbnailWidth) {
    return SizedBox(
      height: thumbnailHeight,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingSmall),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _imageUrls.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                _pageController?.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                width: thumbnailWidth,
                height: thumbnailHeight * 0.8,
                margin: const EdgeInsets.only(right: AppTheme.spacingSmall),
                decoration: BoxDecoration(
                  border: _currentImageIndex == index
                      ? Border.all(color: AppTheme.primaryLight, width: 2)
                      : Border.all(color: Colors.grey.shade300, width: 1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall - 2),
                  child: CachedNetworkImage(
                    imageUrl: _imageUrls[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildImagePlaceholder(size: 24),
                    errorWidget: (context, url, error) => _buildErrorImage(iconSize: 24),
                    memCacheWidth: 200,
                    memCacheHeight: 200,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder({double size = 40}) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            if (size > 30) ...[
              const SizedBox(height: 8),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorImage({double iconSize = 40}) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: iconSize,
              color: Colors.grey.shade400,
            ),
            if (iconSize > 30) ...[
              const SizedBox(height: 8),
              Text(
                'Image not available',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: AspectRatio(
        aspectRatio: 1.2,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No images available',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Product images will appear here when added',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ImageFullScreenViewer(
          imageUrls: _imageUrls,
          initialIndex: _currentImageIndex,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class ImageFullScreenViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageFullScreenViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<ImageFullScreenViewer> createState() => _ImageFullScreenViewerState();
}

class _ImageFullScreenViewerState extends State<ImageFullScreenViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Main image viewer
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Top bar with close button and counter
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Navigation arrows for multiple images
          if (widget.imageUrls.length > 1)
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentIndex > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_currentIndex < widget.imageUrls.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}