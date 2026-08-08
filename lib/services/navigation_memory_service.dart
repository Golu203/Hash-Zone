// ─── NavigationMemoryService ──────────────────────────────────────────────────
// Smart Back Navigation & State Memory Engine for HashZone V1 Customer Website.
// Saves & restores scroll positions, search queries, filters, categories,
// selected variants, form inputs, and active tabs with zero extra database reads.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationStateSnapshot {
  final String route;
  final double scrollOffset;
  final String? searchQuery;
  final String? selectedCategory;
  final String? selectedCollection;
  final String? activeFilter;
  final String? sortOption;
  final String? selectedSize;
  final int? selectedQuantity;
  final Map<String, dynamic>? customData;
  final DateTime timestamp;

  NavigationStateSnapshot({
    required this.route,
    this.scrollOffset = 0.0,
    this.searchQuery,
    this.selectedCategory,
    this.selectedCollection,
    this.activeFilter,
    this.sortOption,
    this.selectedSize,
    this.selectedQuantity,
    this.customData,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class NavigationMemoryService extends ChangeNotifier {
  static final NavigationMemoryService _instance = NavigationMemoryService._internal();
  factory NavigationMemoryService() => _instance;
  NavigationMemoryService._internal();

  final List<NavigationStateSnapshot> _history = [];
  final Map<String, NavigationStateSnapshot> _routeMemory = {};

  /// Saves or updates state snapshot for a route
  void saveSnapshot({
    required String route,
    double scrollOffset = 0.0,
    String? searchQuery,
    String? selectedCategory,
    String? selectedCollection,
    String? activeFilter,
    String? sortOption,
    String? selectedSize,
    int? selectedQuantity,
    Map<String, dynamic>? customData,
  }) {
    final snapshot = NavigationStateSnapshot(
      route: route,
      scrollOffset: scrollOffset,
      searchQuery: searchQuery,
      selectedCategory: selectedCategory,
      selectedCollection: selectedCollection,
      activeFilter: activeFilter,
      sortOption: sortOption,
      selectedSize: selectedSize,
      selectedQuantity: selectedQuantity,
      customData: customData,
    );

    _routeMemory[route] = snapshot;

    if (_history.isEmpty || _history.last.route != route) {
      _history.add(snapshot);
    } else {
      _history[_history.length - 1] = snapshot;
    }
  }

  /// Retrieves last saved snapshot for a specific route
  NavigationStateSnapshot? getSnapshot(String route) {
    return _routeMemory[route];
  }

  /// Pops current route snapshot and returns previous snapshot
  NavigationStateSnapshot? popSnapshot() {
    if (_history.isNotEmpty) {
      _history.removeLast();
    }
    if (_history.isNotEmpty) {
      return _history.last;
    }
    return null;
  }

  /// Smart Back Action: returns to exact previous route with restored state or fallback
  void smartGoBack(BuildContext context, {String fallbackRoute = '/'}) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    final prevSnapshot = popSnapshot();
    if (prevSnapshot != null && prevSnapshot.route.isNotEmpty) {
      context.go(prevSnapshot.route);
    } else {
      context.go(fallbackRoute);
    }
  }

  /// Helper to attach scroll listener and auto-restore position when page builds
  void attachScrollRestoration({
    required ScrollController controller,
    required String route,
  }) {
    final snapshot = getSnapshot(route);
    if (snapshot != null && snapshot.scrollOffset > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.hasClients) {
          controller.jumpTo(
            snapshot.scrollOffset.clamp(0.0, controller.position.maxScrollExtent),
          );
        }
      });
    }

    controller.addListener(() {
      if (controller.hasClients) {
        saveSnapshot(
          route: route,
          scrollOffset: controller.offset,
          searchQuery: getSnapshot(route)?.searchQuery,
          selectedCategory: getSnapshot(route)?.selectedCategory,
          selectedCollection: getSnapshot(route)?.selectedCollection,
          activeFilter: getSnapshot(route)?.activeFilter,
          sortOption: getSnapshot(route)?.sortOption,
          selectedSize: getSnapshot(route)?.selectedSize,
          selectedQuantity: getSnapshot(route)?.selectedQuantity,
          customData: getSnapshot(route)?.customData,
        );
      }
    });
  }
}
