// ─── OrderLockService ────────────────────────────────────────────────────────
// Order locking in Firestore collection orderLocks.
// Prevents conflicting admin updates with auto-expiration TTL (5 mins).

import 'package:cloud_firestore/cloud_firestore.dart';

class OrderLock {
  final String orderId;
  final String lockedBy;
  final DateTime lockedAt;
  final DateTime expiresAt;

  const OrderLock({
    required this.orderId,
    required this.lockedBy,
    required this.lockedAt,
    required this.expiresAt,
  });

  bool isExpired(DateTime now) => now.isAfter(expiresAt);

  Map<String, dynamic> toMap() => {
        'orderId': orderId,
        'lockedBy': lockedBy,
        'lockedAt': Timestamp.fromDate(lockedAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
      };

  factory OrderLock.fromMap(Map<String, dynamic> map) {
    return OrderLock(
      orderId: map['orderId'] as String? ?? '',
      lockedBy: map['lockedBy'] as String? ?? '',
      lockedAt: (map['lockedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class OrderLockService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _locksRef =>
      _db.collection('orderLocks');

  /// Streams order lock status for an order
  Stream<OrderLock?> streamOrderLock(String orderId) {
    return _locksRef.doc(orderId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      final lock = OrderLock.fromMap(snap.data()!);
      if (lock.isExpired(DateTime.now())) return null;
      return lock;
    });
  }

  /// Attempts to acquire lock for processing an order (TTL = 5 mins)
  Future<bool> acquireLock({
    required String orderId,
    required String adminUser,
    int durationMinutes = 5,
  }) async {
    final now = DateTime.now();
    final expiresAt = now.add(Duration(minutes: durationMinutes));
    final doc = await _locksRef.doc(orderId).get();

    if (doc.exists && doc.data() != null) {
      final existingLock = OrderLock.fromMap(doc.data()!);
      if (!existingLock.isExpired(now) && existingLock.lockedBy != adminUser) {
        return false; // Locked by another admin
      }
    }

    final newLock = OrderLock(
      orderId: orderId,
      lockedBy: adminUser,
      lockedAt: now,
      expiresAt: expiresAt,
    );

    await _locksRef.doc(orderId).set(newLock.toMap(), SetOptions(merge: true));
    return true;
  }

  /// Releases lock on an order
  Future<void> releaseLock({
    required String orderId,
    required String adminUser,
  }) async {
    final doc = await _locksRef.doc(orderId).get();
    if (!doc.exists || doc.data() == null) return;
    final existingLock = OrderLock.fromMap(doc.data()!);
    if (existingLock.lockedBy == adminUser) {
      await _locksRef.doc(orderId).delete();
    }
  }
}
