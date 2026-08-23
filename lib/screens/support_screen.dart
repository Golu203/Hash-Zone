import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: const HZNavBar(),
      endDrawer: !isDesktop ? const HZMobileDrawer() : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              color: Colors.black,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : (isMobile ? 18 : 32),
                vertical: isMobile ? 32 : 44,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HZSmartBackButton(fallbackRoute: '/', color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    'HELP & SUPPORT CENTRE',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: isDesktop ? 36 : (isMobile ? 26 : 30),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Wholesale Guide, Verified Payment Help, Shipping Policies & FAQs',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 12.5 : 14,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Content Body
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : (isMobile ? 16 : 28),
                vertical: isMobile ? 24 : 40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1050),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 1. DIRECT CONTACT CHANNELS ─────────────────────────
                      _buildContactSection(isMobile),
                      SizedBox(height: isMobile ? 32 : 48),

                      // ── 2. LEGAL POLICIES & COMPLIANCE ACCESS ──────────────
                      Text(
                        'LEGAL & POLICY COMPLIANCE',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: isMobile ? 22 : 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review our statutory terms, customer privacy protection, logistics policies, and grievance framework.',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 12 : 13,
                          color: const Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLegalSection(),
                      SizedBox(height: isMobile ? 32 : 48),

                      // ── 3. FREQUENTLY ASKED QUESTIONS (FAQS) ───────────────
                      Text(
                        'FREQUENTLY ASKED QUESTIONS',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: isMobile ? 22 : 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Common questions regarding our wholesale bundle model, ordering, payment verification, and delivery.',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 12 : 13,
                          color: const Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildFaqFilters(isMobile),
                      const SizedBox(height: 16),
                      _buildFaqsAccordion(context, isMobile),
                      const SizedBox(height: 48),
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

  // ── CONTACT CHANNELS SECTION ──────────────────────────────────────────────
  Widget _buildContactSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.support_agent, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'DIRECT SUPPORT CHANNELS',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              if (width < 640) {
                // Mobile: 1 Column Stack
                return Column(
                  children: [
                    _channelCard(
                      icon: Icons.phone_in_talk,
                      title: 'Customer Phone Helpline',
                      value: '+91 98848 75578\nMon-Sat: 10:00 AM - 7:00 PM IST',
                      btnText: 'CALL +91 98848 75578',
                      onTap: () => _launch('tel:+919884875578'),
                    ),
                    const SizedBox(height: 12),
                    _channelCard(
                      icon: Icons.chat,
                      title: 'WhatsApp Direct Desk',
                      value: '+91 98848 75578\nInstant Order & Payment Inquiries',
                      btnText: 'CHAT ON WHATSAPP',
                      onTap: () => _launch('https://wa.me/919884875578'),
                    ),
                    const SizedBox(height: 12),
                    _channelCard(
                      icon: Icons.email_outlined,
                      title: 'Official Email Support',
                      value: 'support@hashzone.co.in\nDirect ticketing within 24 hours',
                      btnText: 'SEND EMAIL',
                      onTap: () => _launch('mailto:support@hashzone.co.in'),
                    ),
                  ],
                );
              } else {
                // Tablet / Desktop: Row of 3
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _channelCard(
                        icon: Icons.phone_in_talk,
                        title: 'Phone Support',
                        value: '+91 98848 75578\nMon-Sat: 10 AM - 7 PM IST',
                        btnText: 'CALL NOW',
                        onTap: () => _launch('tel:+919884875578'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _channelCard(
                        icon: Icons.chat,
                        title: 'WhatsApp Desk',
                        value: '+91 98848 75578\nInstant Wholesale Inquiries',
                        btnText: 'CHAT NOW',
                        onTap: () => _launch('https://wa.me/919884875578'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _channelCard(
                        icon: Icons.email_outlined,
                        title: 'Email Support',
                        value: 'support@hashzone.co.in\nResponses within 24h',
                        btnText: 'SEND EMAIL',
                        onTap: () => _launch('mailto:support@hashzone.co.in'),
                      ),
                    ),
                  ],
                );
              }
            },
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
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.black, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF555555), height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onTap,
              child: Text(
                btnText,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── LEGAL POLICIES SECTION ────────────────────────────────────────────────
  Widget _buildLegalSection() {
    final legalItems = [
      {
        'title': 'Terms & Conditions',
        'desc': 'Wholesale bundle model, order terms, payments, and commercial conditions.',
        'icon': Icons.description_outlined,
        'route': '/terms',
      },
      {
        'title': 'Privacy Policy',
        'desc': 'Data protection, address security, payment screenshot privacy, and DPDP compliance.',
        'icon': Icons.shield_outlined,
        'route': '/privacy',
      },
      {
        'title': 'Refund & Cancellation',
        'desc': 'Order cancellation stages, 7-working-day refund processing, and defective goods protocol.',
        'icon': Icons.currency_rupee_outlined,
        'route': '/refund-policy',
      },
      {
        'title': 'Shipping & Delivery',
        'desc': 'Tiruppur dispatch hub, freight calculation, transit timelines, and AWB tracking.',
        'icon': Icons.local_shipping_outlined,
        'route': '/shipping-policy',
      },
      {
        'title': 'Grievance Redressal',
        'desc': 'Statutory redressal officer, 48-hour acknowledgement, and resolution mechanism.',
        'icon': Icons.gavel_outlined,
        'route': '/grievance',
      },
      {
        'title': 'About HashZone',
        'desc': 'Sree Meenakshi Textiles journey, manufacturing heritage since 1998 in Tiruppur.',
        'icon': Icons.business_outlined,
        'route': '/about',
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount = width < 600 ? 1 : (width < 900 ? 2 : 3);
        final double childAspectRatio = width < 600
            ? 3.2
            : (width < 900 ? 2.3 : 2.0);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: legalItems.length,
          itemBuilder: (ctx, i) {
            final item = legalItems[i];
            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => context.push(item['route'] as String),
                borderRadius: BorderRadius.circular(12),
                hoverColor: const Color(0xFFF5F5F5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item['icon'] as IconData, size: 20, color: Colors.black),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item['title'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item['desc'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: const Color(0xFF666666),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 13, color: Color(0xFF999999)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── FAQ FILTERS & SEARCH BAR ──────────────────────────────────────────────
  Widget _buildFaqFilters(bool isMobile) {
    final categories = [
      'All',
      'Wholesale & Bundles',
      'Payments & UTR',
      'Shipping & Delivery',
      'Orders & Returns',
      'Policies & Legal',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
          style: GoogleFonts.inter(fontSize: 13.5, color: Colors.black),
          decoration: InputDecoration(
            hintText: 'Search FAQs (e.g. wholesale bundle, UTR verification, cancel, shipping)...',
            hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF888888)),
            prefixIcon: const Icon(Icons.search, color: Colors.black54, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = cat);
                  },
                  backgroundColor: Colors.white,
                  selectedColor: Colors.black,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? Colors.black : const Color(0xFFE0E0E0),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── FAQS ACCORDION ────────────────────────────────────────────────────────
  Widget _buildFaqsAccordion(BuildContext context, bool isMobile) {
    final allFaqs = [
      {
        'category': 'Wholesale & Bundles',
        'q': 'How do I create an account on HashZone?',
        'a': 'Click "Login / Register" in the top navigation bar. You can sign up using your email and password, or sign in instantly with one tap using Google. After initial sign-in, you complete our 3-step onboarding where you enter your business details, contact information, delivery address, and review & accept the Terms & Conditions and Privacy Policy.',
      },
      {
        'category': 'Wholesale & Bundles',
        'q': 'What information do I need to provide during registration?',
        'a': 'We collect only essential information required for order fulfillment and legal compliance: your Full Name, optional Company Name, Mobile Number, WhatsApp Number, and a complete 7-field postal Delivery Address (Door No, Road, Area, City, State, PIN Code, and Landmark).',
      },
      {
        'category': 'Wholesale & Bundles',
        'q': 'What is a HashZone wholesale bundle?',
        'a': 'HashZone operates on a manufacturer-direct wholesale model. Instead of single retail pieces, garments are sold in pre-packaged bundles containing a defined size assortment (e.g. S, M, L, XL), a set number of pieces per size, and a single fixed wholesale bundle price.',
      },
      {
        'category': 'Wholesale & Bundles',
        'q': 'Can I purchase individual pieces instead of a bundle?',
        'a': 'Because HashZone is a direct apparel manufacturer offering factory pricing, products are sold strictly in complete wholesale bundles as listed. Single-piece retail purchases are not available unless explicitly configured on a specific promotional listing.',
      },
      {
        'category': 'Payments & UTR',
        'q': 'How can I pay for my wholesale order?',
        'a': 'To avoid third-party payment gateway surcharge deductions and provide the best wholesale rates, we accept Direct Bank Transfer (NEFT / RTGS / IMPS / NetBanking) and Official Business UPI. Banking details are displayed during checkout.',
      },
      {
        'category': 'Payments & UTR',
        'q': 'How do I verify my bank transfer payment?',
        'a': 'After transferring funds to our official account, enter your 12-digit Unique Transaction Reference (UTR / Bank Transaction ID) and optionally upload the payment screenshot in the checkout screen. Our admin team cross-verifies the credit and confirms your order.',
        'hasUtrButton': true,
      },
      {
        'category': 'Payments & UTR',
        'q': 'How long does payment verification take?',
        'a': 'Our automated OCR visual assistance aids immediate review, and our administrative verification team confirms bank credits during business hours (Monday to Saturday, 10:00 AM to 7:00 PM IST), typically within 15 minutes to 2 hours.',
      },
      {
        'category': 'Orders & Returns',
        'q': 'Can I cancel my order?',
        'a': 'Orders can be cancelled before dispatch by contacting our support desk. Once an order is packed, dispatched, and assigned an AWB tracking number, cancellation is subject to courier feasibility. Please review our Refund & Cancellation Policy for details.',
        'linkText': 'View Refund & Cancellation Policy',
        'linkRoute': '/refund-policy',
      },
      {
        'category': 'Orders & Returns',
        'q': 'Can I modify my order after placement?',
        'a': 'Orders cannot normally be modified directly after placement. Please contact our support team immediately and we will do our best to assist, subject to current order processing stage and fabric stock availability.',
      },
      {
        'category': 'Shipping & Delivery',
        'q': 'How long does delivery take & how are shipping charges calculated?',
        'a': 'Consignments are dispatched from our Tiruppur facility within 1–3 business days following payment confirmation. Transit typically takes 3–7 business days across India. Shipping charges are calculated based on parcel weight, volume, and destination PIN code.',
        'linkText': 'View Shipping & Delivery Policy',
        'linkRoute': '/shipping-policy',
      },
      {
        'category': 'Orders & Returns',
        'q': 'Where can I find my invoice and receipt?',
        'a': 'You can access all receipts and official GST tax invoices by logging into your account and visiting "My Account -> My Orders". Each order card provides direct PDF download links under the Documents section.',
      },
      {
        'category': 'Policies & Legal',
        'q': 'How can I raise a formal complaint or grievance?',
        'a': 'You can submit a formal grievance to our appointed Grievance Officer via email at grievance@hashzone.co.in. We acknowledge all grievances within 48 hours and resolve them within 15 to 30 business days.',
        'linkText': 'View Grievance Redressal Process',
        'linkRoute': '/grievance',
      },
      {
        'category': 'Policies & Legal',
        'q': 'Where can I read the Terms & Conditions?',
        'a': 'You can review our complete Terms & Conditions anytime at /terms or by clicking the link below.',
        'linkText': 'Open Terms & Conditions',
        'linkRoute': '/terms',
      },
      {
        'category': 'Policies & Legal',
        'q': 'Where can I read the Privacy Policy?',
        'a': 'You can read our complete data protection practices and Privacy Policy at /privacy or by clicking below.',
        'linkText': 'Open Privacy Policy',
        'linkRoute': '/privacy',
      },
    ];

    // Filter FAQs by category and search query
    final filteredFaqs = allFaqs.where((faq) {
      final matchesCategory = _selectedCategory == 'All' || faq['category'] == _selectedCategory;
      final q = (faq['q'] as String).toLowerCase();
      final a = (faq['a'] as String).toLowerCase();
      final matchesSearch = _searchQuery.isEmpty || q.contains(_searchQuery) || a.contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    if (filteredFaqs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          children: [
            const Icon(Icons.search_off, size: 40, color: Color(0xFF999999)),
            const SizedBox(height: 12),
            Text(
              'No FAQs found for "$_searchQuery"',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your search terms or select "All" categories.',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF777777)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'All';
                });
              },
              child: const Text('Reset Search & Filters'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredFaqs.length,
          separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
          itemBuilder: (ctx, i) {
            final faq = filteredFaqs[i];
            return Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 20,
                  vertical: 4,
                ),
                leading: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                title: Text(
                  faq['q'] as String,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111111),
                  ),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 16 : 56,
                      0,
                      isMobile ? 16 : 24,
                      16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          faq['a'] as String,
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 12.5 : 13,
                            color: const Color(0xFF444444),
                            height: 1.6,
                          ),
                        ),
                        if (faq['hasUtrButton'] == true) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _showUtrHelpModal,
                            icon: const Icon(Icons.help_outline, size: 16),
                            label: Text(
                              'Open UTR Visual Help Guide',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.black),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                          ),
                        ],
                        if (faq['linkText'] != null) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => context.push(faq['linkRoute'] as String),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    faq['linkText'] as String,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward, size: 13, color: Colors.black),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
