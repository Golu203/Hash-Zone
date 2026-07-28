import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/navbar.dart';
import '../widgets/footer.dart';
import '../utils/seo_helper.dart';

class ErrorScreen extends StatelessWidget {
  final String? message;

  const ErrorScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SeoHelper.updateMetadata(
        title: 'Page Not Found | HASH ZONE Tiruppur',
        description: 'The requested page could not be found. Return to HASH ZONE, premium wholesale clothing manufacturers in Tiruppur, India.',
        keywords: '404 page not found, HASH ZONE',
        path: '/404',
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HZNavBar(),
      endDrawer: !isDesktop ? const HZMobileDrawer() : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '404',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: isDesktop ? 120 : 80,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: const Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'PAGE NOT FOUND',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: isDesktop ? 18 : 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3.0,
                          color: const Color(0xFF555555),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        message ??
                            'The catalog path you are looking for has been moved or does not exist. Browse our wholesale apparel collections below.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.6,
                          color: const Color(0xFF777777),
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/products'),
                        icon: const Icon(Icons.grid_view, size: 16),
                        label: const Text('EXPLORE WHOLESALE CATALOG'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF111111),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: Text(
                          'RETURN TO HOME',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: const Color(0xFF111111),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const HZFooter(),
          ],
        ),
      ),
    );
  }
}
