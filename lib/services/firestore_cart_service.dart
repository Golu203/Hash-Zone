// ─── FirestoreCartService ────────────────────────────────────────────────────
// Handles Firestore read/write for customer cart.
// Collection: customers/{uid}/cart/{itemKey}
// itemKey = productId_size (unique per product+size combo)

import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/cart_provider.dart';

class FirestoreCartService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _cartRef(String uid) =>
      _db.collection('customers').doc(uid).collection('cart');

  // ── Write all items ────────────────────────────────────────────────────────
  Future<void> syncCart(String uid, List<CartItem> items) async {
    final batch = _db.batch();
    final ref = _cartRef(uid);

    // Delete all existing items first
    final existing = await ref.get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    // Write current items
    for (final item in items) {
      final key = '${item.productId}_${item.size}';
      batch.set(ref.doc(key), {
        ...item.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // ── Add or update a single item ────────────────────────────────────────────
  Future<void> upsertItem(String uid, CartItem item) async {
    final key = '${item.productId}_${item.size}';
    await _cartRef(uid).doc(key).set({
      ...item.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Remove a single item ────────────────────────────────────────────────────
  Future<void> removeItem(String uid, String productId, String size) async {
    final key = '${productId}_$size';
    await _cartRef(uid).doc(key).delete();
  }

  // ── Clear all items ────────────────────────────────────────────────────────
  Future<void> clearCart(String uid) async {
    final snapshot = await _cartRef(uid).get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ── Load all items ─────────────────────────────────────────────────────────
  Future<List<CartItem>> loadCart(String uid) async {
    final snapshot = await _cartRef(uid).get();
    return snapshot.docs
        .map((doc) => CartItem.fromMap(doc.data()))
        .toList();
  }

  // ── Stream cart ────────────────────────────────────────────────────────────
  Stream<List<CartItem>> streamCart(String uid) {
    return _cartRef(uid).snapshots().map(
          (snap) => snap.docs.map((doc) => CartItem.fromMap(doc.data())).toList(),
        );
  }
}
