import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class HZPromoPopupDialog extends StatelessWidget {
  final String imageUrl;
  final String linkUrl;
  final String actionText;

  const HZPromoPopupDialog({
    super.key,
    required this.imageUrl,
    required this.linkUrl,
    this.actionText = 'EXPLORE SPECIAL OFFER',
  });

  static void showIfActive(
    BuildContext context, {
    required bool isActive,
    required String imageUrl,
    required String linkUrl,
    String actionText = 'EXPLORE SPECIAL OFFER',
  }) {
    if (!isActive || imageUrl.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.75),
        builder: (context) => HZPromoPopupDialog(
          imageUrl: imageUrl,
          linkUrl: linkUrl,
          actionText: actionText,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final hasActionLink = linkUrl.trim().isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? screenSize.width * 0.9 : 540,
            maxHeight: screenSize.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Image & Optional Action Link Section
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          if (hasActionLink) {
                            context.go(linkUrl);
                          }
                        },
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 300,
                              color: const Color(0xFFF4F4F5),
                              child: const Center(child: CircularProgressIndicator(color: Colors.black)),
                            );
                          },
                        ),
                      ),
                    ),

                    // Display Action Bar ONLY if linkUrl is provided
                    if (hasActionLink)
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          context.go(linkUrl);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                          width: double.infinity,
                          color: Colors.black,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                actionText.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Top-Right Close Button
              Positioned(
                top: -14,
                right: -14,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.0),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 8),
                      ],
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
