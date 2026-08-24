import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;

import 'providers/admin_provider.dart';
import 'providers/business_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/supply_network_provider.dart';
import 'providers/customer_auth_provider.dart';
import 'providers/address_provider.dart';
import 'router/app_router.dart';
import 'services/firebase_options.dart';
import 'services/firestore_service.dart';
import 'services/image_service.dart';
import 'services/customer_auth_service.dart';
import 'services/address_service.dart';
import 'services/payment_config_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestoreService = FirestoreService();
  final imageService = ImageService();
  final customerAuthService = CustomerAuthService();
  final addressService = AddressService();

  // Seed payment config skeleton in Firestore if absent (silent, no UI impact)
  PaymentConfigService().seedIfAbsent().catchError((_) {});

  runApp(
    ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider(create: (_) => BusinessProvider(firestoreService)),
          provider.ChangeNotifierProvider(create: (_) => CatalogProvider(firestoreService)),
          provider.ChangeNotifierProvider(create: (_) => AdminProvider(firestoreService, imageService)),
          provider.ChangeNotifierProvider(create: (_) => CartProvider()),
          provider.ChangeNotifierProvider(create: (_) => SupplyNetworkProvider(firestoreService)),
          provider.ChangeNotifierProvider(create: (_) => CustomerAuthProvider(customerAuthService)),
          provider.ChangeNotifierProvider(create: (_) => AddressProvider(addressService)),
        ],
        child: const HashZoneApp(),
      ),
    ),
  );
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class HashZoneApp extends StatefulWidget {
  const HashZoneApp({super.key});

  @override
  State<HashZoneApp> createState() => _HashZoneAppState();
}

class _HashZoneAppState extends State<HashZoneApp> {
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Wire CustomerAuthProvider → CartProvider + AddressProvider
    // So cart syncs to Firestore when user logs in/out.
    _authSub?.cancel();
    final authProvider = provider.Provider.of<CustomerAuthProvider>(context, listen: false);
    final cartProvider = provider.Provider.of<CartProvider>(context, listen: false);
    final addrProvider = provider.Provider.of<AddressProvider>(context, listen: false);

    _authSub = authProvider.authStateStream.listen((uid) {
      if (uid != null) {
        cartProvider.attachUser(uid);
        addrProvider.attachUser(uid);
      } else {
        cartProvider.detachUser();
        addrProvider.detachUser();
      }
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    _authSub?.cancel();
    super.dispose();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return false;
    }

    final key = event.logicalKey;
    final isArrowDown = key == LogicalKeyboardKey.arrowDown;
    final isArrowUp = key == LogicalKeyboardKey.arrowUp;
    final isPageDown = key == LogicalKeyboardKey.pageDown;
    final isPageUp = key == LogicalKeyboardKey.pageUp;

    if (!isArrowDown && !isArrowUp && !isPageDown && !isPageUp) {
      return false;
    }

    // 1. Never intercept when focus is on an EditableText (TextField, textarea, search, address, GST, etc.)
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null) {
      final context = primaryFocus.context;
      if (context != null) {
        final isEditable = context.findAncestorWidgetOfExactType<EditableText>() != null;
        if (isEditable) {
          return false;
        }
      }
    }

    // 2. Find the active scrollable on the topmost route
    final navContext = rootNavigatorKey.currentContext ?? rootScaffoldMessengerKey.currentContext;
    if (navContext == null) return false;

    ScrollableState? targetScrollable;
    void visitor(Element element) {
      if (targetScrollable != null) return;
      if (element.widget is Scrollable) {
        final state = (element as StatefulElement).state;
        if (state is ScrollableState &&
            state.position.hasPixels &&
            state.position.maxScrollExtent > 0 &&
            state.axisDirection == AxisDirection.down) {
          targetScrollable = state;
          return;
        }
      }
      element.visitChildren(visitor);
    }

    navContext.visitChildElements(visitor);

    if (targetScrollable != null && targetScrollable!.position.hasPixels) {
      final position = targetScrollable!.position;
      double delta = 0.0;
      if (isArrowDown) {
        delta = 90.0;
      } else if (isArrowUp) {
        delta = -90.0;
      } else if (isPageDown) {
        delta = position.viewportDimension * 0.85;
      } else if (isPageUp) {
        delta = -position.viewportDimension * 0.85;
      }

      final targetPixels = (position.pixels + delta).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );

      if ((targetPixels - position.pixels).abs() > 0.5) {
        position.animateTo(
          targetPixels,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutQuad,
        );
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'HASH ZONE | Digital Clothing Catalog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
