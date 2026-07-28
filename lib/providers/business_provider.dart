import 'dart:async';
import 'package:flutter/material.dart';
import '../models/business_settings.dart';
import '../services/firestore_service.dart';

class BusinessProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  BusinessSettings _settings = BusinessSettings();
  StreamSubscription<BusinessSettings>? _sub;

  BusinessSettings get settings => _settings;

  BusinessProvider(this._firestoreService) {
    _initStream();
  }

  void _initStream() {
    _sub = _firestoreService.streamBusinessSettings().listen((newSettings) {
      _settings = newSettings;
      notifyListeners();
    });
  }

  Future<void> updateSettings(BusinessSettings newSettings) async {
    await _firestoreService.saveBusinessSettings(newSettings);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
