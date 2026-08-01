import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../widgets/cart_notification.dart';

class CartItem {
  final String productId;
  final String title;
  final String imageUrl;
  final String size;
  final double price;
  final int quantity;
  final String productUrl;

  CartItem({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.size,
    required this.price,
    required this.quantity,
    required this.productUrl,
  });

  CartItem copyWith({
    String? productId,
    String? title,
    String? imageUrl,
    String? size,
    double? price,
    int? quantity,
    String? productUrl,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      size: size ?? this.size,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      productUrl: productUrl ?? this.productUrl,
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
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] ?? '',
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      size: map['size'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 1,
      productUrl: map['productUrl'] ?? '',
    );
  }
}

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;

  CartProvider() {
    _loadCart();
  }

  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  double get grandTotal => _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString('hashzone_cart');
      if (cartData != null) {
        final List decoded = jsonDecode(cartData);
        _items = decoded.map((e) => CartItem.fromMap(Map<String, dynamic>.from(e))).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = jsonEncode(_items.map((e) => e.toMap()).toList());
      await prefs.setString('hashzone_cart', cartData);
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  int getProductTotalQuantity(String productId) {
    return _items
        .where((item) => item.productId == productId)
        .fold(0, (sum, item) => sum + item.quantity);
  }

  void updateProductTotalQuantity(Product product, int newTotalQty) {
    final productItems = _items.where((item) => item.productId == product.id).toList();
    if (productItems.isEmpty) {
      if (newTotalQty > 0) {
        final size = product.availableSizes.isNotEmpty ? product.availableSizes.first : 'Free Size';
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

  void addItem(Product product, String size, double price, int quantity) {
    final domain = Uri.base.origin;
    final productUrl = '$domain/product/${product.slug}';

    final existingIndex = _items.indexWhere(
      (item) => item.productId == product.id && item.size == size,
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
        size: size,
        price: price,
        quantity: quantity,
        productUrl: productUrl,
      ));
    }
    notifyListeners();
    _saveCart();

    if (isNewItemOrSize) {
      HZCartNotification.showItemAdded(product.title, size: size);
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
      final mergedQty = _items[existingNewSizeIndex].quantity + _items[oldIndex].quantity;
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

  String generateWhatsAppMessage({String? customerName, String? customerPhone, String? customerNote}) {
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
      
      double productTotal = 0.0;
      for (var item in itemsList) {
        final double lineTotal = item.price * item.quantity;
        productTotal += lineTotal;
        buffer.writeln('   • Size ${item.size} × ${item.quantity} (₹${item.price.toStringAsFixed(0)} each) = ₹${lineTotal.toStringAsFixed(0)}');
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
