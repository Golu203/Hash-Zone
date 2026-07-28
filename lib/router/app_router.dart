import 'package:go_router/go_router.dart';

import '../screens/about_screen.dart';
import '../screens/admin/admin_banners_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/admin_product_edit_screen.dart';
import '../screens/admin/admin_products_screen.dart';
import '../screens/admin/admin_settings_screen.dart';
import '../screens/admin/admin_taxonomy_screen.dart';
import '../screens/admin/admin_user_manual_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/home_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/products_screen.dart';
import '../screens/error_screen.dart';
import '../services/auth_service.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) => ErrorScreen(message: state.error?.toString()),
  redirect: (context, state) {
    final location = state.uri.toString();
    final isGoingToAdmin = location.startsWith('/admin');
    final isGoingToLogin = location == '/admin/login';
    final isAuthenticated = AuthService().isAuthenticated;

    // Enforce authentication for ALL admin panel routes
    if (isGoingToAdmin && !isGoingToLogin && !isAuthenticated) {
      return '/admin/login';
    }

    // Redirect to dashboard if logged-in user hits /admin/login
    if (isGoingToLogin && isAuthenticated) {
      return '/admin/dashboard';
    }

    return null;
  },
  routes: [
    // Customer Routes
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

    // Admin Portal Routes
    GoRoute(
      path: '/admin',
      redirect: (context, state) => AuthService().isAuthenticated ? '/admin/dashboard' : '/admin/login',
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
  ],
);
