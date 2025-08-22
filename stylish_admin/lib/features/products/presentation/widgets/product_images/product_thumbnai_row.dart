
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';

class ProductThumbnailRow extends StatelessWidget {
  final List<String> imageUrls;
  final List<dynamic> imageFiles;
  final List<bool> isPrimaryFlags;
  final int currentIndex;
  final Function(int) onThumbnailTap;
  final GlobalKey Function(int)? getKeyForIndex;

  const ProductThumbnailRow({
    super.key,
    required this.imageUrls,
    required this.imageFiles,
    required this.isPrimaryFlags,
    required this.currentIndex,
    required this.onThumbnailTap,
    this.getKeyForIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          final isSelected = index == currentIndex;
          final isPrimary = isPrimaryFlags[index];

          final itemKey = getKeyForIndex != null 
              ? getKeyForIndex!(index) 
              : ValueKey('thumbnail_$index');

          return GestureDetector(
            key: itemKey,
            onTap: () => onThumbnailTap(index),
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: AppTheme.spacingSmall),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryLight
                      : isPrimary
                          ? AppTheme.accentAmber
                          : AppTheme.borderColor,
                  width: isSelected || isPrimary ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: _getImageThumbnail(imageUrls[index], index),
                  ),
                  if (isPrimary)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spacingXSmall / 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentAmber,
                          borderRadius: BorderRadius.circular(AppTheme.spacingXSmall),
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getImageThumbnail(String imageUrl, int index) {
    if (index < imageFiles.length && imageFiles[index] != null) {
      if (imageFiles[index] is Uint8List) {
        return Image.memory(
          imageFiles[index],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Icon(Icons.broken_image, color: AppTheme.textSecondary));
          },
        );
      } else if (imageFiles[index] is File) {
        return Image.file(
          imageFiles[index],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Icon(Icons.broken_image, color: AppTheme.textSecondary));
          },
        );
      }
    }

    if (imageUrl.startsWith('data:')) {
      try {
        final parts = imageUrl.split(',');
        if (parts.length > 1) {
          return Image.memory(
            base64Decode(parts[1]),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.broken_image, color: AppTheme.textSecondary));
            },
          );
        }
      } catch (e) {
        debugPrint('Error parsing data URL: $e');
      }
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Center(child: Icon(Icons.broken_image, color: AppTheme.textSecondary));
      },
    );
  }
}