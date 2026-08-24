import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
      builder: (context) => HZFullscreenGalleryDialog(
        images: widget.images,
        initialIndex: initialIndex,
      ),
    );
  }
}

/// Fullscreen lightbox image viewer with keyboard navigation and on-screen controls
class HZFullscreenGalleryDialog extends StatefulWidget {
  final List<CloudinaryImage> images;
  final int initialIndex;

  const HZFullscreenGalleryDialog({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<HZFullscreenGalleryDialog> createState() => _HZFullscreenGalleryDialogState();
}

class _HZFullscreenGalleryDialogState extends State<HZFullscreenGalleryDialog> {
  late int _currentIndex;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.images.isNotEmpty ? widget.images.length - 1 : 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _prevImage() {
    if (widget.images.length <= 1) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + widget.images.length) % widget.images.length;
    });
  }

  void _nextImage() {
    if (widget.images.length <= 1) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.images.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        child: const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 64)),
      );
    }

    return Dialog.fullscreen(
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _prevImage();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _nextImage();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).pop();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            // Center Image
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.0,
                child: CloudinaryImageWidget(
                  imageSource: widget.images[_currentIndex],
                  fit: BoxFit.contain,
                  targetWidth: 1600,
                ),
              ),
            ),

            // Top-Left Image Counter
            if (widget.images.length > 1)
              Positioned(
                top: 24,
                left: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),

            // Top-Right Close Button
            Positioned(
              top: 20,
              right: 20,
              child: Semantics(
                button: true,
                label: 'Close gallery',
                child: Tooltip(
                  message: 'Close (Esc)',
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ),

            // On-screen Left Navigation Chevron (if multiple images)
            if (widget.images.length > 1)
              Positioned(
                left: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Semantics(
                    button: true,
                    label: 'Previous image',
                    child: Tooltip(
                      message: 'Previous (Left Arrow)',
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 36),
                          onPressed: _prevImage,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // On-screen Right Navigation Chevron (if multiple images)
            if (widget.images.length > 1)
              Positioned(
                right: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Semantics(
                    button: true,
                    label: 'Next image',
                    child: Tooltip(
                      message: 'Next (Right Arrow)',
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.white, size: 36),
                          onPressed: _nextImage,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
