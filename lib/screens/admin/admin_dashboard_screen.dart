import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/catalog_provider.dart';
import '../../services/auth_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = Provider.of<CatalogProvider>(context);
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

            // KPI Summary Row (Responsive Grid: wider aspect ratio on mobile to fit the horizontal row layout)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isDesktop ? 4 : 2,
              crossAxisSpacing: isDesktop ? 20 : 12,
              mainAxisSpacing: isDesktop ? 20 : 12,
              childAspectRatio: isDesktop ? 1.6 : 2.2,
              children: [
                _kpiCard(context, 'TOTAL PRODUCTS', catalog.products.length.toString(), Icons.checkroom),
                _kpiCard(context, 'SEGMENTS', catalog.departments.length.toString(), Icons.domain),
                _kpiCard(context, 'CATEGORIES', catalog.categories.length.toString(), Icons.category),
                _kpiCard(context, 'HERO BANNERS', catalog.heroBanners.length.toString(), Icons.view_carousel),
              ],
            ),

            const SizedBox(height: 40),

            Text(
              'STORE MANAGEMENT MODULES',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.8,
                color: const Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 16),

            // Modules Layout (Responsive: Grid on desktop, dynamically-sized Column on mobile to avoid clipping)
            isDesktop
                ? GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 2.2,
                    children: [
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
                        title: 'Business & Contact Settings',
                        subtitle: 'Edit WhatsApp number, call number, store address, and opening hours.',
                        icon: Icons.settings_outlined,
                        route: '/admin/settings',
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _moduleCard(
                        context,
                        title: 'Products Management',
                        subtitle: 'Add, edit, assign sizes, re-order Cloudinary images, toggle featured & offers.',
                        icon: Icons.inventory_2_outlined,
                        route: '/admin/products',
                      ),
                      const SizedBox(height: 16),
                      _moduleCard(
                        context,
                        title: 'Taxonomies & Sizes',
                        subtitle: 'Manage Segments, toggle Sizes Applicable on/off, set Categories & Subcategories.',
                        icon: Icons.account_tree_outlined,
                        route: '/admin/taxonomy',
                      ),
                      const SizedBox(height: 16),
                      _moduleCard(
                        context,
                        title: 'Hero Banners & Offers',
                        subtitle: 'Upload homepage hero slider banners and promotional headlines.',
                        icon: Icons.view_carousel_outlined,
                        route: '/admin/banners',
                      ),
                      const SizedBox(height: 16),
                      _moduleCard(
                        context,
                        title: 'Business & Contact Settings',
                        subtitle: 'Edit WhatsApp number, call number, store address, and opening hours.',
                        icon: Icons.settings_outlined,
                        route: '/admin/settings',
                      ),
                    ],
                  ),

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

  Widget _moduleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return InkWell(
      onTap: () => context.go(route),
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
