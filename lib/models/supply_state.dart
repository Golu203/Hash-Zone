import 'package:cloud_firestore/cloud_firestore.dart';

class SupplyState {
  final String id;
  final String state;
  final double latitude;
  final double longitude;
  final List<String> cities;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SupplyState({
    required this.id,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.cities,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  factory SupplyState.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    return SupplyState(
      id: id,
      state: map['state']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      cities: map['cities'] != null
          ? List<String>.from((map['cities'] as List).map((e) => e.toString()))
          : [],
      active: map['active'] as bool? ?? true,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'cities': cities,
      'active': active,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}
