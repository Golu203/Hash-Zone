// ─── AddressService ────────────────────────────────────────────────────────
// Firestore sub-collection: customers/{uid}/addresses/{id}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_profile.dart';

class CustomerAddress2 {
  final String id;
  final String name;
  final String phone;
  final String companyName;
  final String label;
  final String doorNumber;
  final String road;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final String landmark;
  final bool isDefault;

  const CustomerAddress2({
    required this.id,
    this.name = '',
    this.phone = '',
    this.companyName = '',
    this.label = '',
    required this.doorNumber,
    required this.road,
    required this.area,
    required this.city,
    this.state = 'Tamil Nadu',
    this.pincode = '',
    this.landmark = '',
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'companyName': companyName,
        'label': label,
        'doorNumber': doorNumber,
        'road': road,
        'area': area,
        'city': city,
        'state': state,
        'pincode': pincode,
        'landmark': landmark,
        'isDefault': isDefault,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory CustomerAddress2.fromMap(Map<String, dynamic> map) {
    return CustomerAddress2(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      companyName: map['companyName'] as String? ?? '',
      label: map['label'] as String? ?? '',
      doorNumber: map['doorNumber'] as String? ?? '',
      road: map['road'] as String? ?? '',
      area: map['area'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? 'Tamil Nadu',
      pincode: map['pincode'] as String? ?? '',
      landmark: map['landmark'] as String? ?? '',
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  CustomerAddress2 copyWith({
    String? name,
    String? phone,
    String? companyName,
    String? label,
    String? doorNumber,
    String? road,
    String? area,
    String? city,
    String? state,
    String? pincode,
    String? landmark,
    bool? isDefault,
  }) {
    return CustomerAddress2(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      companyName: companyName ?? this.companyName,
      label: label ?? this.label,
      doorNumber: doorNumber ?? this.doorNumber,
      road: road ?? this.road,
      area: area ?? this.area,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      landmark: landmark ?? this.landmark,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Returns a formatted summary line for display.
  String get summary {
    final parts = [
      if (name.isNotEmpty) name,
      if (doorNumber.isNotEmpty) doorNumber,
      if (road.isNotEmpty) road,
      if (area.isNotEmpty) area,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (pincode.isNotEmpty) pincode,
    ];
    return parts.join(', ');
  }
}

class AddressService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _addrRef(String uid) =>
      _db.collection('customers').doc(uid).collection('addresses');

  Stream<List<CustomerAddress2>> streamAddresses(String uid) {
    return _addrRef(uid)
        .orderBy('isDefault', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CustomerAddress2.fromMap(doc.data()))
            .toList());
  }

  Future<List<CustomerAddress2>> getAddresses(String uid) async {
    final snap = await _addrRef(uid).get();
    return snap.docs.map((d) => CustomerAddress2.fromMap(d.data())).toList();
  }

  Future<CustomerAddress2> addAddress(String uid, CustomerAddress2 address) async {
    final existing = await _addrRef(uid).get();
    final isFirst = existing.docs.isEmpty;

    final shouldBeDefault = isFirst ? true : address.isDefault;

    // If marked as default, clear default flag from all other addresses
    if (shouldBeDefault && existing.docs.isNotEmpty) {
      final batch = _db.batch();
      for (final doc in existing.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
      await batch.commit();
    }

    final docRef = _addrRef(uid).doc();
    final newAddr = address.copyWith(isDefault: shouldBeDefault);
    await docRef.set({...newAddr.toMap(), 'id': docRef.id});
    return newAddr;
  }

  Future<void> updateAddress(String uid, CustomerAddress2 address) async {
    if (address.isDefault) {
      final all = await _addrRef(uid).get();
      final batch = _db.batch();
      for (final doc in all.docs) {
        batch.update(doc.reference, {'isDefault': doc.id == address.id});
      }
      await batch.commit();
    }

    await _addrRef(uid).doc(address.id).update(address.toMap());
  }

  Future<void> deleteAddress(String uid, String addressId) async {
    await _addrRef(uid).doc(addressId).delete();
    final remaining = await getAddresses(uid);
    if (remaining.isNotEmpty && !remaining.any((a) => a.isDefault)) {
      await setDefault(uid, remaining.first.id);
    }
  }

  Future<void> setDefault(String uid, String addressId) async {
    final batch = _db.batch();
    final all = await _addrRef(uid).get();
    for (final doc in all.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == addressId});
    }
    await batch.commit();
  }

  // ── Auto Data Migration for Existing Customers ─────────────────────────────
  Future<void> migrateFromProfile(String uid, CustomerAddress onboardingAddress, {String name = '', String phone = ''}) async {
    final existing = await _addrRef(uid).get();
    if (existing.docs.isNotEmpty) {
      // Check if any default exists; if not, promote the first address
      final docs = existing.docs;
      final hasDefault = docs.any((d) => d.data()['isDefault'] == true);
      if (!hasDefault && docs.isNotEmpty) {
        await setDefault(uid, docs.first.id);
      }
      return;
    }

    final addr = CustomerAddress2(
      id: '',
      name: name,
      phone: phone,
      label: 'Default Address',
      doorNumber: onboardingAddress.doorNumber,
      road: onboardingAddress.road,
      area: onboardingAddress.area,
      city: onboardingAddress.city,
      state: 'Tamil Nadu',
      isDefault: true,
    );
    await addAddress(uid, addr);
  }
}
