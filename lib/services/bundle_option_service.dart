import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bundle_option.dart';

class BundleOptionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('bundleOptions');

  /// Stream of all active bundle options ordered by name
  Stream<List<BundleOption>> watchAll() {
    return _col.orderBy('createdAt').snapshots().map((snap) {
      return snap.docs
          .map((doc) => BundleOption.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Fetch all bundle options once (active + inactive)
  Future<List<BundleOption>> fetchAll() async {
    final snap = await _col.orderBy('createdAt').get();
    return snap.docs
        .map((doc) => BundleOption.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Fetch only active bundle options (for product edit screen)
  Future<List<BundleOption>> fetchActive() async {
    final snap = await _col
        .where('active', isEqualTo: true)
        .orderBy('createdAt')
        .get();
    return snap.docs
        .map((doc) => BundleOption.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Add a new bundle option
  Future<void> add(BundleOption option) async {
    await _col.add(option.toMap());
  }

  /// Update an existing bundle option
  Future<void> update(BundleOption option) async {
    await _col.doc(option.id).update(option.toMap());
  }

  /// Soft-delete: mark as inactive
  Future<void> deactivate(String id) async {
    await _col.doc(id).update({'active': false});
  }

  /// Permanently delete
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  /// Seed 5 default bundle options — only if the collection is empty.
  /// Safe to call on every app launch from admin; no duplicates.
  Future<void> seedDefaultsIfEmpty() async {
    final snap = await _col.limit(1).get();
    if (snap.docs.isNotEmpty) return; // Already seeded

    final defaults = [
      BundleOption(
        id: '',
        name: 'S-M-L-XL Assorted Bundle',
        sizes: ['S', 'M', 'L', 'XL'],
        totalPieces: 100,
        piecesPerSize: 25,
      ),
      BundleOption(
        id: '',
        name: 'S-M-L Assorted Bundle',
        sizes: ['S', 'M', 'L'],
        totalPieces: 90,
        piecesPerSize: 30,
      ),
      BundleOption(
        id: '',
        name: 'M-L-XL-XXL Assorted Bundle',
        sizes: ['M', 'L', 'XL', 'XXL'],
        totalPieces: 100,
        piecesPerSize: 25,
      ),
      BundleOption(
        id: '',
        name: 'Full Size Run (XS-3XL)',
        sizes: ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'],
        totalPieces: 105,
        piecesPerSize: 15,
      ),
      BundleOption(
        id: '',
        name: 'Mini Bundle (L-XL)',
        sizes: ['L', 'XL'],
        totalPieces: 50,
        piecesPerSize: 25,
      ),
    ];

    final batch = _db.batch();
    for (final d in defaults) {
      batch.set(_col.doc(), d.toMap());
    }
    await batch.commit();
  }
}
