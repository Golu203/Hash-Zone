import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a reusable bundle template that admin defines once
/// and can be applied to any product.
class BundleOption {
  final String id;
  final String name; // e.g. "Assorted Bundle", "Small-Large Set"
  final List<String> sizes; // e.g. ["S","M","L","XL"]
  final int totalPieces; // e.g. 100
  final int piecesPerSize; // e.g. 25 (each size contributes this many pieces)
  final bool active;
  final DateTime createdAt;

  BundleOption({
    required this.id,
    required this.name,
    required this.sizes,
    required this.totalPieces,
    required this.piecesPerSize,
    this.active = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Human-readable size breakdown summary e.g. "S×25, M×25, L×25, XL×25"
  String get sizesBreakdown {
    if (sizes.isEmpty) return '—';
    return sizes.map((s) => '$s×$piecesPerSize').join(', ');
  }

  /// Short comma-separated size list e.g. "S, M, L, XL"
  String get sizeLabel {
    if (sizes.isEmpty) return '—';
    return sizes.join(', ');
  }

  BundleOption copyWith({
    String? id,
    String? name,
    List<String>? sizes,
    int? totalPieces,
    int? piecesPerSize,
    bool? active,
    DateTime? createdAt,
  }) {
    return BundleOption(
      id: id ?? this.id,
      name: name ?? this.name,
      sizes: sizes ?? this.sizes,
      totalPieces: totalPieces ?? this.totalPieces,
      piecesPerSize: piecesPerSize ?? this.piecesPerSize,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'sizes': sizes,
        'totalPieces': totalPieces,
        'piecesPerSize': piecesPerSize,
        'active': active,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory BundleOption.fromMap(Map<String, dynamic> map, String id) {
    return BundleOption(
      id: id,
      name: map['name'] as String? ?? '',
      sizes: List<String>.from(map['sizes'] as List? ?? []),
      totalPieces: (map['totalPieces'] as num?)?.toInt() ?? 0,
      piecesPerSize: (map['piecesPerSize'] as num?)?.toInt() ?? 0,
      active: map['active'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
