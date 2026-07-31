import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;

import 'providers/admin_provider.dart';
import 'providers/business_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/supply_network_provider.dart';
import 'router/app_router.dart';
import 'services/firebase_options.dart';
import 'services/firestore_service.dart';
import 'services/image_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with hashzone options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestoreService = FirestoreService();
  final imageService = ImageService();

  runApp(
    ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider(create: (_) => BusinessProvider(firestoreService)),
          provider.ChangeNotifierProvider(create: (_) => CatalogProvider(firestoreService)),
          provider.ChangeNotifierProvider(create: (_) => AdminProvider(firestoreService, imageService)),
          provider.ChangeNotifierProvider(create: (_) => CartProvider()),
          provider.ChangeNotifierProvider(create: (_) => SupplyNetworkProvider(firestoreService)),
        ],
        child: const HashZoneApp(),
      ),
    ),
  );
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class HashZoneApp extends StatelessWidget {
  const HashZoneApp({super.key});

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
