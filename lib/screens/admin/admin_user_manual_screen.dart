import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUserManualScreen extends StatelessWidget {
  const AdminUserManualScreen({super.key});

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard! Paste into Hero Banner or Promo Popup Link URL.'),
        backgroundColor: Colors.black,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        title: Text(
          'ADMIN PANEL USER MANUAL & QUICK LINKS',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/admin/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 32, horizontal: isDesktop ? 48 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.menu_book_outlined, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'HASH ZONE ADMIN USER MANUAL',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: isDesktop ? 28 : 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Complete operational guide for catalog management, Cloudinary image cropping, promo popups, hero banners, and quick route links.',
                    style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // SECTION 1: QUICK LINK DIRECTORY (ONE-CLICK COPY)
            _sectionHeader('1. QUICK LINK DIRECTORY (FOR HERO BANNERS & POPUPS)', Icons.link),
            const SizedBox(height: 12),
            Text(
              'Copy these internal routes with 1-click and paste into the "Target URL / Route" field when creating Hero Banners or Promo Popup Advertisements:',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF555555)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2.0),
              ),
              child: Column(
                children: [
                  _quickLinkRow(
                    context,
                    label: 'Entire Products Catalog',
                    route: '/products',
                    description: 'Directs customers to the full catalog grid page.',
                  ),
                  const Divider(height: 24),
                  _quickLinkRow(
                    context,
                    label: 'Special Offers Section',
                    route: '/products?offers=true',
                    description: 'Directs customers to discounted offer items only.',
                  ),
                  const Divider(height: 24),
                  _quickLinkRow(
                    context,
                    label: 'About Us Page (SMT Profile)',
                    route: '/about',
                    description: 'Directs customers to Sree Meenakshi Textile company details.',
                  ),
                  const Divider(height: 24),
                  _quickLinkRow(
                    context,
                    label: 'Contact Us & Store Location',
                    route: '/contact',
                    description: 'Directs customers to phone numbers, WhatsApp, and Google Maps.',
                  ),
                  const Divider(height: 24),
                  _quickLinkRow(
                    context,
                    label: 'Direct WhatsApp Order Chat',
                    route: 'https://wa.me/919876543210',
                    description: 'Launches WhatsApp chat directly with your store number.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // SECTION 2: MANAGING PRODUCTS & PRICES
            _sectionHeader('2. MANAGING PRODUCTS & CUSTOM PRICES', Icons.inventory_2_outlined),
            const SizedBox(height: 16),
            _guideCard(
              title: 'Creating & Editing Products',
              bulletPoints: [
                'Go to Admin Dashboard -> Products Management -> "+ ADD NEW PRODUCT".',
                'Upload 1 to 5 high-resolution product photos. Use the 3:4 aspect ratio cropper to frame your items edge-to-edge.',
                'Select Segment, Category, and Subcategory.',
                'Price is OPTIONAL: Type standard numeric price (e.g. 999), custom text (e.g. "₹1,200 / metre" or "On Request"), or leave completely BLANK.',
                'If price is left empty, NO price text will be shown to customers.',
              ],
            ),
            const SizedBox(height: 16),
            _guideCard(
              title: 'Featured & Special Offer Discount System',
              bulletPoints: [
                'FEATURED Switch: Displays the item in the homepage "Featured Collection" carousel.',
                'OFFER Switch: Flags the item with a red "OFFER" badge. Opens a "Special Offer Discount Price (₹)" field.',
                'On customer product cards and detail screens, the Special Offer price (e.g. ₹999) displays in red next to the original price (e.g. ₹1,499) rendered with a strikethrough line.',
              ],
            ),

            const SizedBox(height: 40),

            // SECTION 3: IMAGE DIMENSIONS & ASPECT RATIOS
            _sectionHeader('3. IMAGE DIMENSIONS & RECOMMENDED ASPECT RATIOS', Icons.aspect_ratio),
            const SizedBox(height: 16),
            _guideCard(
              title: 'Media Specifications & Aspect Ratios (No File Size Restrictions)',
              bulletPoints: [
                '🖼️ Hero Slideshow Banners: Ratio 21:9 Ultra-Wide Screen | Recommended: 2100 x 900 px.',
                '⭐ Dedicated Product Cover Image: Ratio 3:4 Portrait | Recommended: 900 x 1200 px.',
                '📷 Product Gallery Images: Ratio 4:3 Landscape | Recommended: 1200 x 900 px.',
                '📂 Segment & Category Cover Images: Ratio 1:1 Square | Recommended: 800 x 800 px.',
                '📢 Entrance Promo & Festive Popup Banners: Ratio 1:1 Square | Recommended: 800 x 800 px.',
                '🔓 Freedom of Uploads: File size restrictions and forced auto-compression loops are completely disabled. High-resolution images upload directly with full original clarity.',
              ],
            ),

            const SizedBox(height: 40),

            // SECTION 4: HERO BANNERS MANAGEMENT
            _sectionHeader('4. HERO BANNERS SLIDESHOW MANAGEMENT', Icons.view_carousel_outlined),
            const SizedBox(height: 16),
            _guideCard(
              title: 'Managing Homepage Hero Banners',
              bulletPoints: [
                'Go to Admin Dashboard -> Hero Banners Management.',
                'Upload & crop 21:9 Ultra-Wide Screen banner images directly to Cloudinary.',
                'Enter Main Title (e.g. "AUTUMN COLLECTION"), Subtitle, Button Label, and Target Route (e.g. /products).',
                'Editing Banners: Click the "EDIT" icon next to any active banner to update text, link URL, or change the banner image.',
                'Auto-Slideshow: Banners automatically rotate every 4 seconds on the homepage with manual arrow controls and dot indicators.',
              ],
            ),

            const SizedBox(height: 40),

            // SECTION 5: PROMO POPUP ADVERTISEMENT
            _sectionHeader('5. CUSTOMER ENTRANCE PROMO POPUP ADVERTISEMENT', Icons.campaign_outlined),
            const SizedBox(height: 16),
            _guideCard(
              title: 'Setting Up Promo Popup & Festival Greeting Banners',
              bulletPoints: [
                'Go to Admin Dashboard -> Business & Contact Settings -> "1. PROMO POPUP ADVERTISEMENT".',
                'Toggle "Enable Customer Entrance Popup Banner" ON or OFF.',
                'Festive Greetings & Seasonal Sales: Perfect for welcoming customers with festival greeting posters (e.g., Diwali, New Year, Pongal, Eid, Christmas) or promotional sale announcements when they land on your store.',
                'Upload & crop your promo or festival poster image directly to Cloudinary.',
                'Action Target Link URL: Enter a target route (e.g. /products?offers=true or WhatsApp link). Leave empty if it is a pure festival greeting poster with no button.',
                'Action Button Text: Customize the button label (e.g. "EXPLORE FESTIVE SALE" or "INQUIRE NOW"). A white right-side arrow is automatically added at the end.',
                'Session Behavior: The promo popup displays ONCE immediately when a customer lands on the home page. It will NOT pop up when switching tabs or returning to home during that session.',
              ],
            ),

            const SizedBox(height: 40),

            // SECTION 6: SEGMENTS, CATEGORIES & SIZE SYSTEM
            _sectionHeader('6. SEGMENTS, CATEGORIES & SIZE CONTROL', Icons.category_outlined),
            const SizedBox(height: 16),
            _guideCard(
              title: 'Segment Setup & Size Applicability',
              bulletPoints: [
                'Go to Admin Dashboard -> Segments & Categories.',
                'Segment Size Toggle: When creating/editing a segment, toggle "Sizes applicable for this segment" ON or OFF.',
                'For segments like Fabrics or Bags (where sizes are OFF), size chips in the product editor automatically GREY OUT and disable.',
                'For apparel segments like Men or Women (where sizes are ON), size chips (S, M, L, XL, XXL, 3XL) are active.',
              ],
            ),

            const SizedBox(height: 40),

            // SECTION 7: BUSINESS CONTACT & FOOTER SOCIAL MEDIA
            _sectionHeader('7. BUSINESS CONTACT & FOOTER SOCIAL MEDIA LINKS', Icons.settings_phone_outlined),
            const SizedBox(height: 16),
            _guideCard(
              title: 'Configuring Contact Channels & Footer Logos',
              bulletPoints: [
                'Go to Admin Dashboard -> Business & Contact Settings.',
                'Update WhatsApp Business Number, Call Telephone, Store Address, Email, and Google Maps URL.',
                'Social Media Links: Enter URLs for Instagram, Facebook, Twitter/X, YouTube, and WhatsApp.',
                'Footer Design: Displays circular white ring outline social buttons. If a link is not configured, clicking its icon shows a clean "Coming Soon!" notification.',
              ],
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.black, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickLinkRow(
    BuildContext context, {
    required String label,
    required String route,
    required String description,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 750;

    final labelCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF666666)),
        ),
      ],
    );

    final routeBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black26),
      ),
      child: Text(
        route,
        style: GoogleFonts.firaCode(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
        overflow: TextOverflow.ellipsis,
      ),
    );

    final copyBtn = ElevatedButton.icon(
      onPressed: () => _copyToClipboard(context, route, label),
      icon: const Icon(Icons.copy, size: 14),
      label: const Text('COPY LINK', style: TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          labelCol,
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: routeBadge),
              const SizedBox(width: 10),
              copyBtn,
            ],
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: labelCol,
          ),
          const SizedBox(width: 12),
          routeBadge,
          const SizedBox(width: 12),
          copyBtn,
        ],
      );
    }
  }

  Widget _guideCard({
    required String title,
    required List<String> bulletPoints,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          ...bulletPoints.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Expanded(
                      child: Text(
                        point,
                        style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: const Color(0xFF333333)),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
