import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HZFreeCropperModal extends StatefulWidget {
  final Uint8List imageBytes;
  final String filename;

  const HZFreeCropperModal({
    super.key,
    required this.imageBytes,
    required this.filename,
  });

  /// Helper static method to open the free-style cropper dialog and return cropped bytes.
  static Future<Uint8List?> cropImage(
    BuildContext context, {
    required Uint8List imageBytes,
    required String filename,
  }) async {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (context) => HZFreeCropperModal(
        imageBytes: imageBytes,
        filename: filename,
      ),
    );
  }

  @override
  State<HZFreeCropperModal> createState() => _HZFreeCropperModalState();
}

class _HZFreeCropperModalState extends State<HZFreeCropperModal> {
  ui.Image? _decodedImage;
  bool _isLoading = true;

  // Viewport and Crop Rect (relative to the viewport)
  Size _viewportSize = Size.zero;
  Rect? _imageRect; // actual bounding box of the contained image on screen
  Rect? _cropRect; // current draggable crop rectangle on screen

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void dispose() {
    _decodedImage?.dispose();
    super.dispose();
  }

  Future<void> _decodeImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _decodedImage = frame.image;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load image: $e'), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    }
  }

  void _initLayoutIfNeeded(Size viewportSize) {
    if (_decodedImage == null) return;
    if (_viewportSize == viewportSize && _cropRect != null) return;

    _viewportSize = viewportSize;

    // 1. Calculate image bounding box inside viewport using BoxFit.contain
    final double imgW = _decodedImage!.width.toDouble();
    final double imgH = _decodedImage!.height.toDouble();

    // Leave a 20px padding around the viewport
    final double availW = viewportSize.width - 40;
    final double availH = viewportSize.height - 40;

    final double scale = (availW / imgW < availH / imgH) ? (availW / imgW) : (availH / imgH);
    final double displayW = imgW * scale;
    final double displayH = imgH * scale;

    final double displayLeft = (viewportSize.width - displayW) / 2;
    final double displayTop = (viewportSize.height - displayH) / 2;

    _imageRect = Rect.fromLTWH(displayLeft, displayTop, displayW, displayH);

    // 2. Initialize crop rectangle to occupy 85% of the image display area
    final double cropW = displayW * 0.85;
    final double cropH = displayH * 0.85;
    final double cropLeft = displayLeft + (displayW - cropW) / 2;
    final double cropTop = displayTop + (displayH - cropH) / 2;

    _cropRect = Rect.fromLTWH(cropLeft, cropTop, cropW, cropH);
  }

  // Drags the entire crop box
  void _moveCropBox(Offset delta) {
    if (_cropRect == null || _imageRect == null) return;

    double left = _cropRect!.left + delta.dx;
    double top = _cropRect!.top + delta.dy;

    // Keep crop box inside image boundaries
    if (left < _imageRect!.left) left = _imageRect!.left;
    if (top < _imageRect!.top) top = _imageRect!.top;
    if (left + _cropRect!.width > _imageRect!.right) {
      left = _imageRect!.right - _cropRect!.width;
    }
    if (top + _cropRect!.height > _imageRect!.bottom) {
      top = _imageRect!.bottom - _cropRect!.height;
    }

    setState(() {
      _cropRect = Rect.fromLTWH(left, top, _cropRect!.width, _cropRect!.height);
    });
  }

  // Drags individual corners / edges
  void _resizeCropBox({
    double? leftDelta,
    double? rightDelta,
    double? topDelta,
    double? bottomDelta,
  }) {
    if (_cropRect == null || _imageRect == null) return;

    double left = _cropRect!.left;
    double top = _cropRect!.top;
    double right = _cropRect!.right;
    double bottom = _cropRect!.bottom;

    const double minSize = 60.0; // Min crop box size to prevent collapsing

    if (leftDelta != null) {
      left = (left + leftDelta).clamp(_imageRect!.left, right - minSize);
    }
    if (rightDelta != null) {
      right = (right + rightDelta).clamp(left + minSize, _imageRect!.right);
    }
    if (topDelta != null) {
      top = (top + topDelta).clamp(_imageRect!.top, bottom - minSize);
    }
    if (bottomDelta != null) {
      bottom = (bottom + bottomDelta).clamp(top + minSize, _imageRect!.bottom);
    }

    setState(() {
      _cropRect = Rect.fromLTRB(left, top, right, bottom);
    });
  }

  Future<void> _processCrop() async {
    if (_decodedImage == null || _cropRect == null || _imageRect == null) return;

    setState(() => _isLoading = true);

    try {
      final double originalW = _decodedImage!.width.toDouble();
      final double originalH = _decodedImage!.height.toDouble();

      // Get relative crop coordinates relative to the on-screen image box
      final double relLeft = (_cropRect!.left - _imageRect!.left) / _imageRect!.width;
      final double relTop = (_cropRect!.top - _imageRect!.top) / _imageRect!.height;
      final double relWidth = _cropRect!.width / _imageRect!.width;
      final double relHeight = _cropRect!.height / _imageRect!.height;

      // Map back to native resolution coordinates
      final double srcX = (relLeft * originalW).clamp(0.0, originalW);
      final double srcY = (relTop * originalH).clamp(0.0, originalH);
      final double srcW = (relWidth * originalW).clamp(10.0, originalW - srcX);
      final double srcH = (relHeight * originalH).clamp(10.0, originalH - srcY);

      // Create new high-quality canvas at the exact cropped native size
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, srcW, srcH));
      final paint = Paint()..filterQuality = FilterQuality.high;

      canvas.drawImageRect(
        _decodedImage!,
        Rect.fromLTWH(srcX, srcY, srcW, srcH),
        Rect.fromLTWH(0, 0, srcW, srcH),
        paint,
      );

      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(srcW.round(), srcH.round());
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null && mounted) {
        Navigator.pop(context, byteData.buffer.asUint8List());
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cropping image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 700;

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: isMobile ? const EdgeInsets.all(10) : const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? screenSize.width : 750,
        height: isMobile ? screenSize.height * 0.85 : 620,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP 1: FREE CROP',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Drag corners to select the region to keep',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFAAAAAA)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(color: Color(0xFF222222), height: 32),

            // Viewport
            Expanded(
              child: Stack(
                children: [
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    ),

                  if (!_isLoading && _decodedImage != null)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(constraints.maxWidth, constraints.maxHeight);
                        _initLayoutIfNeeded(size);

                        if (_cropRect == null || _imageRect == null) {
                          return const SizedBox.shrink();
                        }

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            // 1. Raw image centered inside the display box
                            Positioned.fromRect(
                              rect: _imageRect!,
                              child: RawImage(
                                image: _decodedImage,
                                fit: BoxFit.fill,
                              ),
                            ),

                            // 2. Translucent dark overlay with hole for crop area
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _CropOverlayPainter(
                                  imageRect: _imageRect!,
                                  cropRect: _cropRect!,
                                ),
                              ),
                            ),

                            // 3. Draggable handles & center movement box
                            // Center drag area
                            Positioned.fromRect(
                              rect: _cropRect!,
                              child: GestureDetector(
                                onPanUpdate: (details) => _moveCropBox(details.delta),
                                child: Container(
                                  color: Colors.transparent,
                                ),
                              ),
                            ),
                            // Top border handle
                            Positioned(
                              left: _cropRect!.left + 15,
                              right: _viewportSize.width - _cropRect!.right + 15,
                              top: _cropRect!.top - 10,
                              height: 20,
                              child: GestureDetector(
                                onVerticalDragUpdate: (details) => _resizeCropBox(topDelta: details.delta.dy),
                                child: Container(color: Colors.transparent),
                              ),
                            ),
                            // Bottom border handle
                            Positioned(
                              left: _cropRect!.left + 15,
                              right: _viewportSize.width - _cropRect!.right + 15,
                              top: _cropRect!.bottom - 10,
                              height: 20,
                              child: GestureDetector(
                                onVerticalDragUpdate: (details) => _resizeCropBox(bottomDelta: details.delta.dy),
                                child: Container(color: Colors.transparent),
                              ),
                            ),
                            // Left border handle
                            Positioned(
                              left: _cropRect!.left - 10,
                              top: _cropRect!.top + 15,
                              bottom: _viewportSize.height - _cropRect!.bottom + 15,
                              width: 20,
                              child: GestureDetector(
                                onHorizontalDragUpdate: (details) => _resizeCropBox(leftDelta: details.delta.dx),
                                child: Container(color: Colors.transparent),
                              ),
                            ),
                            // Right border handle
                            Positioned(
                              left: _cropRect!.right - 10,
                              top: _cropRect!.top + 15,
                              bottom: _viewportSize.height - _cropRect!.bottom + 15,
                              width: 20,
                              child: GestureDetector(
                                onHorizontalDragUpdate: (details) => _resizeCropBox(rightDelta: details.delta.dx),
                                child: Container(color: Colors.transparent),
                              ),
                            ),

                            // Corner Handles (Standard drag targets)
                            // Top-Left corner
                            Positioned(
                              left: _cropRect!.left - 15,
                              top: _cropRect!.top - 15,
                              child: _CornerHandle(
                                onPanUpdate: (details) {
                                  _resizeCropBox(leftDelta: details.delta.dx, topDelta: details.delta.dy);
                                },
                              ),
                            ),
                            // Top-Right corner
                            Positioned(
                              left: _cropRect!.right - 15,
                              top: _cropRect!.top - 15,
                              child: _CornerHandle(
                                onPanUpdate: (details) {
                                  _resizeCropBox(rightDelta: details.delta.dx, topDelta: details.delta.dy);
                                },
                              ),
                            ),
                            // Bottom-Left corner
                            Positioned(
                              left: _cropRect!.left - 15,
                              top: _cropRect!.bottom - 15,
                              child: _CornerHandle(
                                onPanUpdate: (details) {
                                  _resizeCropBox(leftDelta: details.delta.dx, bottomDelta: details.delta.dy);
                                },
                              ),
                            ),
                            // Bottom-Right corner
                            Positioned(
                              left: _cropRect!.right - 15,
                              top: _cropRect!.bottom - 15,
                              child: _CornerHandle(
                                onPanUpdate: (details) {
                                  _resizeCropBox(rightDelta: details.delta.dx, bottomDelta: details.delta.dy);
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF222222), height: 32),

            // Footer controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(color: const Color(0xFF888888), fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _processCrop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Done & Next',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  final Rect imageRect;
  final Rect cropRect;

  _CropOverlayPainter({required this.imageRect, required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw dark translucent overlay on the image bounding area (except crop box)
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.5);

    final path = Path()
      ..addRect(imageRect)
      ..addRect(cropRect);
    
    // Draw using EvenOdd path fill to exclude the transparent crop box area
    canvas.drawPath(
      path..fillType = PathFillType.evenOdd,
      overlayPaint,
    );

    // 2. Draw crop box border outline
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(cropRect, borderPaint);
    
    // Draw corner guides inside the crop box
    final guidePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    // Thirds gridlines
    final double thirdW = cropRect.width / 3;
    final double thirdH = cropRect.height / 3;
    
    canvas.drawLine(Offset(cropRect.left + thirdW, cropRect.top), Offset(cropRect.left + thirdW, cropRect.bottom), guidePaint);
    canvas.drawLine(Offset(cropRect.left + 2 * thirdW, cropRect.top), Offset(cropRect.left + 2 * thirdW, cropRect.bottom), guidePaint);
    canvas.drawLine(Offset(cropRect.left, cropRect.top + thirdH), Offset(cropRect.right, cropRect.top + thirdH), guidePaint);
    canvas.drawLine(Offset(cropRect.left, cropRect.top + 2 * thirdH), Offset(cropRect.right, cropRect.top + 2 * thirdH), guidePaint);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.imageRect != imageRect || oldDelegate.cropRect != cropRect;
  }
}

class _CornerHandle extends StatelessWidget {
  final void Function(DragUpdateDetails details) onPanUpdate;

  const _CornerHandle({required this.onPanUpdate});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: onPanUpdate,
      child: Container(
        width: 30,
        height: 30,
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                )
              ]
            ),
          ),
        ),
      ),
    );
  }
}
