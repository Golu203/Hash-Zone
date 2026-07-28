import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/business_provider.dart';

class HZFooter extends StatelessWidget {
  const HZFooter({super.key});

  Future<void> _launchSocial(BuildContext context, String? url, String platformName) async {
    if (url == null || url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$platformName Coming Soon!',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.black,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$platformName Coming Soon!', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.black,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = Provider.of<BusinessProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Container(
      color: const Color(0xFF000000),
      padding: EdgeInsets.symmetric(
        vertical: 50,
        horizontal: isDesktop ? 32 : 20,
      ),
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _brandColumn(context, business)),
                      const SizedBox(width: 40),
                      Expanded(flex: 2, child: _navColumn(context)),
                      const SizedBox(width: 40),
                      Expanded(flex: 3, child: _contactColumn(context, business)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _brandColumn(context, business),
                      const SizedBox(height: 40),
                      _navColumn(context),
                      const SizedBox(height: 40),
                      _contactColumn(context, business),
                    ],
                  ),
          ),

          const SizedBox(height: 50),
          const Divider(color: Color(0xFF222222), height: 1),
          const SizedBox(height: 30),

          // Bottom Copyright & Legal
          Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: isDesktop
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '© ${DateTime.now().year} SHREE MEENAKSHI TEXTILES. ALL RIGHTS RESERVED.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          letterSpacing: 1.0,
                          color: const Color(0xFF888888),
                        ),
                      ),
                      Text(
                        'DIGITAL CLOTHING STORE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          letterSpacing: 1.0,
                          color: const Color(0xFF888888),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '© ${DateTime.now().year} SHREE MEENAKSHI TEXTILES. ALL RIGHTS RESERVED.',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          letterSpacing: 0.8,
                          color: const Color(0xFF888888),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'DIGITAL CLOTHING STORE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          letterSpacing: 0.8,
                          color: const Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _brandColumn(BuildContext context, BusinessProvider business) {
    final social = business.settings.socialLinks;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
                image: const DecorationImage(
                  image: AssetImage('assets/images/logo.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'SHREE MEENAKSHI TEXTILES',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: isDesktop ? 24 : 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: isDesktop ? 2.5 : 1.5,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Explore our digital store for high-quality menswear, womenswear, and modern apparel. Select your favorite items and inquire directly on WhatsApp.',
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.6,
            color: const Color(0xFFCCCCCC),
          ),
        ),
        const SizedBox(height: 24),

        // Circular Ring White Outline Social Media Buttons (Matching attached photo theme)
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _circularRingButton(context, 'facebook', social['facebook'], 'Facebook'),
            _circularRingButton(context, 'twitter', social['twitter'], 'Twitter / X'),
            _circularRingButton(context, 'youtube', social['youtube'], 'YouTube'),
            _circularRingButton(context, 'instagram', social['instagram'], 'Instagram'),
            _circularRingButton(context, 'whatsapp', social['whatsapp'], 'WhatsApp'),
            _circularRingButton(context, 'maps', business.settings.googleMapsUrl, 'Google Maps'),
          ],
        ),
      ],
    );
  }

  Widget _circularRingButton(BuildContext context, String brand, String? url, String label) {
    final isConfigured = url != null && url.trim().isNotEmpty;

    return InkWell(
      onTap: () => _launchSocial(context, url, label),
      borderRadius: BorderRadius.circular(24),
      child: Tooltip(
        message: isConfigured ? label : '$label (Coming Soon)',
        child: Opacity(
          opacity: isConfigured ? 1.0 : 0.40,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(color: Colors.white, width: 2.0),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Center(
              child: _brandGlyph(brand),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brandGlyph(String brand) {
    switch (brand) {
      case 'facebook':
        return Text(
          'f',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.1,
          ),
        );

      case 'twitter':
        return Text(
          '𝕏',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );

      case 'youtube':
        return Container(
          width: 18,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Center(
            child: Icon(Icons.play_arrow, color: Colors.black, size: 12),
          ),
        );

      case 'instagram':
        return const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20);

      case 'whatsapp':
        return const Icon(Icons.chat_outlined, color: Colors.white, size: 19);

      case 'maps':
        return const Icon(Icons.map_outlined, color: Colors.white, size: 19);

      default:
        return const Icon(Icons.link, color: Colors.white, size: 18);
    }
  }

  Widget _navColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NAVIGATION',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _footerLink(context, 'Home Store', '/'),
        _footerLink(context, 'All Products', '/products'),
        _footerLink(context, 'Special Offers', '/products?offers=true'),
        _footerLink(context, 'About Us', '/about'),
        _footerLink(context, 'Contact Us', '/contact'),
      ],
    );
  }

  Widget _footerLink(BuildContext context, String text, String path) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.go(path),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFFCCCCCC),
          ),
        ),
      ),
    );
  }

  Widget _contactColumn(BuildContext context, BusinessProvider business) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTACT & INQUIRIES',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _contactRow(Icons.location_on_outlined, business.settings.storeAddress),
        const SizedBox(height: 10),
        _contactRow(Icons.phone_outlined, business.settings.contactNumbers.isNotEmpty ? business.settings.contactNumbers.first : ''),
        const SizedBox(height: 10),
        _contactRow(Icons.chat_outlined, 'WhatsApp: ${business.settings.whatsAppNumber}'),
        const SizedBox(height: 10),
        _contactRow(Icons.email_outlined, business.settings.email),
      ],
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFCCCCCC)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFFCCCCCC),
            ),
          ),
        ),
      ],
    );
  }
}
