import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/navbar.dart';
import '../../widgets/footer.dart';
import '../../widgets/smart_back_button.dart';

class CustomerDashboardScreen extends StatelessWidget {
  const CustomerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<CustomerAuthProvider>();
    final cart = context.watch<CartProvider>();
    final profile = auth.profile;
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HZNavBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header banner ─────────────────────────────────────────
            Container(
              width: double.infinity,
              color: Colors.black,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : 24,
                vertical: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HZSmartBackButton(fallbackRoute: '/', color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    'MY ACCOUNT',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: isDesktop ? 36 : 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile?.displayName.isNotEmpty == true
                        ? 'Welcome back, ${profile!.displayName}'
                        : 'Welcome back',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),

            // ── Dashboard grid ────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : 16,
                vertical: 40,
              ),
              child: isDesktop
                  ? _desktopLayout(context, auth, cart, profile)
                  : _mobileLayout(context, auth, cart, profile),
            ),
            const HZFooter(),
          ],
        ),
      ),
    );
  }

  // ── Desktop: sidebar + content ──────────────────────────────────────────────
  Widget _desktopLayout(BuildContext context, CustomerAuthProvider auth, CartProvider cart, dynamic profile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar
        SizedBox(
          width: 240,
          child: _DashboardSidebar(profile: profile, cart: cart, auth: auth),
        ),
        const SizedBox(width: 40),
        // Main Content
        Expanded(child: _ProfileCard(profile: profile)),
      ],
    );
  }

  // ── Mobile: stacked ─────────────────────────────────────────────────────────
  Widget _mobileLayout(BuildContext context, CustomerAuthProvider auth, CartProvider cart, dynamic profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileCard(profile: profile),
        const SizedBox(height: 24),
        _DashboardTiles(cart: cart, auth: auth),
      ],
    );
  }
}

// ── Sidebar (Desktop) ─────────────────────────────────────────────────────────
class _DashboardSidebar extends StatelessWidget {
  final dynamic profile;
  final CartProvider cart;
  final CustomerAuthProvider auth;

  const _DashboardSidebar({required this.profile, required this.cart, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9F9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.black,
                  child: Text(
                    _initials(profile?.displayName ?? ''),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.displayName.isNotEmpty == true
                            ? profile!.displayName
                            : 'My Account',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (profile?.email.isNotEmpty == true)
                        Text(
                          profile!.email,
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.black45),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _navItem(context, Icons.person_outline, 'Profile', () => context.go('/profile/edit')),
          _navItem(context, Icons.location_on_outlined, 'Addresses', () => context.go('/addresses')),
          _navItem(context, Icons.shopping_bag_outlined, 'Cart', () => context.go('/cart'),
              badge: cart.totalQuantity > 0 ? '${cart.totalQuantity}' : null),
          _navItem(context, Icons.receipt_long_outlined, 'Orders', () => context.go('/orders')),
          _navItem(context, Icons.folder_outlined, 'Documents', null, disabled: true, tag: 'Coming Soon'),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _navItem(context, Icons.store_outlined, 'Continue Shopping', () => context.go('/')),
          _navItem(
            context,
            Icons.logout_outlined,
            'Sign Out',
            () => _confirmSignOut(context, auth),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onTap, {
    String? badge,
    bool disabled = false,
    String? tag,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: disabled ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: disabled
                  ? Colors.black26
                  : isDestructive
                      ? const Color(0xFFD32F2F)
                      : Colors.black87,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: disabled
                      ? Colors.black26
                      : isDestructive
                          ? const Color(0xFFD32F2F)
                          : Colors.black87,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(badge, style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            if (tag != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(tag, style: GoogleFonts.inter(fontSize: 10, color: Colors.black45)),
              ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  void _confirmSignOut(BuildContext context, CustomerAuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Sign Out', style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, fontSize: 22)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.inter(fontSize: 14, color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
              if (context.mounted) context.go('/');
            },
            child: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Profile Card (main content) ───────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final dynamic profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Profile Information', style: GoogleFonts.cormorantGaramond(fontSize: 22, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.go('/profile/edit'),
                icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.black),
                label: Text('Edit', style: GoogleFonts.inter(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (profile == null)
            const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black)))
          else ...[
            _infoRow('Name', profile.displayName.isNotEmpty ? profile.displayName : '—'),
            _infoRow('Email', profile.email.isNotEmpty ? profile.email : '—'),
            _infoRow('Company', profile.companyName.isNotEmpty ? profile.companyName : '—'),
            _infoRow('Mobile', profile.phoneNumber.isNotEmpty ? profile.phoneNumber : '—'),
            _infoRow('WhatsApp', profile.whatsAppNumber.isNotEmpty ? profile.whatsAppNumber : '—'),
          ],
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _actionChip(context, Icons.receipt_long_outlined, 'My Orders', () => context.go('/orders')),
              _actionChip(context, Icons.location_on_outlined, 'Manage Addresses', () => context.go('/addresses')),
              _actionChip(context, Icons.shopping_bag_outlined, 'View Cart', () => context.go('/cart')),
              _actionChip(context, Icons.store_outlined, 'Browse Store', () => context.go('/')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _actionChip(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDDDDDD)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.black87),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}

// ── Mobile Tiles ──────────────────────────────────────────────────────────────
class _DashboardTiles extends StatelessWidget {
  final CartProvider cart;
  final CustomerAuthProvider auth;
  const _DashboardTiles({required this.cart, required this.auth});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _tile(context, Icons.person_outline, 'Profile', () => context.go('/profile/edit')),
        _tile(context, Icons.location_on_outlined, 'Addresses', () => context.go('/addresses')),
        _tile(context, Icons.shopping_bag_outlined, 'Cart',
            () => context.go('/cart'),
            badge: cart.totalQuantity > 0 ? '${cart.totalQuantity}' : null),
        _tile(context, Icons.receipt_long_outlined, 'Orders', () => context.go('/orders')),
        _tile(context, Icons.folder_outlined, 'Documents', null, disabled: true),
        _tile(context, Icons.logout_outlined, 'Sign Out',
            () => _signOut(context, auth),
            isDestructive: true),
      ],
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, VoidCallback? onTap, {String? badge, bool disabled = false, bool isDestructive = false}) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: disabled ? const Color(0xFFF0F0F0) : const Color(0xFFDDDDDD)),
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 28, color: disabled ? Colors.black26 : isDestructive ? const Color(0xFFD32F2F) : Colors.black),
                if (badge != null)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                      child: Text(badge, style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: disabled ? Colors.black26 : isDestructive ? const Color(0xFFD32F2F) : Colors.black87),
              textAlign: TextAlign.center,
            ),
            if (disabled) Text('Coming Soon', style: GoogleFonts.inter(fontSize: 10, color: Colors.black26)),
          ],
        ),
      ),
    );
  }

  void _signOut(BuildContext context, CustomerAuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Sign Out?', style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, fontSize: 22)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.inter(fontSize: 14, color: Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0),
            onPressed: () async { Navigator.pop(ctx); await auth.signOut(); if (context.mounted) context.go('/'); },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
