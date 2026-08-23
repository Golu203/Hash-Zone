import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/supply_network_provider.dart';
import '../../services/auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static String? currentSection;

  @override
  Widget build(BuildContext context) {
    final catalog = Provider.of<CatalogProvider>(context);
    final supplyNetwork = Provider.of<SupplyNetworkProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        title: Text(
          'HASH ZONE ADMIN DASHBOARD',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => context.go('/admin/manual'),
              icon: const Icon(Icons.menu_book, color: Colors.white, size: 18),
              label: Text(
                'USER MANUAL',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sign Out',
            onPressed: () async {
              currentSection = null; // Reset section state on logout
              await AuthService().signOut();
              if (context.mounted) context.go('/admin/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // USER MANUAL & QUICK LINKS CARD
            InkWell(
              onTap: () => context.go('/admin/manual'),
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 2.0),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_book, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📖 ADMIN USER MANUAL & QUICK LINKS DIRECTORY',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'View operational guide, image cropper instructions, and copy 1-click links for Banners & Popups.',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),

            if (currentSection == null) ...[
              Text(
                'OVERVIEW STATISTICS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.8,
                  color: const Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 16),

              // KPI Summary Row
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isDesktop ? 5 : 2,
                crossAxisSpacing: isDesktop ? 16 : 12,
                mainAxisSpacing: isDesktop ? 16 : 12,
                childAspectRatio: isDesktop ? 1.3 : 2.2,
                children: [
                  _kpiCard(context, 'TOTAL PRODUCTS', catalog.products.length.toString(), Icons.checkroom),
                  _kpiCard(context, 'SEGMENTS', catalog.departments.length.toString(), Icons.domain),
                  _kpiCard(context, 'CATEGORIES', catalog.categories.length.toString(), Icons.category),
                  _kpiCard(context, 'HERO BANNERS', catalog.heroBanners.length.toString(), Icons.view_carousel),
                  _kpiCard(context, 'SUPPLY STATES', supplyNetwork.states.length.toString(), Icons.map_outlined),
                ],
              ),

              const SizedBox(height: 40),

              Text(
                'PRIMARY MANAGEMENT CARDS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.8,
                  color: const Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 16),

              // 4 Primary Cards Layout
              isDesktop
                  ? GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 2.2,
                      children: _buildPrimaryCards(),
                    )
                  : Column(
                      children: _buildPrimaryCardsWithSpacing(),
                    ),
            ] else ...[
              // Section Sub-modules View
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        currentSection = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'Back to Dashboard',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _getSectionTitle(currentSection!),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.8,
                  color: const Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 16),

              // Sub-modules grid/list
              isDesktop
                  ? GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 2.2,
                      children: _buildSectionModules(currentSection!),
                    )
                  : Column(
                      children: _buildSectionModulesWithSpacing(currentSection!),
                    ),
            ],

            const SizedBox(height: 40),

            // Guidance Banner with Bold Black Border
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF000000), width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF000000),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Store Administrator Dashboard',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF000000),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All catalog changes made in this panel instantly update the live web application and customer WhatsApp inquiry messages.',
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF444444)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPrimaryCards() {
    return [
      _sectionLinkCard(
        title: 'WEBSITE DESIGN & CONTROL',
        subtitle: 'Products, Taxonomies, Sizes, Categories, Hero Banners, and India Supply Map.',
        icon: Icons.web_outlined,
        onTap: () => setState(() => currentSection = 'website'),
      ),
      _sectionLinkCard(
        title: 'ORDERS & CUSTOMERS',
        subtitle: 'Active & Previous Orders, Customer Management, and Payment Verifications.',
        icon: Icons.people_alt_outlined,
        onTap: () => setState(() => currentSection = 'orders'),
      ),
      _sectionLinkCard(
        title: 'PAYMENT & BUSINESS SETTINGS',
        subtitle: 'Bank Transfer details, payment configurations, and business contact settings.',
        icon: Icons.storefront_outlined,
        onTap: () => setState(() => currentSection = 'payment'),
      ),
      _sectionLinkCard(
        title: 'DEVELOPER & SYSTEM',
        subtitle: 'OCR Test Mode, connection diagnostics, backup & restores, system utilities.',
        icon: Icons.construction_outlined,
        onTap: () => setState(() => currentSection = 'developer'),
      ),
    ];
  }

  List<Widget> _buildPrimaryCardsWithSpacing() {
    final cards = _buildPrimaryCards();
    final List<Widget> spaced = [];
    for (int i = 0; i < cards.length; i++) {
      spaced.add(cards[i]);
      if (i < cards.length - 1) {
        spaced.add(const SizedBox(height: 16));
      }
    }
    return spaced;
  }

  String _getSectionTitle(String section) {
    switch (section) {
      case 'website':
        return 'WEBSITE DESIGN & CONTROL';
      case 'orders':
        return 'ORDERS & CUSTOMERS';
      case 'payment':
        return 'PAYMENT & BUSINESS SETTINGS';
      case 'developer':
        return 'DEVELOPER & SYSTEM';
      default:
        return '';
    }
  }

  List<Widget> _buildSectionModules(String section) {
    switch (section) {
      case 'website':
        return [
          _moduleCard(
            context,
            title: 'Products Management',
            subtitle: 'Add, edit, assign sizes, re-order Cloudinary images, toggle featured & offers.',
            icon: Icons.inventory_2_outlined,
            route: '/admin/products',
          ),
          _moduleCard(
            context,
            title: 'Taxonomies & Sizes',
            subtitle: 'Manage Segments, toggle Sizes Applicable on/off, set Categories & Subcategories.',
            icon: Icons.account_tree_outlined,
            route: '/admin/taxonomy',
          ),
          _moduleCard(
            context,
            title: 'Hero Banners & Offers',
            subtitle: 'Upload homepage hero slider banners and promotional headlines.',
            icon: Icons.view_carousel_outlined,
            route: '/admin/banners',
          ),
          _moduleCard(
            context,
            title: 'Supply Network',
            subtitle: 'Add, edit, or delete cities and states in the India supply network map.',
            icon: Icons.map_outlined,
            route: '/admin/supply-network',
          ),
          _moduleCard(
            context,
            title: 'Bundle Options',
            subtitle: 'Create and manage reusable bundle size templates (e.g. S-M-L-XL, 100 pcs). Assign them to products.',
            icon: Icons.inventory_2_outlined,
            route: '/admin/bundle-options',
          ),
        ];
      case 'orders':
        return [
          _moduleCard(
            context,
            title: 'Orders Management',
            subtitle: 'Manage received, confirmed, dispatched, and rejected orders, view customer info & receipts.',
            icon: Icons.shopping_bag_outlined,
            route: '/admin/orders',
          ),
          _moduleCard(
            context,
            title: 'Payment Verification',
            subtitle: 'Verify pending customer payment submissions, view screenshots, approve or reject.',
            icon: Icons.fact_check_outlined,
            route: '/admin/payment-verification',
          ),
        ];
      case 'payment':
        return [
          _moduleCard(
            context,
            title: 'Business & Contact Settings',
            subtitle: 'Edit WhatsApp number, call number, store address, and opening hours.',
            icon: Icons.settings_outlined,
            route: '/admin/settings',
          ),
          _moduleCard(
            context,
            title: 'Payment Configuration',
            subtitle: 'Configure Bank Transfer details and Payment Instructions.',
            icon: Icons.payments_outlined,
            route: '/admin/payment-config',
          ),
        ];
      case 'developer':
        return [
          _moduleCard(
            context,
            title: 'Developer & Testing',
            subtitle: 'Toggle OCR test mode, check live system connection health, run diagnostics.',
            icon: Icons.developer_mode_outlined,
            route: '/admin/developer-testing',
            onTap: () => _showDevPasswordDialog(context),
          ),
          _moduleCard(
            context,
            title: 'Backup & Recovery',
            subtitle: 'Create full database backups (.hzb) and perform smart restores.',
            icon: Icons.settings_backup_restore_outlined,
            route: '/admin/backup-recovery',
          ),
        ];
      default:
        return [];
    }
  }

  List<Widget> _buildSectionModulesWithSpacing(String section) {
    final modules = _buildSectionModules(section);
    final List<Widget> spaced = [];
    for (int i = 0; i < modules.length; i++) {
      spaced.add(modules[i]);
      if (i < modules.length - 1) {
        spaced.add(const SizedBox(height: 16));
      }
    }
    return spaced;
  }

  Widget _sectionLinkCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF000000), width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: const Color(0xFF000000),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: isMobile ? 22 : 28),
            ),
            SizedBox(width: isMobile ? 14 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 11 : 12,
                      height: 1.3,
                      color: const Color(0xFF444444),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF000000), width: 1.5),
              ),
              child: Icon(Icons.arrow_forward, color: const Color(0xFF000000), size: isMobile ? 12 : 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(BuildContext context, String title, String value, IconData icon) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF000000), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF000000), width: 1.0),
              ),
              child: Icon(icon, color: const Color(0xFF000000), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: const Color(0xFF444444),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF000000), width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: const Color(0xFF333333),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF000000), width: 1.0),
                ),
                child: Icon(icon, color: const Color(0xFF000000), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF000000),
            ),
          ),
        ],
      ),
    );
  }

  void _showDevPasswordDialog(BuildContext context) {
    final passwordCtrl = TextEditingController();
    bool obscure = true;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_outline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Developer Access',
                  style: GoogleFonts.cormorantGaramond(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please enter your developer password to access this section.',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Developer Password',
                  labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
                  errorText: errorText,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.black45,
                      size: 20,
                    ),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
                onSubmitted: (_) {
                  if (passwordCtrl.text.trim() == 'kushal287') {
                    Navigator.pop(ctx);
                    context.go('/admin/developer-testing');
                  } else {
                    setDialogState(() => errorText = 'Incorrect password. Access denied.');
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                passwordCtrl.dispose();
              },
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.black54, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                if (passwordCtrl.text.trim() == 'kushal287') {
                  Navigator.pop(ctx);
                  context.go('/admin/developer-testing');
                } else {
                  setDialogState(() => errorText = 'Incorrect password. Access denied.');
                }
              },
              child: Text('Enter', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moduleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
    VoidCallback? onTap,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return InkWell(
      onTap: onTap ?? () => context.go(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF000000), width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: const Color(0xFF000000),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: isMobile ? 22 : 28),
            ),
            SizedBox(width: isMobile ? 14 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 11 : 12,
                      height: 1.3,
                      color: const Color(0xFF444444),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF000000), width: 1.5),
              ),
              child: Icon(Icons.arrow_forward, color: const Color(0xFF000000), size: isMobile ? 12 : 16),
            ),
          ],
        ),
      ),
    );
  }
}
