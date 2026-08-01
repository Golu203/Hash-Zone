// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/navbar.dart';
import '../widgets/footer.dart';

class InstallScreen extends StatefulWidget {
  const InstallScreen({super.key});

  @override
  State<InstallScreen> createState() => _InstallScreenState();
}

class _InstallScreenState extends State<InstallScreen> {
  /// `null`  → checking / not yet determined
  /// `true`  → native prompt available (Android Chrome etc.)
  /// `false` → prompt not available (already installed, iOS Safari, unsupported)
  bool? _promptAvailable;
  bool _installed = false;

  @override
  void initState() {
    super.initState();
    _checkInstallPrompt();
  }

  void _checkInstallPrompt() {
    try {
      // The service‑worker / manifest must already be registered for this to fire.
      // We expose a JS helper in index.html that captures the beforeinstallprompt event.
      final available = js.context.callMethod('hzIsInstallPromptAvailable', []) as bool? ?? false;
      setState(() => _promptAvailable = available);
    } catch (_) {
      setState(() => _promptAvailable = false);
    }

    // Also check if already running in standalone (installed) mode.
    try {
      final standalone = js.context.callMethod('hzIsStandalone', []) as bool? ?? false;
      if (standalone) setState(() => _installed = true);
    } catch (_) {}
  }

  Future<void> _triggerInstall() async {
    try {
      final result = js.context.callMethod('hzTriggerInstall', []) as String?;
      if (result == 'accepted') {
        setState(() {
          _installed = true;
          _promptAvailable = false;
        });
      } else if (result == 'dismissed') {
        // User dismissed — keep button available to try again later
      }
    } catch (_) {
      setState(() => _promptAvailable = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HZNavBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 48,
                  vertical: isMobile ? 48 : 80,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App icon
                    Container(
                      width: isMobile ? 80 : 100,
                      height: isMobile ? 80 : 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.black,
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'icons/Icon-192.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Heading
                    Text(
                      'Install HashZone App',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: isMobile ? 30 : 38,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subheading
                    Text(
                      'Install HashZone on your device for a faster, smoother, app-like shopping experience.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 14 : 16,
                        height: 1.65,
                        color: const Color(0xFF555555),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Benefits
                    _buildBenefits(isMobile),
                    const SizedBox(height: 48),

                    // Install CTA area
                    _buildInstallSection(isMobile),
                  ],
                ),
              ),
            ),
            const HZFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefits(bool isMobile) {
    final items = [
      (Icons.bolt_outlined, 'Faster access'),
      (Icons.fullscreen_outlined, 'Full-screen experience'),
      (Icons.grid_view_outlined, 'Quick product browsing'),
      (Icons.chat_bubble_outline_rounded, 'Easy WhatsApp inquiries'),
      (Icons.touch_app_outlined, 'One-tap access from your device'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHY INSTALL',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: const Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.$1, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      item.$2,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInstallSection(bool isMobile) {
    if (_installed) {
      return _buildAlreadyInstalled(isMobile);
    }

    if (_promptAvailable == true) {
      return _buildNativePromptSection(isMobile);
    }

    // Prompt not available — show manual instructions
    return _buildManualInstructions(isMobile);
  }

  Widget _buildAlreadyInstalled(bool isMobile) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FFF4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 20),
              const SizedBox(width: 10),
              Text(
                'App Already Installed',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'You can access HashZone directly from your device\'s home screen.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF777777)),
        ),
      ],
    );
  }

  Widget _buildNativePromptSection(bool isMobile) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _triggerInstall,
            icon: const Icon(Icons.download_outlined, color: Colors.white, size: 20),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            label: Text(
              'Install App',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your browser will prompt you to install HashZone as an app.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF888888)),
        ),
      ],
    );
  }

  Widget _buildManualInstructions(bool isMobile) {
    final isIOS = _detectIOS();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isIOS ? 'INSTALL ON IPHONE / IPAD' : 'INSTALL INSTRUCTIONS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: const Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 16),
          if (isIOS) ...[
            _instructionStep('1', 'Tap the Share button', Icons.ios_share),
            _instructionStep('2', 'Scroll down and tap "Add to Home Screen"', Icons.add_box_outlined),
            _instructionStep('3', 'Tap "Add" to confirm', Icons.check_outlined),
          ] else ...[
            _instructionStep('1', 'Open HashZone in Chrome or Edge', Icons.open_in_browser),
            _instructionStep('2', 'Tap the menu (⋮) in the top-right corner', Icons.more_vert),
            _instructionStep('3', 'Select "Add to Home screen" or "Install app"', Icons.add_box_outlined),
            _instructionStep('4', 'Confirm the installation', Icons.check_outlined),
          ],
        ],
      ),
    );
  }

  Widget _instructionStep(String step, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _detectIOS() {
    try {
      final ua = js.context['navigator']['userAgent'] as String? ?? '';
      return ua.contains('iPhone') || ua.contains('iPad') || ua.contains('iPod');
    } catch (_) {
      return false;
    }
  }
}
