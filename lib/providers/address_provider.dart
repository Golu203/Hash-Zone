// ─── AddressProvider ─────────────────────────────────────────────────────────
// ChangeNotifier that streams customer addresses from Firestore.

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/address_service.dart';

class AddressProvider extends ChangeNotifier {
  final AddressService _service;

  List<CustomerAddress2> _addresses = [];
  bool _isLoading = false;
  StreamSubscription<List<CustomerAddress2>>? _sub;

  AddressProvider(this._service);

  List<CustomerAddress2> get addresses => _addresses;
  bool get isLoading => _isLoading;
  CustomerAddress2? get defaultAddress =>
      _addresses.isEmpty ? null : _addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => _addresses.first,
      );

  void attachUser(String uid) {
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();
    _sub = _service.streamAddresses(uid).listen((addrs) {
      _addresses = addrs;
      _isLoading = false;
      notifyListeners();
    });
  }

  void detachUser() {
    _sub?.cancel();
    _addresses = [];
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAddress(String uid, CustomerAddress2 address) async {
    await _service.addAddress(uid, address);
  }

  Future<void> updateAddress(String uid, CustomerAddress2 address) async {
    await _service.updateAddress(uid, address);
  }

  Future<void> deleteAddress(String uid, String id) async {
    await _service.deleteAddress(uid, id);
  }

  Future<void> setDefault(String uid, String id) async {
    await _service.setDefault(uid, id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
