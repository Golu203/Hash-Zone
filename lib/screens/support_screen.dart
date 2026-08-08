import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/navbar.dart';
import '../widgets/footer.dart';
import '../widgets/payment_help_centre.dart';
import '../widgets/smart_back_button.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showUtrHelpModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: const SizedBox(
          width: 700,
          child: SingleChildScrollView(child: PaymentHelpCentre()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HZNavBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              color: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HZSmartBackButton(fallbackRoute: '/', color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    'HELP & SUPPORT CENTRE',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: isDesktop ? 36 : 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Customer Support, FAQs, Shipping Guidelines & Refund Policy',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Content Body
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 20, vertical: 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 1. CONTACT CARDS ──────────────────────────────────
                      _buildContactCards(isDesktop),
                      const SizedBox(height: 48),

                      // ── 2. FREQUENTLY ASKED QUESTIONS (FAQS) ──────────────
                      Text('FREQUENTLY ASKED QUESTIONS', style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      const SizedBox(height: 16),
                      _buildFaqsAccordion(),
                      const SizedBox(height: 48),

                      // ── 3. REFUND POLICY ──────────────────────────────────
                      Text('REFUND POLICY', style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      const SizedBox(height: 16),
                      _buildRefundPolicy(),
                      const SizedBox(height: 48),

                      // ── 4. SHIPPING POLICY ────────────────────────────────
                      Text('SHIPPING POLICY', style: GoogleFonts.cormorantGaramond(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      const SizedBox(height: 16),
                      _buildShippingPolicy(),
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

  // ── CONTACT CARDS ─────────────────────────────────────────────────────────
  Widget _buildContactCards(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DIRECT SUPPORT CHANNELS', style: GoogleFonts.cormorantGaramond(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 3 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isDesktop ? 2.2 : 2.5,
            children: [
              _channelCard(
                icon: Icons.phone_in_talk,
                title: 'Customer Phone Support',
                value: '+91 98765 43210\nMon-Sat: 10:00 AM - 7:00 PM',
                btnText: 'CALL NOW',
                onTap: () => _launch('tel:+919876543210'),
              ),
              _channelCard(
                icon: Icons.chat,
                title: 'WhatsApp Business',
                value: '+91 98765 43210\nInstant Order Support',
                btnText: 'CHAT ON WHATSAPP',
                onTap: () => _launch('https://wa.me/919876543210'),
              ),
              _channelCard(
                icon: Icons.email_outlined,
                title: 'Email Support',
                value: 'support@hashzone.co.in\nResponds within 24 hours',
                btnText: 'SEND EMAIL',
                onTap: () => _launch('mailto:support@hashzone.co.in'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _channelCard({
    required IconData icon,
    required String title,
    required String value,
    required String btnText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEEEEEE))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.black, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54, height: 1.4)),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: onTap,
            child: Text(btnText, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── FAQS ACCORDION ────────────────────────────────────────────────────────
  Widget _buildFaqsAccordion() {
    final faqs = [
      {
        'q': 'How do I place an order?',
        'a': 'Simply browse our catalog, select your preferred clothing item and size, click "Add to Cart" or "Buy Now", and proceed to checkout. You can select your delivery address and pay via Bank Transfer.',
      },
      {
        'q': 'Where can I find my Transaction ID (UTR)?',
        'a': 'Your 12-digit UTR / Transaction ID is generated by your banking application (NetBanking / IMPS / NEFT / RTGS) right after completing the payment. Click below to view visual app guides.',
        'hasUtrButton': true,
      },
      {
        'q': 'How do I track my order?',
        'a': 'Go to "My Account" -> "My Orders". Each order features a 3-stage progress bar (Order Received -> Order Confirmed -> Dispatched). Once shipped, courier partner details and AWB tracking links will appear on your order card.',
      },
      {
        'q': 'Can I modify my order?',
        'a': 'Customers cannot modify an order directly after placing it. However, please contact our support team immediately and we will do our best to accommodate your request depending on the current order processing stage.',
      },
      {
        'q': 'Can I cancel my order?',
        'a': 'Orders can be cancelled before dispatch by contacting support via WhatsApp or Phone. Once an order is dispatched, cancellation is subject to courier recall feasibility.',
      },
      {
        'q': 'How do I download my invoice & receipt?',
        'a': 'System-generated receipts and tax invoices can be viewed and downloaded directly from "My Account" -> "My Orders" under the Documents section.',
      },
      {
        'q': 'How long does payment verification take?',
        'a': 'Our automated browser OCR system validates payment screenshots instantly. Manual verification, if needed, takes between 15 minutes to 2 hours during business hours.',
      },
      {
        'q': 'Why is shipping charged separately?',
        'a': 'Because HashZone serves both retail and wholesale buyers across India, shipping charges vary based on order weight, package volume, delivery PIN code, and courier choice. Shipping cost is communicated via WhatsApp prior to dispatch.',
      },
    ];

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEEEEE))),
      child: Column(
        children: faqs.map((faq) {
          return ExpansionTile(
            title: Text(faq['q'] as String, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(faq['a'] as String, style: GoogleFonts.inter(fontSize: 13, color: Colors.black54, height: 1.6)),
                    if (faq['hasUtrButton'] == true) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _showUtrHelpModal,
                        icon: const Icon(Icons.help_outline, size: 16),
                        label: Text('Open UTR Visual Help Guide', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.black, side: const BorderSide(color: Colors.black)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── REFUND POLICY ─────────────────────────────────────────────────────────
  Widget _buildRefundPolicy() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEEEEE))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _policyBullet('Eligible cancelled or rejected orders are refunded promptly.'),
          _policyBullet('Refund processing begins only after administrative approval.'),
          _policyBullet('Refunds are processed within 7 Working Days to the original source account.'),
          _policyBullet('Bank processing times may vary depending on financial institution.'),
          _policyBullet('Shipping charges may be non-refundable where package dispatch has already occurred.'),
          _policyBullet('Customers may contact support at support@hashzone.co.in or +91 98765 43210 for refund assistance.'),
        ],
      ),
    );
  }

  // ── SHIPPING POLICY ───────────────────────────────────────────────────────
  Widget _buildShippingPolicy() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEEEEE))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shipping charges are calculated separately for each order to ensure the most cost-effective courier rate based on:',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.black87, height: 1.6),
          ),
          const SizedBox(height: 12),
          _policyBullet('Delivery Location (State / City / Remote Area PIN Code)'),
          _policyBullet('Package Weight & Parcel Volume'),
          _policyBullet('Order Quantity (Retail vs Bulk Wholesale)'),
          _policyBullet('Courier Partner Selection (Express vs Economy)'),
          const SizedBox(height: 12),
          Text(
            'The exact shipping amount is communicated via WhatsApp prior to dispatch.',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _policyBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87, height: 1.5))),
        ],
      ),
    );
  }
}
