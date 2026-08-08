import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../screens/about_screen.dart';
import '../screens/admin/admin_banners_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/admin_product_edit_screen.dart';
import '../screens/admin/admin_products_screen.dart';
import '../screens/admin/admin_settings_screen.dart';
import '../screens/admin/admin_taxonomy_screen.dart';
import '../screens/admin/admin_user_manual_screen.dart';
import '../screens/admin/admin_supply_network_screen.dart';
import '../screens/admin/admin_payment_config_screen.dart';
import '../screens/admin/admin_payment_verification_screen.dart';
import '../screens/admin/admin_developer_testing_screen.dart';
import '../screens/admin/admin_orders_screen.dart';
import '../screens/admin/admin_backup_recovery_screen.dart';
import '../screens/customer/customer_orders_screen.dart';
import '../screens/customer/customer_order_details_screen.dart';
import '../screens/support_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/home_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/products_screen.dart';
import '../screens/error_screen.dart';
import '../services/auth_service.dart';
import '../providers/business_provider.dart';
import '../providers/customer_auth_provider.dart';
import '../screens/cart_screen.dart';
import '../screens/install_screen.dart';
import '../screens/auth/customer_login_screen.dart';
import '../screens/auth/customer_signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/onboarding/customer_onboarding_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/dashboard/customer_dashboard_screen.dart';
import '../screens/dashboard/profile_edit_screen.dart';
import '../screens/dashboard/address_management_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) => ErrorScreen(message: state.error?.toString()),
  redirect: (context, state) {
    final location = state.uri.toString();

    // ── Admin Auth Guard (unchanged) ─────────────────────────────────────────
    final isGoingToAdmin = location.startsWith('/admin');
    final isGoingToAdminLogin = location == '/admin/login';
    final isAdminAuthenticated = AuthService().isAuthenticated;

    if (isGoingToAdmin && !isGoingToAdminLogin && !isAdminAuthenticated) {
      return '/admin/login';
    }
    if (isGoingToAdminLogin && isAdminAuthenticated) {
      return '/admin/dashboard';
    }

    // ── Customer Auth Guard ──────────────────────────────────────────────────
    final customerAuth = Provider.of<CustomerAuthProvider>(context, listen: false);
    final isCustomerLoading = customerAuth.isLoading;

    // Let auth pages and public pages pass through freely
    final isAuthRoute = location.startsWith('/login') ||
        location.startsWith('/signup') ||
        location.startsWith('/forgot-password') ||
        location.startsWith('/onboarding') ||
        isGoingToAdmin;

    if (isAuthRoute) return null;

    // Protected customer routes
    final protectedRoutes = ['/profile', '/orders', '/dashboard', '/addresses', '/checkout'];
    final isProtected = protectedRoutes.any((r) => location.startsWith(r));

    if (isProtected && !isCustomerLoading && !customerAuth.isAuthenticated) {
      return '/login?redirect=${Uri.encodeComponent(location)}';
    }

    // After authenticated: if onboarding incomplete, redirect to onboarding
    // (except when already going there or to an auth screen)
    if (!isAuthRoute &&
        !isCustomerLoading &&
        customerAuth.isAuthenticated &&
        customerAuth.needsOnboarding) {
      return '/onboarding?redirect=${Uri.encodeComponent(location)}';
    }

    return null;
  },
  routes: [
    // ── Customer Routes (Public) ───────────────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductsScreen(),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ProductDetailScreen(productId: id);
      },
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: '/contact',
      builder: (context, state) => const ContactScreen(),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) {
        final business = Provider.of<BusinessProvider>(context);
        // ── Wait for Firestore before making the cart enable/disable decision.
        // Without this guard, the default enableShoppingCart = false kicks in on
        // page refresh and silently redirects to HomeScreen while the URL stays /cart.
        if (business.isLoading) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ),
            ),
          );
        }
        if (!business.settings.enableShoppingCart) {
          return const HomeScreen();
        }
        return const CartScreen();
      },
    ),
    GoRoute(
      path: '/install',
      builder: (context, state) => const InstallScreen(),
    ),
    GoRoute(
      path: '/support',
      builder: (context, state) => const SupportScreen(),
    ),
    GoRoute(
      path: '/contact',
      builder: (context, state) => const SupportScreen(),
    ),

    // ── Customer Auth Routes ───────────────────────────────────────────────────
    GoRoute(
      path: '/login',
      builder: (context, state) {
        final redirect = state.uri.queryParameters['redirect'];
        return CustomerLoginScreen(redirectTo: redirect);
      },
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) {
        final redirect = state.uri.queryParameters['redirect'];
        return CustomerSignupScreen(redirectTo: redirect);
      },
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) {
        final redirect = state.uri.queryParameters['redirect'];
        return ForgotPasswordScreen(redirectTo: redirect);
      },
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) {
        final redirect = state.uri.queryParameters['redirect'];
        return CustomerOnboardingScreen(redirectTo: redirect);
      },
    ),

    // ── Customer Protected Routes (Module 2) ──────────────────────────────────
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const CustomerDashboardScreen(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const ProfileEditScreen(),
    ),
    GoRoute(
      path: '/addresses',
      builder: (context, state) => const AddressManagementScreen(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const CustomerOrdersScreen(),
    ),
    GoRoute(
      path: '/orders/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return CustomerOrderDetailsScreen(orderId: id);
      },
    ),

    // ── Admin Portal Routes (unchanged) ───────────────────────────────────────
    GoRoute(
      path: '/admin',
      redirect: (context, state) =>
          AuthService().isAuthenticated ? '/admin/dashboard' : '/admin/login',
    ),
    GoRoute(
      path: '/admin/login',
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/products',
      builder: (context, state) => const AdminProductsScreen(),
    ),
    GoRoute(
      path: '/admin/products/new',
      builder: (context, state) => const AdminProductEditScreen(),
    ),
    GoRoute(
      path: '/admin/products/edit/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return AdminProductEditScreen(productId: id);
      },
    ),
    GoRoute(
      path: '/admin/taxonomy',
      builder: (context, state) => const AdminTaxonomyScreen(),
    ),
    GoRoute(
      path: '/admin/banners',
      builder: (context, state) => const AdminBannersScreen(),
    ),
    GoRoute(
      path: '/admin/settings',
      builder: (context, state) => const AdminSettingsScreen(),
    ),
    GoRoute(
      path: '/admin/manual',
      builder: (context, state) => const AdminUserManualScreen(),
    ),
    GoRoute(
      path: '/admin/supply-network',
      builder: (context, state) => const AdminSupplyNetworkScreen(),
    ),
    GoRoute(
      path: '/admin/payment-config',
      builder: (context, state) => const AdminPaymentConfigScreen(),
    ),
    GoRoute(
      path: '/admin/payment-verification',
      builder: (context, state) => const AdminPaymentVerificationScreen(),
    ),
    GoRoute(
      path: '/admin/developer-testing',
      builder: (context, state) => const AdminDeveloperTestingScreen(),
    ),
    GoRoute(
      path: '/admin/orders',
      builder: (context, state) => const AdminOrdersScreen(),
    ),
    GoRoute(
      path: '/admin/backup-recovery',
      builder: (context, state) => const AdminBackupRecoveryScreen(),
    ),
  ],
);
