import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../router/app_router.dart';

class HZCartNotification {
  static Timer? _snackBarTimer;

  static void showItemAdded(String productTitle, {String? size}) {
    _snackBarTimer?.cancel();
    rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();

    final sizeText = (size != null && size.isNotEmpty) ? ' ($size)' : '';
    final message = '"$productTitle"$sizeText added to cart.';

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        duration: const Duration(seconds: 6),
        backgroundColor: const Color(0xFF111111),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            _snackBarTimer?.cancel();
            rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
            appRouter.go('/cart');
          },
        ),
      ),
    );

    _snackBarTimer = Timer(const Duration(seconds: 6), () {
      rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    });
  }
}
