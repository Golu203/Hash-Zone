import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/navigation_memory_service.dart';

class HZSmartBackButton extends StatelessWidget {
  final String fallbackRoute;
  final String? label;
  final Color color;

  const HZSmartBackButton({
    super.key,
    this.fallbackRoute = '/',
    this.label = 'Back',
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => NavigationMemoryService().smartGoBack(context, fallbackRoute: fallbackRoute),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back, color: color, size: 20),
            if (label != null && label!.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
