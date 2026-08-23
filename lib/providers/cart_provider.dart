import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/firestore_cart_service.dart';
import '../widgets/cart_notification.dart';

class CartItem {
  final String productId;
  final String title;
  final String imageUrl;
  // For bundle items: stores the bundle name. For legacy: stores the size.
  final String size;
  // For bundle items: price per bundle. For legacy: price per piece.
  final double price;
  // For bundle items: number of bundles. For legacy: number of pieces.
  final int quantity;
  final String productUrl;
  final String sku;

  // ─── Bundle fields (null for legacy items) ──────────────────────────────
  final String? bundleName;
  final List<String>? bundleSizes;
  final int? totalPiecesPerBundle;
  final int? piecesPerSize;

  CartItem({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.size,
    required this.price,
    required this.quantity,
    required this.productUrl,
    required this.sku,
    this.bundleName,
    this.bundleSizes,
    this.totalPiecesPerBundle,
    this.piecesPerSize,
  });

  bool get isBundleItem => bundleName != null && bundleName!.isNotEmpty;

  /// Total physical pieces in this cart line
  int get totalPieces =>
      isBundleItem ? (totalPiecesPerBundle ?? 0) * quantity : quantity;

  CartItem copyWith({
    String? productId,
    String? title,
    String? imageUrl,
    String? size,
    double? price,
    int? quantity,
    String? productUrl,
    String? sku,
    String? bundleName,
    List<String>? bundleSizes,
    int? totalPiecesPerBundle,
    int? piecesPerSize,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      size: size ?? this.size,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      productUrl: productUrl ?? this.productUrl,
      sku: sku ?? this.sku,
      bundleName: bundleName ?? this.bundleName,
      bundleSizes: bundleSizes ?? this.bundleSizes,
      totalPiecesPerBundle: totalPiecesPerBundle ?? this.totalPiecesPerBundle,
      piecesPerSize: piecesPerSize ?? this.piecesPerSize,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'title': title,
      'imageUrl': imageUrl,
      'size': size,
      'price': price,
      'quantity': quantity,
      'productUrl': productUrl,
      'sku': sku,
      if (bundleName != null) 'bundleName': bundleName,
      if (bundleSizes != null) 'bundleSizes': bundleSizes,
      if (totalPiecesPerBundle != null) 'totalPiecesPerBundle': totalPiecesPerBundle,
      if (piecesPerSize != null) 'piecesPerSize': piecesPerSize,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    final rawBundleSizes = map['bundleSizes'];
    return CartItem(
      productId: map['productId'] ?? '',
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      size: map['size'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 1,
      productUrl: map['productUrl'] ?? '',
      sku: map['sku'] ?? '',
      bundleName: map['bundleName'] as String?,
      bundleSizes: rawBundleSizes != null ? List<String>.from(rawBundleSizes as List) : null,
      totalPiecesPerBundle: (map['totalPiecesPerBundle'] as num?)?.toInt(),
      piecesPerSize: (map['piecesPerSize'] as num?)?.toInt(),
    );
  }
}

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  String? _uid; // null = guest (local storage only)
  final FirestoreCartService _firestoreCart = FirestoreCartService();

  List<CartItem> get items => _items;

  CartProvider() {
    _loadCart();
  }

  // ── Auth wiring ─────────────────────────────────────────────────────────────
  /// Called by main.dart listener when user signs in.
  /// If the guest already added items to their cart, those items become the active
  /// checkout cart and are synced to Firestore (no unwanted merging with older carts).
  /// If the cart was empty, load the customer's saved Firestore cart.
  Future<void> attachUser(String uid) async {
    _uid = uid;
    
    if (_items.isNotEmpty) {
      // Guest cart takes priority for this checkout session: sync it to Firestore
      await _firestoreCart.syncCart(uid, _items);
    } else {
      // Direct login without a guest cart: load customer's saved cart from Firestore
      final firestoreItems = await _firestoreCart.loadCart(uid);
      if (firestoreItems.isNotEmpty) {
        _items = firestoreItems;
      }
    }

    await _saveCart();
    notifyListeners();
  }

  /// Called when user signs out.
  /// Starts a completely fresh, isolated guest session with an empty cart.
  Future<void> detachUser() async {
    _uid = null;
    _items = [];
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('hashzone_cart');
    } catch (_) {}
  }

