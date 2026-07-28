import 'package:flutter/material.dart';
import '../models/cloudinary_image.dart';
import 'cloudinary_image_widget.dart';
import 'context_menu_wrapper.dart';

class HZProductImageGallery extends StatefulWidget {
  final List<CloudinaryImage> images;

  const HZProductImageGallery({super.key, required this.images});

  @override
  State<HZProductImageGallery> createState() => _HZProductImageGalleryState();
}

class _HZProductImageGalleryState extends State<HZProductImageGallery> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: 450,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: const Center(child: Icon(Icons.checkroom, color: Color(0xFF888888), size: 64)),
      );
    }

    return Column(
      children: [
        // Main Image Display with Custom Right-Click / Download Context Menu
        HZContextMenuWrapper(
          imageUrl: widget.images[_selectedIndex].url,
          child: GestureDetector(
            onTap: () => _openFullscreenImageViewer(context, _selectedIndex),
            child: Container(
              height: 520,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E5E5)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16)],
              ),
              child: CloudinaryImageWidget(
                imageSource: widget.images[_selectedIndex],
                fit: BoxFit.contain,
                targetWidth: 1200,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Thumbnail Selector Strip
        if (widget.images.length > 1)
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedIndex;
                final img = widget.images[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF000000) : const Color(0xFFE5E5E5),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: CloudinaryImageWidget(
                      imageSource: img,
                      targetWidth: 200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _openFullscreenImageViewer(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        child: Stack(
          children: [
            Center(
              child: CloudinaryImageWidget(
                imageSource: widget.images[initialIndex],
                fit: BoxFit.contain,
                targetWidth: 1600,
              ),
            ),
            Positioned(
              top: 24,
              right: 24,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
