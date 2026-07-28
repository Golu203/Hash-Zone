import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/cloudinary_image.dart';

class CloudinaryImageWidget extends StatelessWidget {
  final dynamic imageSource; // Can be CloudinaryImage or String URL
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? targetWidth;
  final int? targetHeight;
  final String crop;
  final BorderRadius? borderRadius;
  final String? altText;

  const CloudinaryImageWidget({
    super.key,
    required this.imageSource,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.targetWidth,
    this.targetHeight,
    this.crop = 'limit',
    this.borderRadius,
    this.altText,
  });

  String _buildTransformUrl() {
    String rawUrl = '';
    if (imageSource is CloudinaryImage) {
      rawUrl = (imageSource as CloudinaryImage).url;
    } else if (imageSource is String) {
      rawUrl = imageSource as String;
    }

    if (rawUrl.isEmpty) return '';

    if (!rawUrl.contains('/upload/')) return rawUrl;

    final transforms = <String>['f_auto', 'q_auto'];
    if (targetWidth != null && targetWidth! > 0) {
      transforms.add('w_$targetWidth');
    }
    if (targetHeight != null && targetHeight! > 0) {
      transforms.add('h_$targetHeight');
    }
    if (targetWidth != null || targetHeight != null) {
      transforms.add('c_$crop');
    }

    final transformStr = '${transforms.join(',')}/';
    return rawUrl.replaceFirst('/upload/', '/upload/$transformStr');
  }

  @override
  Widget build(BuildContext context) {
    final finalUrl = _buildTransformUrl();

    Widget imageContent;

    if (finalUrl.isEmpty) {
      imageContent = Container(
        width: width,
        height: height,
        color: const Color(0xFFF5F5F7),
        child: const Center(
          child: Icon(Icons.checkroom, color: Color(0xFFBBBBBB), size: 40),
        ),
      );
    } else {
      imageContent = Image.network(
        finalUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: child,
            );
          }
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFF5F5F7),
            child: const Center(
              child: SpinKitPulse(color: Color(0xFFBBBBBB), size: 36),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFF5F5F7),
            child: const Center(
              child: Icon(Icons.broken_image_outlined, color: Color(0xFFBBBBBB), size: 36),
            ),
          );
        },
      );
    }

    if (borderRadius != null) {
      imageContent = ClipRRect(
        borderRadius: borderRadius!,
        child: imageContent,
      );
    }

    if (altText != null && altText!.isNotEmpty) {
      imageContent = Semantics(
        label: altText,
        image: true,
        child: imageContent,
      );
    }

    return imageContent;
  }
}
