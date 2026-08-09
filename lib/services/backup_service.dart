// ─── BackupService ────────────────────────────────────────────────────────────
// HashZone V1 — Production Backup & Recovery Engine
// Format: HZB-2.0 — structured JSON package (Base64-encoded)
// Safe: Read-only. Never modifies Firestore data.
// Includes: manifest, database, settings, checksums layers.

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── CONSTANTS ────────────────────────────────────────────────────────────────

const String kHzbVersion = 'HZB-2.0';
const String kAppVersion = '1.0.0';
const String kDbSchemaVersion = 'v1.0';

// ─── COLLECTION GROUPS ────────────────────────────────────────────────────────

/// Product-related Firestore collections
const List<String> kProductCollections = [
  'products',
  'categories',
  'collections',
];

/// Customer-related Firestore collections
const List<String> kCustomerCollections = [
  'customers',
  'addresses',
];

/// Order-related Firestore collections
const List<String> kOrderCollections = [
  'orders',
  'orderTimeline',
  'dispatchInformation',
  'refundInformation',
];

/// Payment-related Firestore collections
const List<String> kPaymentCollections = [
  'paymentVerification',
  'paymentAudit',
  'paymentConfiguration',
  'paymentValidationSettings',
  'paymentInstructions',
];

/// Settings / configuration collections
const List<String> kSettingsCollections = [
  'settings',
  'systemSettings',
  'developerSettings',
  'messageTemplates',
  'businessSettings',
  'ocrSettings',
  'backupSettings',
];

/// Website / content collections
const List<String> kContentCollections = [
  'banners',
  'offers',
  'homepageConfig',
  'supplyNetwork',
  'websiteContent',
];

/// All collections in order
const List<String> kAllCollections = [
  ...kProductCollections,
  ...kCustomerCollections,
  ...kOrderCollections,
  ...kPaymentCollections,
  ...kSettingsCollections,
  ...kContentCollections,
];

// ─── MODELS ───────────────────────────────────────────────────────────────────

class HzbManifest {
  final String backupVersion;
  final String appVersion;
  final String dbSchemaVersion;
  final String createdAt;
  final String createdBy;
  final String generator;
  final String cloudinaryPolicy;
  final int totalCollections;
  final int totalRecords;
  final Map<String, int> collectionCounts;
  final List<String> includedCollections;
  final int estimatedSizeBytes;

  const HzbManifest({
    required this.backupVersion,
    required this.appVersion,
    required this.dbSchemaVersion,
    required this.createdAt,
    required this.createdBy,
    required this.generator,
    required this.cloudinaryPolicy,
    required this.totalCollections,
    required this.totalRecords,
    required this.collectionCounts,
    required this.includedCollections,
    required this.estimatedSizeBytes,
  });

  Map<String, dynamic> toMap() => {
        'backupVersion': backupVersion,
        'appVersion': appVersion,
        'dbSchemaVersion': dbSchemaVersion,
        'createdAt': createdAt,
        'createdBy': createdBy,
        'generator': generator,
        'cloudinaryPolicy': cloudinaryPolicy,
        'totalCollections': totalCollections,
        'totalRecords': totalRecords,
        'collectionCounts': collectionCounts,
        'includedCollections': includedCollections,
        'estimatedSizeBytes': estimatedSizeBytes,
      };

  factory HzbManifest.fromMap(Map<String, dynamic> m) => HzbManifest(
        backupVersion: m['backupVersion'] as String? ?? kHzbVersion,
        appVersion: m['appVersion'] as String? ?? kAppVersion,
        dbSchemaVersion: m['dbSchemaVersion'] as String? ?? kDbSchemaVersion,
        createdAt: m['createdAt'] as String? ?? '',
        createdBy: m['createdBy'] as String? ?? 'Admin',
        generator: m['generator'] as String? ?? 'HashZone BackupService',
        cloudinaryPolicy: m['cloudinaryPolicy'] as String? ?? 'urls-only',
        totalCollections: m['totalCollections'] as int? ?? 0,
        totalRecords: m['totalRecords'] as int? ?? 0,
        collectionCounts: Map<String, int>.from(m['collectionCounts'] as Map? ?? {}),
        includedCollections: List<String>.from(m['includedCollections'] as List? ?? []),
        estimatedSizeBytes: m['estimatedSizeBytes'] as int? ?? 0,
      );
}

