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
  final String businessIdType; // 'GST' | 'PAN'
  final String businessIdValue; // The GST or PAN number
  final CustomerAddress address;
  final bool onboardingComplete;
  final String authProvider; // 'email' | 'google'
  final String accountStatus; // 'active' | 'suspended'
  final bool isDeleted;
  final bool termsAccepted;
  final bool privacyAccepted;
  final DateTime? termsAcceptedAt;
  final DateTime? privacyAcceptedAt;
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
    this.businessIdType = 'GST',
    this.businessIdValue = '',
    this.address = const CustomerAddress(),
    this.onboardingComplete = false,
    this.authProvider = 'email',
    this.accountStatus = 'active',
    this.isDeleted = false,
    this.termsAccepted = false,
    this.privacyAccepted = false,
    this.termsAcceptedAt,
    this.privacyAcceptedAt,
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
        'businessIdType': businessIdType,
        'businessIdValue': businessIdValue,
        'contactDetails': {
          'phoneNumber': phoneNumber,
          'businessIdType': businessIdType,
          'businessIdValue': businessIdValue,
        },
        'address': address.toMap(),
        'onboardingComplete': onboardingComplete,
        'authProvider': authProvider,
        'accountStatus': accountStatus,
        'isDeleted': isDeleted,
        'termsAccepted': termsAccepted,
        'privacyAccepted': privacyAccepted,
        'termsAcceptedAt': termsAcceptedAt != null
            ? Timestamp.fromDate(termsAcceptedAt!)
            : (termsAccepted ? FieldValue.serverTimestamp() : null),
        'privacyAcceptedAt': privacyAcceptedAt != null
            ? Timestamp.fromDate(privacyAcceptedAt!)
            : (privacyAccepted ? FieldValue.serverTimestamp() : null),
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      };

  factory CustomerProfile.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    final rawContact = map['contactDetails'] as Map<String, dynamic>?;

    return CustomerProfile(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? (rawContact?['phoneNumber'] as String?) ?? '',
      whatsAppNumber: map['whatsAppNumber'] as String? ?? '',
      companyName: map['companyName'] as String? ?? '',
      businessIdType: map['businessIdType'] as String? ?? (rawContact?['businessIdType'] as String?) ?? 'GST',
      businessIdValue: map['businessIdValue'] as String? ?? (rawContact?['businessIdValue'] as String?) ?? '',
      address: CustomerAddress.fromMap(map['address'] as Map<String, dynamic>?),
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      authProvider: map['authProvider'] as String? ?? 'email',
      accountStatus: map['accountStatus'] as String? ?? 'active',
      isDeleted: map['isDeleted'] as bool? ?? false,
      termsAccepted: map['termsAccepted'] as bool? ?? false,
      privacyAccepted: map['privacyAccepted'] as bool? ?? false,
      termsAcceptedAt: parseDate(map['termsAcceptedAt']),
      privacyAcceptedAt: parseDate(map['privacyAcceptedAt']),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      lastLogin: parseDate(map['lastLogin']),
    );
  }

  CustomerProfile copyWith({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? whatsAppNumber,
    String? companyName,
    String? businessIdType,
    String? businessIdValue,
    CustomerAddress? address,
    bool? onboardingComplete,
    String? accountStatus,
    bool? termsAccepted,
    bool? privacyAccepted,
    DateTime? termsAcceptedAt,
    DateTime? privacyAcceptedAt,
  }) {
    return CustomerProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      whatsAppNumber: whatsAppNumber ?? this.whatsAppNumber,
      companyName: companyName ?? this.companyName,
      businessIdType: businessIdType ?? this.businessIdType,
      businessIdValue: businessIdValue ?? this.businessIdValue,
      address: address ?? this.address,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      authProvider: authProvider,
      accountStatus: accountStatus ?? this.accountStatus,
      isDeleted: isDeleted,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      privacyAccepted: privacyAccepted ?? this.privacyAccepted,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
      privacyAcceptedAt: privacyAcceptedAt ?? this.privacyAcceptedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastLogin: lastLogin,
    );
  }
}
