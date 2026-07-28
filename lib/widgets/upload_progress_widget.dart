import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../repositories/image_upload_repository.dart';

class UploadProgressWidget extends StatelessWidget {
  final ImageUploadTask task;
  final VoidCallback onSetCover;
  final VoidCallback onRemove;
  final VoidCallback onRetry;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const UploadProgressWidget({
    super.key,
    required this.task,
    required this.onSetCover,
    required this.onRemove,
    required this.onRetry,
    this.onMoveUp,
    this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (task.progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: task.isCover ? const Color(0xFF000000) : const Color(0xFFE5E5E5),
          width: task.isCover ? 2.0 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Image Preview Thumbnail
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFF4F4F5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: task.bytes.isNotEmpty
                  ? Image.memory(task.bytes, fit: BoxFit.cover)
                  : task.cloudinaryImage != null
                      ? Image.network(task.cloudinaryImage!.url, fit: BoxFit.cover)
                      : const Icon(Icons.image, color: Color(0xFF888888)),
            ),
          ),

          const SizedBox(width: 16),

          // Main Info & Progress Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'IMAGE #${task.displayOrder}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: const Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (task.isCover)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF000000),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'COVER IMAGE',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 6),

                // Status Indicator / Progress Bar
                if (task.status == UploadStatus.uploading) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Uploading to Cloudinary...',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF333333)),
                      ),
                      Text(
                        '$percentage%',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF000000)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: task.progress,
                    backgroundColor: const Color(0xFFE5E5E5),
                    color: const Color(0xFF000000),
                  ),
                ] else if (task.status == UploadStatus.success) ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          task.cloudinaryImage != null
                              ? '${task.cloudinaryImage!.width}x${task.cloudinaryImage!.height} • ${task.cloudinaryImage!.format.toUpperCase()}'
                              : 'Uploaded successfully',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF333333)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ] else if (task.status == UploadStatus.error) ...[
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          task.errorMessage ?? 'Upload failed',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.redAccent),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'Ready to upload',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF888888)),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Action Buttons
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Retry Button if error
                  if (task.status == UploadStatus.error)
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.orange, size: 20),
                      tooltip: 'Retry Upload',
                      onPressed: onRetry,
                    ),

                  // Set as Cover Button
                  if (!task.isCover)
                    IconButton(
                      icon: const Icon(Icons.star_border, color: Color(0xFF555555), size: 20),
                      tooltip: 'Set as Cover Image',
                      onPressed: onSetCover,
                    ),

                  // Move Up / Down
                  if (onMoveUp != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, color: Color(0xFF555555), size: 18),
                      tooltip: 'Move Up',
                      onPressed: onMoveUp,
                    ),
                  if (onMoveDown != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, color: Color(0xFF555555), size: 18),
                      tooltip: 'Move Down',
                      onPressed: onMoveDown,
                    ),

                  // Remove Image
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    tooltip: 'Remove Image',
                    onPressed: onRemove,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