  // ── Computed ────────────────────────────────────────────────────────────────
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);
  double get grandTotal =>
      _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  // ── Local persistence ───────────────────────────────────────────────────────
  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString('hashzone_cart');
      if (cartData != null) {
        final List decoded = jsonDecode(cartData);
        _items =
            decoded.map((e) => CartItem.fromMap(Map<String, dynamic>.from(e))).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveCart() async {
    // Local prefs (guest sessions / offline fallback)
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = jsonEncode(_items.map((e) => e.toMap()).toList());
      await prefs.setString('hashzone_cart', cartData);
    } catch (_) {}

    // Firestore sync (authenticated users)
    if (_uid != null) {
      _firestoreCart.syncCart(_uid!, _items).catchError((_) {});
    }
  }

  // ── Public API (unchanged signatures) ──────────────────────────────────────
  int getProductTotalQuantity(String productId) {
    return _items
        .where((item) => item.productId == productId)
        .fold(0, (sum, item) => sum + item.quantity);
  }

  void updateProductTotalQuantity(Product product, int newTotalQty) {
    final productItems = _items.where((item) => item.productId == product.id).toList();
    if (productItems.isEmpty) {
      if (newTotalQty > 0) {
        final size =
            product.availableSizes.isNotEmpty ? product.availableSizes.first : 'Free Size';
        final price = product.getActivePriceForSize(size);
        addItem(product, size, price, newTotalQty);
      }
      return;
    }

    if (newTotalQty <= 0) {
      _items.removeWhere((item) => item.productId == product.id);
      notifyListeners();
      _saveCart();
      return;
    }

    final firstItem = productItems.first;
    final otherItemsSum = productItems.skip(1).fold(0, (sum, item) => sum + item.quantity);
    final neededQtyForFirst = newTotalQty - otherItemsSum;

    if (neededQtyForFirst <= 0) {
      _items.remove(firstItem);
      updateProductTotalQuantity(product, newTotalQty);
    } else {
      final index = _items.indexOf(firstItem);
      _items[index] = _items[index].copyWith(quantity: neededQtyForFirst);
      notifyListeners();
      _saveCart();
    }
  }

  void addItem(
    Product product,
    String size,
    double price,
    int quantity, {
    String? bundleName,
    List<String>? bundleSizes,
    int? totalPiecesPerBundle,
    int? piecesPerSize,
  }) {
    final domain = Uri.base.origin;
    final productUrl = '$domain/#/product/${product.slug}';

    // Bundle items key on productId only (one bundle config per product)
    // Legacy items key on (productId, size)
    final effectiveSize = bundleName ?? size;
    final existingIndex = _items.indexWhere(
      (item) => item.productId == product.id && item.size == effectiveSize,
    );

    final isNewItemOrSize = (existingIndex == -1);

    if (existingIndex != -1) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + quantity,
      );
    } else {
      _items.add(CartItem(
        productId: product.id,
        title: product.title,
        imageUrl: product.coverImageUrl,
        size: effectiveSize,
        price: price,
        quantity: quantity,
        productUrl: productUrl,
        sku: product.sku,
        bundleName: bundleName,
        bundleSizes: bundleSizes,
        totalPiecesPerBundle: totalPiecesPerBundle,
        piecesPerSize: piecesPerSize,
      ));
    }
    notifyListeners();
    _saveCart();

    if (isNewItemOrSize) {
      HZCartNotification.showItemAdded(
        product.title,
        size: bundleName != null ? '$bundleName (×$quantity bundles)' : size,
      );
    }
  }

  void updateQuantity(String productId, String size, int newQty) {
    if (newQty <= 0) {
      removeItem(productId, size);
      return;
    }

    final index = _items.indexWhere(
      (item) => item.productId == productId && item.size == size,
    );

    if (index != -1) {
      _items[index] = _items[index].copyWith(quantity: newQty);
      notifyListeners();
      _saveCart();
    }
  }

  void updateSize(String productId, String oldSize, String newSize, double newPrice) {
    final oldIndex = _items.indexWhere(
      (item) => item.productId == productId && item.size == oldSize,
    );
    if (oldIndex == -1) return;

    final existingNewSizeIndex = _items.indexWhere(
      (item) => item.productId == productId && item.size == newSize,
    );

    if (existingNewSizeIndex != -1 && existingNewSizeIndex != oldIndex) {
      final mergedQty =
          _items[existingNewSizeIndex].quantity + _items[oldIndex].quantity;
      _items[existingNewSizeIndex] = _items[existingNewSizeIndex].copyWith(
        quantity: mergedQty,
        price: newPrice,
      );
      _items.removeAt(oldIndex);
    } else {
      _items[oldIndex] = _items[oldIndex].copyWith(
        size: newSize,
        price: newPrice,
      );
    }
    notifyListeners();
    _saveCart();
  }

  void removeItem(String productId, String size) {
    _items.removeWhere(
      (item) => item.productId == productId && item.size == size,
    );
    notifyListeners();
    _saveCart();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
    _saveCart();
  }

  String generateWhatsAppMessage({
    String? customerName,
    String? customerPhone,
    String? customerNote,
    Map<String, String>? productSkus,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🛍️ *NEW ORDER INQUIRY - HASH ZONE*');
    buffer.writeln('──────────────────');

    if (customerName != null && customerName.trim().isNotEmpty) {
      buffer.writeln('👤 *Customer Details*');
      buffer.writeln('   • Name: ${customerName.trim()}');
      if (customerPhone != null && customerPhone.trim().isNotEmpty) {
        buffer.writeln('   • Phone: ${customerPhone.trim()}');
      }
      if (customerNote != null && customerNote.trim().isNotEmpty) {
        buffer.writeln('   • Note: ${customerNote.trim()}');
      }
      buffer.writeln('──────────────────');
    }

    final grouped = <String, List<CartItem>>{};
    for (var item in _items) {
      grouped.putIfAbsent(item.productId, () => []).add(item);
    }

    var index = 1;
    grouped.forEach((productId, itemsList) {
      final firstItem = itemsList.first;
      buffer.writeln('$index. *${firstItem.title}*');

      final skuFromMap = productSkus?[productId] ?? '';
      final sku = skuFromMap.isNotEmpty ? skuFromMap : firstItem.sku;
      if (sku.trim().isNotEmpty) {
        buffer.writeln('   • SKU CODE: "${sku.trim()}"');
      }

      double productTotal = 0.0;
      for (var item in itemsList) {
        final double lineTotal = item.price * item.quantity;
        productTotal += lineTotal;
        if (item.isBundleItem) {
          // Bundle display
          final sizes = item.bundleSizes?.join(', ') ?? item.bundleName ?? '';
          final pieces = item.totalPiecesPerBundle ?? 0;
          buffer.writeln(
              '   • Bundle: ${item.bundleName} (${item.quantity} × $pieces pcs = ${item.totalPieces} pcs)');
          buffer.writeln(
              '     Sizes: $sizes | ₹${item.price.toStringAsFixed(0)}/bundle × ${item.quantity} = ₹${lineTotal.toStringAsFixed(0)}');
        } else {
          // Legacy size display
          buffer.writeln(
              '   • Size ${item.size} × ${item.quantity} (₹${item.price.toStringAsFixed(0)} each) = ₹${lineTotal.toStringAsFixed(0)}');
        }
      }

      buffer.writeln('   *Product Total: ₹${productTotal.toStringAsFixed(0)}*');
      buffer.writeln('   Link: ${firstItem.productUrl}');
      buffer.writeln('──────────────────');
      index++;
    });

    buffer.writeln('💰 *Grand Total: ₹${grandTotal.toStringAsFixed(0)}*');
    return buffer.toString();
  }
}
