import 'package:flutter/material.dart';
import 'package:afyalink/core/theme.dart';

/// A network image that silently falls back to a placeholder when
/// the media file is missing (404) or when no URL is provided.
class ProductImage extends StatelessWidget {
  final String? url;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProductImage({
    super.key,
    this.url,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (url == null || url!.isEmpty) {
      image = _placeholder();
    } else {
      image = Image.network(
        url!,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading image: $url - $error');
          return _placeholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _shimmer();
        },
      );
    }


    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _placeholder() {
    return Container(
      height: height,
      width: width,
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication_outlined, size: (height ?? 80) * 0.35, color: AppTheme.primaryTeal.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _shimmer() {
    return Container(
      height: height,
      width: width,
      decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
    );
  }
}
