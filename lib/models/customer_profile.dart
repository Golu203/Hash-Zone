// ─── CustomerProfile ─────────────────────────────────────────────────────────
// Firestore document: customers/{uid}
// Future-ready for Cart, Orders, Addresses, Documents, Preferences.

import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerAddress {
  final String doorNumber;
  final String road;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final String landmark;

  const CustomerAddress({
    this.doorNumber = '',
    this.road = '',
    this.area = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.landmark = '',
  });

  String get fullAddress {
    final doorStr = doorNumber.trim();
    final roadStr = road.trim();
    final areaStr = area.trim();
    final cityStr = city.trim();
    final stateStr = state.trim();
    final pinStr = pincode.trim();
    var lmStr = landmark.trim();

    if (lmStr.isNotEmpty) {
      lmStr = lmStr.replaceAll(RegExp(r'\bNear\s+Near\b', caseSensitive: false), 'Near').trim();
    }

    final parts = <String>[];
    if (doorStr.isNotEmpty) parts.add(doorStr);
    if (roadStr.isNotEmpty) parts.add(roadStr);
    if (areaStr.isNotEmpty) parts.add(areaStr);
    if (cityStr.isNotEmpty) parts.add(cityStr);

    if (stateStr.isNotEmpty && pinStr.isNotEmpty) {
      parts.add('$stateStr - $pinStr');
    } else {
      if (stateStr.isNotEmpty) parts.add(stateStr);
      if (pinStr.isNotEmpty) parts.add(pinStr);
    }

    if (lmStr.isNotEmpty) {
      if (RegExp(r'^(near|opp|opposite|behind|beside)\b', caseSensitive: false).hasMatch(lmStr)) {
        parts.add(lmStr);
      } else {
        parts.add('Near $lmStr');
      }
    }

    if (parts.isEmpty) return 'No address provided.';
    return parts.join(', ');
  }

  Map<String, dynamic> toMap() => {
        'doorNumber': doorNumber,
        'road': road,
        'area': area,
        'city': city,
        'state': state,
        'pincode': pincode,
        'landmark': landmark,
      };

  factory CustomerAddress.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const CustomerAddress();
    return CustomerAddress(
      doorNumber: map['doorNumber'] as String? ??
          map['doorNo'] as String? ??
          map['flatNo'] as String? ??
          map['houseNo'] as String? ??
          '',
      road: map['road'] as String? ??
          map['street'] as String? ??
          map['addressLine1'] as String? ??
          '',
      area: map['area'] as String? ??
          map['locality'] as String? ??
          map['addressLine2'] as String? ??
          '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      pincode: map['pincode'] as String? ??
          map['zipCode'] as String? ??
          map['postalCode'] as String? ??
          map['pin'] as String? ??
          '',
      landmark: map['landmark'] as String? ?? '',
    );
  }
}

class CustomerProfile {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String phoneNumber;
  final String whatsAppNumber;
  final String companyName;
  final CustomerAddress address;
  final bool onboardingComplete;
  final String authProvider; // 'email' | 'google'
  final String accountStatus; // 'active' | 'suspended'
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;

  const CustomerProfile({
    required this.uid,
    this.email = '',
    this.displayName = '',
    this.photoUrl = '',
    this.phoneNumber = '',
    this.whatsAppNumber = '',
    this.companyName = '',
    this.address = const CustomerAddress(),
    this.onboardingComplete = false,
    this.authProvider = 'email',
    this.accountStatus = 'active',
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'phoneNumber': phoneNumber,
        'whatsAppNumber': whatsAppNumber,
        'companyName': companyName,
        'address': address.toMap(),
        'onboardingComplete': onboardingComplete,
        'authProvider': authProvider,
        'accountStatus': accountStatus,
        'isDeleted': isDeleted,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      };

  factory CustomerProfile.fromMap(Map<String, dynamic> map) {
    return CustomerProfile(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      whatsAppNumber: map['whatsAppNumber'] as String? ?? '',
      companyName: map['companyName'] as String? ?? '',
      address: CustomerAddress.fromMap(map['address'] as Map<String, dynamic>?),
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      authProvider: map['authProvider'] as String? ?? 'email',
      accountStatus: map['accountStatus'] as String? ?? 'active',
      isDeleted: map['isDeleted'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      lastLogin: (map['lastLogin'] as Timestamp?)?.toDate(),
    );
  }

  CustomerProfile copyWith({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? whatsAppNumber,
    String? companyName,
    CustomerAddress? address,
    bool? onboardingComplete,
    String? accountStatus,
  }) {
    return CustomerProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      whatsAppNumber: whatsAppNumber ?? this.whatsAppNumber,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      authProvider: authProvider,
      accountStatus: accountStatus ?? this.accountStatus,
      isDeleted: isDeleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastLogin: lastLogin,
    );
  }
}
