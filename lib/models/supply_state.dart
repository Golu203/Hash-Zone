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
    return SupplyState(
      id: id,
      state: map['state'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      cities: List<String>.from(map['cities'] ?? []),
      active: map['active'] ?? true,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
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
