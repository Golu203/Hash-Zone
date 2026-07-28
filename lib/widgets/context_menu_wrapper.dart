// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class HZContextMenuWrapper extends StatelessWidget {
  final Widget child;
  final String? imageUrl;
  final String? productTitle;

  const HZContextMenuWrapper({
    super.key,
    required this.child,
    this.imageUrl,
    this.productTitle,
  });

  Future<void> _downloadImage(BuildContext context, String url, String filename) async {
    if (kIsWeb) {
      try {
        final request = await html.HttpRequest.request(url, responseType: 'blob');
        final blob = request.response as html.Blob;
        final objectUrl = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: objectUrl)
          ..setAttribute('download', filename)
          ..style.display = 'none';
        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(objectUrl);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image downloaded to device successfully!'),
              backgroundColor: Colors.black,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        final anchor = html.AnchorElement(href: url)
          ..target = '_blank'
          ..setAttribute('download', filename);
        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
      }
    } else {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _showCustomContextMenu(BuildContext context, Offset position) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<dynamic>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      color: Colors.black,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.white24, width: 1.5),
      ),
      items: <PopupMenuEntry<dynamic>>[
        if (imageUrl != null && imageUrl!.isNotEmpty) ...<PopupMenuEntry<dynamic>>[
          PopupMenuItem<dynamic>(
            onTap: () {
              final name = '${productTitle?.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_') ?? 'hashzone_image'}.jpg';
              _downloadImage(context, imageUrl!, name);
            },
            child: Row(
              children: [
                const Icon(Icons.download_rounded, size: 20, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'DOWNLOAD IMAGE TO DEVICE',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          PopupMenuItem<dynamic>(
            onTap: () {
              Clipboard.setData(ClipboardData(text: imageUrl!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image link copied to clipboard!'),
                  backgroundColor: Colors.black,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Row(
              children: [
                const Icon(Icons.link_rounded, size: 20, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'COPY IMAGE LINK',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
        ],
        PopupMenuItem<dynamic>(
          enabled: false,
          child: Text(
            'HASH ZONE • DIGITAL CATALOG',
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white54),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) {
        _showCustomContextMenu(context, details.globalPosition);
      },
      onLongPressStart: (details) {
        _showCustomContextMenu(context, details.globalPosition);
      },
      child: child,
    );
  }
}
