import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum CropAspectRatioOption {
  product3x4,
  gallery4x3,
  square1x1,
  banner16x9,
  banner21x9,
  promoPopup,
}

class HZImageCropperModal extends StatefulWidget {
  final Uint8List imageBytes;
  final String filename;
  final CropAspectRatioOption initialRatio;

  const HZImageCropperModal({
    super.key,
    required this.imageBytes,
    required this.filename,
    this.initialRatio = CropAspectRatioOption.product3x4,
  });

  /// Helper static method to open cropper dialog and return processed cropped bytes
  static Future<Uint8List?> cropImage(
    BuildContext context, {
    required Uint8List imageBytes,
    required String filename,
    CropAspectRatioOption initialRatio = CropAspectRatioOption.product3x4,
  }) async {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (context) => HZImageCropperModal(
        imageBytes: imageBytes,
        filename: filename,
        initialRatio: initialRatio,
      ),
    );
  }

  @override
  State<HZImageCropperModal> createState() => _HZImageCropperModalState();
}

class _HZImageCropperModalState extends State<HZImageCropperModal> {
  ui.Image? _decodedImage;
  bool _isLoading = true;
  int _rotationQuarterTurns = 0;
  late CropAspectRatioOption _selectedRatio;

  // Image Pan & Scale State
  Offset _imagePanOffset = Offset.zero;
  double _imageScale = 1.0;