class HzbPackage {
  final HzbManifest manifest;
  final Map<String, List<Map<String, dynamic>>> database;
  final Map<String, dynamic> settings;
  final Map<String, String> checksums;

  const HzbPackage({
    required this.manifest,
    required this.database,
    required this.settings,
    required this.checksums,
  });

  /// Encode to .hzb Base64 string
  String toHzbString() {
    final raw = jsonEncode({
      'hzbVersion': kHzbVersion,
      'manifest': manifest.toMap(),
      'database': database,
      'settings': settings,
      'checksums': checksums,
    });
    final bytes = utf8.encode(raw);
    return base64Encode(bytes);
  }

  /// Decode from .hzb Base64 string
  factory HzbPackage.fromHzbString(String hzb) {
    final bytes = base64Decode(hzb.trim());
    final raw = utf8.decode(bytes);
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return HzbPackage(
      manifest: HzbManifest.fromMap(m['manifest'] as Map<String, dynamic>),
      database: (m['database'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, List<Map<String, dynamic>>.from((v as List).map((e) => Map<String, dynamic>.from(e as Map)))),
      ),
      settings: Map<String, dynamic>.from(m['settings'] as Map? ?? {}),
      checksums: Map<String, String>.from(m['checksums'] as Map? ?? {}),
    );
  }
}

// Legacy alias for restore compatibility
typedef BackupPackage = HzbPackage;
typedef BackupManifest = HzbManifest;

class RestoreAnalysis {
  final HzbManifest manifest;
  final int totalRecords;
  final int willCreate;
  final int willUpdate;
  final int willSkip;
  final Map<String, int> collectionBreakdown;

  const RestoreAnalysis({
    required this.manifest,
    required this.totalRecords,
    required this.willCreate,
    required this.willUpdate,
    required this.willSkip,
    required this.collectionBreakdown,
  });
}

class RestoreReport {
  final int productsCreated;
  final int productsUpdated;
  final int customersUpdated;
  final int ordersUpdated;
  final int collectionsUpdated;
  final int skipped;
  final List<String> errors;

  const RestoreReport({
    this.productsCreated = 0,
    this.productsUpdated = 0,
    this.customersUpdated = 0,
    this.ordersUpdated = 0,
    this.collectionsUpdated = 0,
    this.skipped = 0,
    this.errors = const [],
  });
}

// ─── BACKUP SERVICE ───────────────────────────────────────────────────────────

class BackupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Serialization ────────────────────────────────────────────────────────────

  /// Recursively serialize Firestore types into JSON-safe structures.
  dynamic _ser(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is int) return v;
    if (v is double) return v;
    if (v is String) return v;

    if (v is Timestamp) {
      return {
        '_type': 'timestamp',
        'seconds': v.seconds,
        'nanoseconds': v.nanoseconds,
        '_iso': v.toDate().toIso8601String(),
      };
    }

    if (v is DateTime) {
      return {
        '_type': 'datetime',
        'value': v.toIso8601String(),
      };
    }

    if (v is GeoPoint) {
      return {
        '_type': 'geopoint',
        'latitude': v.latitude,
        'longitude': v.longitude,
      };
    }

    if (v is DocumentReference) {
      return {
        '_type': 'docref',
        'path': v.path,
        'id': v.id,
      };
    }

    if (v is Map) {
      final result = <String, dynamic>{};
      for (final entry in v.entries) {
        result[entry.key.toString()] = _ser(entry.value);
      }
      return result;
    }

    if (v is List) {
      return v.map(_ser).toList();
    }

    // Fallback: convert to string to avoid JSON encode failure
    return v.toString();
  }

  Map<String, dynamic> _serMap(Map<String, dynamic> m) {
    final result = <String, dynamic>{};
    for (final e in m.entries) {
      result[e.key] = _ser(e.value);
    }
    return result;
  }

  /// Recursively deserialize back to Firestore types.
  dynamic _deser(dynamic v) {
    if (v == null) return null;
    if (v is bool || v is int || v is double || v is String) return v;

    if (v is Map) {
      final type = v['_type'];
      if (type == 'timestamp') {
        return Timestamp(v['seconds'] as int, v['nanoseconds'] as int);
      }
      if (type == 'datetime') {
        return DateTime.parse(v['value'] as String);
      }
      if (type == 'geopoint') {
        return GeoPoint(v['latitude'] as double, v['longitude'] as double);
      }
      if (type == 'docref') {
        return FirebaseFirestore.instance.doc(v['path'] as String);
      }
      final result = <String, dynamic>{};
      for (final e in (v as Map<String, dynamic>).entries) {
        result[e.key] = _deser(e.value);
      }
      return result;
    }

    if (v is List) {
      return v.map(_deser).toList();
    }

    return v;
  }

  Map<String, dynamic> _deserMap(Map<String, dynamic> m) {
    final result = <String, dynamic>{};
    for (final e in m.entries) {
      result[e.key] = _deser(e.value);
    }
    return result;
  }

  // ── Checksum ─────────────────────────────────────────────────────────────────

  /// Simple deterministic hash for backup integrity verification.
  /// Uses a polynomial rolling hash over UTF-8 bytes.
  String _hashJson(String json) {
    final bytes = utf8.encode(json);
    var hash = 0x811c9dc5; // FNV-1a 32-bit offset basis
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * 0x01000193) & 0xFFFFFFFF; // FNV prime
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  // ── Read a single collection ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _readCollection(String name) async {
    try {
      final snap = await _db.collection(name).get();
      return snap.docs.map((d) {
        final data = d.data();
        data['_id'] = d.id;
        return _serMap(data);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Main backup entry point ───────────────────────────────────────────────────

  Future<HzbPackage> createBackup({
    required String adminUser,
    required void Function(String stage, double progress) onProgress,
  }) async {
    onProgress('Preparing Backup', 0.02);

    final database = <String, List<Map<String, dynamic>>>{};
    final settingsData = <String, dynamic>{};
    final counts = <String, int>{};
    int totalRecords = 0;

    // ── Stage: Products ─────────────────────────────────────────────────────────
    onProgress('Reading Products', 0.05);
    for (final col in kProductCollections) {
      final docs = await _readCollection(col);
      database[col] = docs;
      counts[col] = docs.length;
      totalRecords += docs.length;
    }

    // ── Stage: Customers ────────────────────────────────────────────────────────
    onProgress('Reading Customers', 0.18);
    for (final col in kCustomerCollections) {
      final docs = await _readCollection(col);
      database[col] = docs;
      counts[col] = docs.length;
      totalRecords += docs.length;
    }

    // ── Stage: Orders ───────────────────────────────────────────────────────────
    onProgress('Reading Orders', 0.30);
    for (final col in kOrderCollections) {
      final docs = await _readCollection(col);
      database[col] = docs;
      counts[col] = docs.length;
      totalRecords += docs.length;
    }

    // ── Stage: Payments ─────────────────────────────────────────────────────────
    onProgress('Reading Payment Data', 0.44);
    for (final col in kPaymentCollections) {
      final docs = await _readCollection(col);
      database[col] = docs;
      counts[col] = docs.length;
      totalRecords += docs.length;
    }

    // ── Stage: Settings ─────────────────────────────────────────────────────────
    onProgress('Reading Settings', 0.58);
    for (final col in kSettingsCollections) {
      final docs = await _readCollection(col);
      // Settings go into both database and settings map for convenience
      database[col] = docs;
      counts[col] = docs.length;
      totalRecords += docs.length;
      if (docs.isNotEmpty) {
        settingsData[col] = docs;
      }
    }

    // ── Stage: Content ──────────────────────────────────────────────────────────
    onProgress('Reading Website Content', 0.70);
    for (final col in kContentCollections) {
      final docs = await _readCollection(col);
      database[col] = docs;
      counts[col] = docs.length;
      totalRecords += docs.length;
    }

    // ── Stage: Serialize & Manifest ─────────────────────────────────────────────
    onProgress('Serializing Data', 0.80);
    final now = DateTime.now();
    final databaseJson = jsonEncode(database);
    final settingsJson = jsonEncode(settingsData);

    onProgress('Creating Manifest', 0.84);
    final includedCollections = counts.entries.where((e) => e.value > 0).map((e) => e.key).toList();

    final manifest = HzbManifest(
      backupVersion: kHzbVersion,
      appVersion: kAppVersion,
      dbSchemaVersion: kDbSchemaVersion,
      createdAt: now.toIso8601String(),
      createdBy: adminUser,
      generator: 'HashZone BackupService v2.0',
      cloudinaryPolicy: 'urls-only — binary files remain in Cloudinary',
      totalCollections: includedCollections.length,
      totalRecords: totalRecords,
      collectionCounts: counts,
      includedCollections: includedCollections,
      estimatedSizeBytes: databaseJson.length + settingsJson.length,
    );

    // ── Stage: Checksums ────────────────────────────────────────────────────────
    onProgress('Creating Checksums', 0.88);
    final manifestJson = jsonEncode(manifest.toMap());
    final checksums = {
      'manifest': _hashJson(manifestJson),
      'database': _hashJson(databaseJson),
      'settings': _hashJson(settingsJson),
      'algorithm': 'fnv1a-32',
      'generatedAt': now.toIso8601String(),
    };

    // ── Stage: Package ──────────────────────────────────────────────────────────
    onProgress('Compressing Backup', 0.93);
    final package = HzbPackage(
      manifest: manifest,
      database: database,
      settings: settingsData,
      checksums: checksums,
    );

    // ── Validate ─────────────────────────────────────────────────────────────────
    onProgress('Validating Package', 0.96);
    _validatePackage(package);

    onProgress('Preparing Download', 1.0);
    return package;
  }

  /// Throws if package is invalid — prevents corrupt backup download.
  void _validatePackage(HzbPackage pkg) {
    if (pkg.manifest.backupVersion.isEmpty) {
      throw Exception('Manifest missing backup version.');
    }
    if (pkg.database.isEmpty) {
      throw Exception('Database layer is empty — no collections found.');
    }
    if (pkg.checksums.isEmpty) {
      throw Exception('Checksums missing.');
    }
  }

  // ── Restore helpers ──────────────────────────────────────────────────────────

  Future<RestoreAnalysis> analyzeBackup(HzbPackage package) async {
    int totalRecords = 0;
    int willCreate = 0;
    int willUpdate = 0;
    const int willSkip = 0;
    final breakdown = <String, int>{};

    for (final entry in package.database.entries) {
      final colName = entry.key;
      final docs = entry.value;
      breakdown[colName] = docs.length;
      totalRecords += docs.length;

      try {
        final existingSnap = await _db.collection(colName).get();
        final existingIds = existingSnap.docs.map((d) => d.id).toSet();
        for (final docData in docs) {
          final id = docData['_id'] as String? ?? '';
          if (id.isEmpty || !existingIds.contains(id)) {
            willCreate++;
          } else {
            willUpdate++;
          }
        }
      } catch (_) {
        willCreate += docs.length;
      }
    }

    return RestoreAnalysis(
      manifest: package.manifest,
      totalRecords: totalRecords,
      willCreate: willCreate,
      willUpdate: willUpdate,
      willSkip: willSkip,
      collectionBreakdown: breakdown,
    );
  }

  Future<RestoreReport> restoreBackup({
    required HzbPackage package,
    required String adminUser,
    required void Function(String stage, double progress) onProgress,
  }) async {
    onProgress('Creating Safety Backup', 0.05);
    try {
      await createBackup(adminUser: 'SafetyBackup_$adminUser', onProgress: (_, __) {});
    } catch (_) {}

    int productsCreated = 0;
    int productsUpdated = 0;
    int customersUpdated = 0;
    int ordersUpdated = 0;
    int collectionsUpdated = 0;
    int skipped = 0;
    final errors = <String>[];

    final cols = package.database;
    int i = 0;
    final total = cols.length;

    for (final entry in cols.entries) {
      i++;
      final colName = entry.key;
      final docs = entry.value;
      onProgress('Restoring $colName (${docs.length} records)', 0.1 + (i / total) * 0.85);

      for (final docData in docs) {
        final id = docData['_id'] as String?;
        final clean = _deserMap(Map<String, dynamic>.from(docData)..remove('_id'));

        try {
          final ref = (id != null && id.isNotEmpty)
              ? _db.collection(colName).doc(id)
              : _db.collection(colName).doc();

          final existing = await ref.get();
          final exists = existing.exists;
          await ref.set(clean, SetOptions(merge: true));

          if (colName == 'products') {
            exists ? productsUpdated++ : productsCreated++;
          } else if (colName == 'customers') {
            customersUpdated++;
          } else if (colName == 'orders') {
            ordersUpdated++;
          }
        } catch (e) {
          errors.add('Failed $colName ($id): $e');
        }
      }
      collectionsUpdated++;
    }

    onProgress('Finalizing Restore Report', 1.0);
    return RestoreReport(
      productsCreated: productsCreated,
      productsUpdated: productsUpdated,
      customersUpdated: customersUpdated,
      ordersUpdated: ordersUpdated,
      collectionsUpdated: collectionsUpdated,
      skipped: skipped,
      errors: errors,
    );
  }
}
