import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/business_provider.dart';
import '../providers/catalog_provider.dart';

class HZNavBar extends StatefulWidget implements PreferredSizeWidget {
  const HZNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(104);

  @override
  State<HZNavBar> createState() => _HZNavBarState();
}

class _HZNavBarState extends State<HZNavBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(BuildContext context, String query) {
    if (query.trim().isNotEmpty) {
      final catalog = Provider.of<CatalogProvider>(context, listen: false);
      catalog.setSearchQuery(query.trim());
      context.go('/products');
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = Provider.of<BusinessProvider>(context);
    final catalog = Provider.of<CatalogProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Top Announcement Bar (Solid Black Background)
            if (business.settings.announcementText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: const Color(0xFF000000),
                child: Text(
                  business.settings.announcementText
                      .replaceAll(RegExp(r'CURATED LUXURY\s*', caseSensitive: false), '')
                      .replaceAll(RegExp(r'LUXURY\s*', caseSensitive: false), ''),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
              ),

            // Main Navbar Header (Pure White & Black Accent)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
                ),
                child: Row(
                  children: [
                    // Brand Logo & Title
                    InkWell(
                      onTap: () {
                        catalog.toggleOffersOnly(false);
                        catalog.clearFilters();
                        context.go('/');
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'assets/images/logo_new.jpg',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'HASH ZONE',
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.5,
                                  color: const Color(0xFF000000),
                                ),
                              ),
                              Text(
                                'DIGITAL CATALOG',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2.0,
                                  color: const Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Desktop Navigation Items
                    if (isDesktop) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _navLink(context, 'HOME', '/'),

                          // Dynamic Segments Dropdown
                          if (catalog.departments.isNotEmpty)
                            MenuAnchor(
                              style: MenuStyle(
                                backgroundColor: WidgetStateProperty.all<Color>(Colors.white),
                                elevation: WidgetStateProperty.all<double>(8),
                                shape: WidgetStateProperty.all<OutlinedBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Color(0xFFE5E5E5)),
                                  ),
                                ),
                              ),
                              builder: (context, controller, child) {
                                return InkWell(
                                  onTap: () {
                                    if (controller.isOpen) {
                                      controller.close();
                                    } else {
                                      controller.open();
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    child: Row(
                                      children: [
                                        Text(
                                          'SEGMENTS',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.2,
                                            color: const Color(0xFF555555),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.keyboard_arrow_down, color: Color(0xFF555555), size: 18),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              menuChildren: catalog.departments.map((d) {
                                final categories = catalog.categories.where((c) => c.departmentId == d.id).toList();
                                return SubmenuButton(
                                  style: MenuItemButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  ),
                                  menuChildren: [
                                    MenuItemButton(
                                      style: MenuItemButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                      ),
                                      onPressed: () {
                                        catalog.toggleOffersOnly(false);
                                        catalog.setDepartmentFilter(d.id);
                                        catalog.setCategoryFilter('');
                                        context.go('/products');
                                      },
                                      child: Text(
                                        'Explore all ${d.name}',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF000000),
                                        ),
                                      ),
                                    ),
                                    ...categories.map((cat) => MenuItemButton(
                                      style: MenuItemButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                      ),
                                      onPressed: () {
                                        catalog.toggleOffersOnly(false);
                                        catalog.setDepartmentFilter(d.id);
                                        catalog.setCategoryFilter(cat.id);
                                        context.go('/products');
                                      },
                                      child: Text(
                                        cat.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: const Color(0xFF333333),
                                        ),
                                      ),
                                    )),
                                  ],
                                  child: Text(
                                    d.name.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.0,
                                      color: const Color(0xFF111111),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                          _navLink(context, 'OFFERS', '/products?offers=true'),
                          _navLink(context, 'ABOUT', '/about'),
                          _navLink(context, 'CONTACT', '/contact'),
                        ],
                      ),
                      const SizedBox(width: 20),

                      // Desktop Search Bar
                      SizedBox(
                        width: 160,
                        height: 38,
                        child: TextField(
                          onSubmitted: (query) {
                            if (query.trim().isNotEmpty) {
                              catalog.setSearchQuery(query.trim());
                              context.go('/products');
                            }
                          },
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF888888)),
                            prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF888888)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Admin Portal Shortcut Button (Fixed & Always Visible)
                      ElevatedButton.icon(
                        onPressed: () => context.go('/admin'),
                        icon: const Icon(Icons.lock_outline, size: 14, color: Colors.white),
                        label: Text(
                          'ADMIN',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF111111),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ] else ...[
                      const Spacer(),
                      Builder(
                        builder: (context) {
                          return IconButton(
                            icon: const Icon(Icons.menu, color: Colors.black, size: 26),
                            onPressed: () => Scaffold.of(context).openEndDrawer(),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Strictly determines if this nav link is active based on the current location route.
  Widget _navLink(BuildContext context, String title, String path) {
    final currentUri = GoRouterState.of(context).uri.toString();
    final catalog = Provider.of<CatalogProvider>(context, listen: false);

    bool isActive = false;
    if (path == '/') {
      isActive = (currentUri == '/' || currentUri.isEmpty);
    } else if (path.contains('offers=true')) {
      // ONLY active if URI actually contains offers=true
      isActive = currentUri.contains('offers=true');
    } else if (path == '/products') {
      // Active for catalog route ONLY if offers=true is NOT in URI
      isActive = currentUri.startsWith('/products') && !currentUri.contains('offers=true');
    } else {
      isActive = currentUri.startsWith(path);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: InkWell(
        onTap: () {
          if (path.contains('offers=true')) {
            catalog.toggleOffersOnly(true);
            context.go('/products?offers=true');
          } else {
            if (path == '/products') {
              catalog.toggleOffersOnly(false);
            }
            context.go(path);
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                letterSpacing: 1.2,
                color: isActive ? const Color(0xFF000000) : const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: 20,
              color: isActive ? const Color(0xFF000000) : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class HZMobileDrawer extends StatelessWidget {
  const HZMobileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = Provider.of<CatalogProvider>(context);
    final business = Provider.of<BusinessProvider>(context);

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(24),
              color: const Color(0xFFF7F7F8),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/images/logo_new.jpg',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HASH ZONE',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: const Color(0xFF000000),
                        ),
                      ),
                      Text(
                        'DIGITAL CATALOG',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFFE5E5E5), height: 1),

            // Navigation Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _drawerItem(context, Icons.home_outlined, 'HOME', '/'),
                  _drawerItem(context, Icons.local_offer_outlined, 'OFFERS & DEALS', '/products?offers=true'),
                  
                  if (catalog.departments.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8),
                      child: Text(
                        'SEGMENTS',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: const Color(0xFF888888),
                        ),
                      ),
                    ),
                    ...catalog.departments.map((d) {
                      final categories = catalog.categories.where((c) => c.departmentId == d.id).toList();
                      return Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 20),
                          title: Text(
                            d.name.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF333333),
                            ),
                          ),
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.only(left: 36, right: 20),
                              title: Text(
                                'Explore all ${d.name}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF000000),
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                catalog.toggleOffersOnly(false);
                                catalog.setDepartmentFilter(d.id);
                                catalog.setCategoryFilter('');
                                context.go('/products');
                              },
                            ),
                            ...categories.map((cat) => ListTile(
                              contentPadding: const EdgeInsets.only(left: 36, right: 20),
                              title: Text(
                                cat.name,
                                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF555555)),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                catalog.toggleOffersOnly(false);
                                catalog.setDepartmentFilter(d.id);
                                catalog.setCategoryFilter(cat.id);
                                context.go('/products');
                              },
                            )),
                          ],
                        ),
                      );
                    }),
                  ],

                  const Divider(color: Color(0xFFE5E5E5), height: 32),
                  
                  _drawerItem(context, Icons.info_outline, 'ABOUT US', '/about'),
                  _drawerItem(context, Icons.contact_support_outlined, 'CONTACT', '/contact'),
                  _drawerItem(context, Icons.admin_panel_settings_outlined, 'ADMIN PORTAL', '/admin'),
                ],
              ),
            ),

            // Drawer Footer Contact Info
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFFF7F7F8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Direct Contact:',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF666666)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    business.settings.contactNumbers.isNotEmpty ? business.settings.contactNumbers.first : '',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF000000)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, String path) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF333333), size: 20),
      title: Text(
        title,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: const Color(0xFF111111)),
      ),
      onTap: () {
        Navigator.pop(context);
        final catalog = Provider.of<CatalogProvider>(context, listen: false);
        if (path.contains('offers=true')) {
          catalog.toggleOffersOnly(true);
          context.go('/products?offers=true');
        } else {
          if (path == '/products') catalog.toggleOffersOnly(false);
          context.go(path);
        }
      },
    );
  }
}