  // Fixed Visible Crop Box Rect
  Rect? _cropRect;
  Size _viewportSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _selectedRatio = widget.initialRatio;
    _decodeImage();
  }

  @override
  void dispose() {
    _decodedImage?.dispose();
    super.dispose();
  }

  Future<void> _decodeImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _decodedImage = frame.image;
        _isLoading = false;
      });
    }
  }

  double _getAspectRatioValue() {
    switch (_selectedRatio) {
      case CropAspectRatioOption.product3x4:
        return 3.0 / 4.0;
      case CropAspectRatioOption.gallery4x3:
        return 4.0 / 3.0;
      case CropAspectRatioOption.square1x1:
        return 1.0;
      case CropAspectRatioOption.banner16x9:
      case CropAspectRatioOption.banner21x9:
        return 21.0 / 9.0; // 21:9 Ultra-Wide Full Width Screen Ratio (2.33:1)
      case CropAspectRatioOption.promoPopup:
        return 1.0;
    }
  }

  String _getRatioLabel() {
    switch (_selectedRatio) {
      case CropAspectRatioOption.product3x4:
        return '3:4 PORTRAIT COVER IMAGE FRAME (FIXED)';
      case CropAspectRatioOption.gallery4x3:
        return '4:3 LANDSCAPE GALLERY IMAGE FRAME (FIXED)';
      case CropAspectRatioOption.square1x1:
        return '1:1 SEGMENT & CATEGORY COVER FRAME (FIXED)';
      case CropAspectRatioOption.banner16x9:
      case CropAspectRatioOption.banner21x9:
        return '21:9 ULTRA-WIDE HERO BANNER VISIBLE FRAME (FIXED)';
      case CropAspectRatioOption.promoPopup:
        return 'PROMO POPUP VISIBLE FRAME (FIXED)';
    }
  }

  void _initCropRectIfNeeded(Size size) {
    if (_viewportSize == size && _cropRect != null) return;

    _viewportSize = size;
    final double targetRatio = _getAspectRatioValue();

    double w = size.width * 0.85;
    double h = w / targetRatio;

    if (h > size.height * 0.85) {
      h = size.height * 0.85;
      w = h * targetRatio;
    }

    final double left = (size.width - w) / 2;
    final double top = (size.height - h) / 2;
    _cropRect = Rect.fromLTWH(left, top, w, h);
  }

  void _rotateClockwise() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  void _resetAdjustment() {
    setState(() {
      _rotationQuarterTurns = 0;
      _imagePanOffset = Offset.zero;
      _imageScale = 1.0;
      if (_viewportSize != Size.zero) {
        _cropRect = null;
        _initCropRectIfNeeded(_viewportSize);
      }
    });
  }

  void _fitImageToVisibleArea() {
    if (_decodedImage == null || _cropRect == null) return;

    final double imgW = _decodedImage!.width.toDouble();
    final double imgH = _decodedImage!.height.toDouble();
    final double cropW = _cropRect!.width;
    final double cropH = _cropRect!.height;

    final double scaleW = cropW / imgW;
    final double scaleH = cropH / imgH;
    final double fitScale = scaleW > scaleH ? scaleW : scaleH;

    setState(() {
      _imageScale = fitScale;
      _imagePanOffset = Offset.zero;
    });
  }

  Future<void> _processAndApplyCrop() async {
    if (_decodedImage == null || _cropRect == null || _viewportSize == Size.zero) return;

    setState(() => _isLoading = true);

    try {
      final double targetRatio = _getAspectRatioValue();

      final int outputWidth = (_selectedRatio == CropAspectRatioOption.banner16x9 || _selectedRatio == CropAspectRatioOption.banner21x9) ? 2100 : 1200;
      final int outputHeight = (outputWidth / targetRatio).round();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()));

      // White background fill for any empty surrounding space
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()), bgPaint);

      // Relative coordinates of image inside fixed crop window
      final double imgW = _decodedImage!.width.toDouble();
      final double imgH = _decodedImage!.height.toDouble();
      final Offset center = Offset(_viewportSize.width / 2, _viewportSize.height / 2);

      final double currentImgW = imgW * _imageScale;
      final double currentImgH = imgH * _imageScale;

      final Offset imgTopLeft = center + _imagePanOffset - Offset(currentImgW / 2, currentImgH / 2);

      final double relativeCropLeft = (_cropRect!.left - imgTopLeft.dx) / currentImgW;
      final double relativeCropTop = (_cropRect!.top - imgTopLeft.dy) / currentImgH;
      final double relativeCropW = _cropRect!.width / currentImgW;
      final double relativeCropH = _cropRect!.height / currentImgH;

      final double srcX = (relativeCropLeft * imgW).clamp(0, imgW);
      final double srcY = (relativeCropTop * imgH).clamp(0, imgH);
      final double srcW = (relativeCropW * imgW).clamp(10, imgW - srcX);
      final double srcH = (relativeCropH * imgH).clamp(10, imgH - srcY);

      canvas.save();
      if (_rotationQuarterTurns != 0) {
        canvas.translate(outputWidth / 2, outputHeight / 2);
        canvas.rotate(_rotationQuarterTurns * (3.141592653589793 / 2));
        canvas.translate(-outputWidth / 2, -outputHeight / 2);
      }

      final paint = Paint()..filterQuality = FilterQuality.high;
      final srcRect = Rect.fromLTWH(srcX, srcY, srcW, srcH);
      final dstRect = Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble());

      canvas.drawImageRect(_decodedImage!, srcRect, dstRect, paint);
      canvas.restore();

      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(outputWidth, outputHeight);
      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null && mounted) {
        final resultBytes = byteData.buffer.asUint8List();
        Navigator.pop(context, resultBytes);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 700;

    return Dialog(
      backgroundColor: const Color(0xFF111111),
      insetPadding: isMobile ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 0 : 20),
        side: const BorderSide(color: Colors.white24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 0 : 20),
        child: SizedBox(
          width: isMobile ? screenSize.width : 980,
          height: isMobile ? screenSize.height : 780,
          child: Column(
            children: [
              // Header Title & Control Bar
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 24,
                  vertical: isMobile ? 8 : 16,
                ),
                color: const Color(0xFF000000),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                tooltip: 'Cancel',
                                onPressed: () => Navigator.pop(context, null),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.fit_screen, color: Colors.white),
                                    tooltip: 'Fit to Frame',
                                    onPressed: _fitImageToVisibleArea,
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _isLoading ? null : _processAndApplyCrop,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                    child: Text(
                                      _isLoading ? '...' : 'APPLY',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getRatioLabel(),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Drag or zoom the image inside the fixed frame.',
                                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white60),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            tooltip: 'Cancel',
                            onPressed: () => Navigator.pop(context, null),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getRatioLabel(),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Drag or zoom the image inside the fixed frame. Visible area is locked to exact proportions.',
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white60),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // FIT TO VISIBLE AREA Quick Button
                          ElevatedButton.icon(
                            onPressed: _fitImageToVisibleArea,
                            icon: const Icon(Icons.fit_screen, size: 16),
                            label: const Text('FIT TO VISIBLE FRAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF222222),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Apply Button
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _processAndApplyCrop,
                            icon: const Icon(Icons.check, size: 18),
                            label: Text(_isLoading ? 'PROCESSING...' : 'APPLY & USE'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                          ),
                        ],
                      ),
              ),

              // Interactive Image Adjusting Workspace (Fixed Locked Crop Window)
              Expanded(
                child: _isLoading || _decodedImage == null
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final size = Size(constraints.maxWidth, constraints.maxHeight);
                          _initCropRectIfNeeded(size);

                          final double imgW = _decodedImage!.width.toDouble() * _imageScale;
                          final double imgH = _decodedImage!.height.toDouble() * _imageScale;
                          final Offset center = Offset(size.width / 2, size.height / 2);
                          final Offset imgPosition = center + _imagePanOffset - Offset(imgW / 2, imgH / 2);

                          return Container(
                            color: const Color(0xFF0A0A0A),
                            child: Stack(
                              children: [
                                // Layer 1: Pan & Drag Background Image
                                Positioned(
                                  left: imgPosition.dx,
                                  top: imgPosition.dy,
                                  width: imgW,
                                  height: imgH,
                                  child: GestureDetector(
                                    onPanUpdate: (details) {
                                      setState(() {
                                        _imagePanOffset += details.delta;
                                      });
                                    },
                                    child: RotatedBox(
                                      quarterTurns: _rotationQuarterTurns,
                                      child: RawImage(
                                        image: _decodedImage,
                                        width: imgW,
                                        height: imgH,
                                        fit: BoxFit.fill,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                ),

                                // Layer 2: Dark Overlay Mask Surrounding Fixed Crop Frame
                                if (_cropRect != null)
                                  IgnorePointer(
                                    child: CustomPaint(
                                      size: size,
                                      painter: MaskOverlayPainter(cropRect: _cropRect!),
                                    ),
                                  ),

                                // Layer 3: FIXED & LOCKED Visible Crop Window Frame (No Resizable Handles)
                                if (_cropRect != null)
                                  Positioned.fromRect(
                                    rect: _cropRect!,
                                    child: GestureDetector(
                                      onPanUpdate: (details) {
                                        setState(() {
                                          _imagePanOffset += details.delta;
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.white, width: 2.5),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.black45, blurRadius: 12),
                                          ],
                                        ),
                                        child: CustomPaint(
                                          painter: RuleOfThirdsGridPainter(),
                                        ),
                                      ),
                                    ),
                                  ),

                                // Layer 4: Frame Label Badge
                                if (_cropRect != null)
                                  Positioned(
                                    left: _cropRect!.left + 12,
                                    top: _cropRect!.top + 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.white54),
                                      ),
                                      child: Text(
                                        'VISIBLE AREA FRAME',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Bottom Control Bar (Image Size Zoom & Rotation)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 24,
                  vertical: isMobile ? 10 : 16,
                ),
                color: const Color(0xFF000000),
                child: isMobile
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Zoom slider row
                          Row(
                            children: [
                              const Icon(Icons.zoom_out, color: Colors.white54, size: 16),
                              Expanded(
                                child: Slider(
                                  value: _imageScale.clamp(0.2, 4.0),
                                  min: 0.2,
                                  max: 4.0,
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white24,
                                  onChanged: (val) {
                                    setState(() {
                                      _imageScale = val;
                                    });
                                  },
                                ),
                              ),
                              const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Control buttons row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              TextButton.icon(
                                onPressed: _fitImageToVisibleArea,
                                icon: const Icon(Icons.fit_screen, size: 16, color: Colors.white),
                                label: const Text('FIT', style: TextStyle(color: Colors.white, fontSize: 11)),
                              ),
                              OutlinedButton.icon(
                                onPressed: _rotateClockwise,
                                icon: const Icon(Icons.rotate_90_degrees_cw, color: Colors.white, size: 16),
                                label: const Text('ROTATE', style: TextStyle(color: Colors.white, fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white38),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _resetAdjustment,
                                icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                                label: const Text('RESET', style: TextStyle(color: Colors.white, fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white38),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          // Fit to Visible Frame Button
                          ElevatedButton.icon(
                            onPressed: _fitImageToVisibleArea,
                            icon: const Icon(Icons.fit_screen, size: 16, color: Colors.black),
                            label: const Text(
                              'FIT TO VISIBLE AREA',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Rotation Action
                          OutlinedButton.icon(
                            onPressed: _rotateClockwise,
                            icon: const Icon(Icons.rotate_90_degrees_cw, color: Colors.white, size: 18),
                            label: const Text('ROTATE 90°', style: TextStyle(color: Colors.white, fontSize: 11)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38)),
                          ),
                          const SizedBox(width: 12),

                          // Reset Action
                          OutlinedButton.icon(
                            onPressed: _resetAdjustment,
                            icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                            label: const Text('RESET', style: TextStyle(color: Colors.white, fontSize: 11)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38)),
                          ),

                          const SizedBox(width: 24),

                          // Image Scale Zoom Slider
                          Text('Adjust Image Size:', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.zoom_out, color: Colors.white54, size: 18),
                                Expanded(
                                  child: Slider(
                                    value: _imageScale.clamp(0.2, 4.0),
                                    min: 0.2,
                                    max: 4.0,
                                    activeColor: Colors.white,
                                    inactiveColor: Colors.white24,
                                    onChanged: (val) {
                                      setState(() {
                                        _imageScale = val;
                                      });
                                    },
                                  ),
                                ),
                                const Icon(Icons.zoom_in, color: Colors.white, size: 18),
                              ],
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
}

/// Semi-Transparent Mask Surrounding Crop Rectangle
class MaskOverlayPainter extends CustomPainter {
  final Rect cropRect;

  MaskOverlayPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.70);

    // Top region
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, cropRect.top), paint);
    // Bottom region
    canvas.drawRect(Rect.fromLTRB(0, cropRect.bottom, size.width, size.height), paint);
    // Left region
    canvas.drawRect(Rect.fromLTRB(0, cropRect.top, cropRect.left, cropRect.bottom), paint);
    // Right region
    canvas.drawRect(Rect.fromLTRB(cropRect.right, cropRect.top, size.width, cropRect.bottom), paint);
  }

  @override
  bool shouldRepaint(covariant MaskOverlayPainter oldDelegate) => oldDelegate.cropRect != cropRect;
}

/// Grid Lines Painter for Crop Box
class RuleOfThirdsGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    // Vertical grid lines
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);

    // Horizontal grid lines
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
