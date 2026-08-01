import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/supply_state.dart';
import '../services/firestore_service.dart';

class SupplyNetworkProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  List<SupplyState> _states = [];
  StreamSubscription<List<SupplyState>>? _sub;
  bool _isLoading = true;

  List<SupplyState> get states => _states;
  List<SupplyState> get activeStates => _states.where((s) => s.active).toList();
  bool get isLoading => _isLoading;

  SupplyNetworkProvider(this._firestoreService) {
    _initStream();
  }

  void _initStream() {
    _sub = _firestoreService.streamSupplyNetwork().listen((newList) {
      _states = newList;
      _states.sort((a, b) => a.state.compareTo(b.state));
      _isLoading = false;
      notifyListeners();
    });
  }

  // Predefined geographic centers for Indian States & UTs (as robust fallback)
  static const Map<String, Map<String, double>> fallbackCoordinates = {
    'Andhra Pradesh': {'latitude': 15.9129, 'longitude': 79.7400},
    'Arunachal Pradesh': {'latitude': 28.2180, 'longitude': 94.7278},
    'Assam': {'latitude': 26.2006, 'longitude': 92.9376},
    'Bihar': {'latitude': 25.0961, 'longitude': 85.3131},
    'Chhattisgarh': {'latitude': 21.2787, 'longitude': 81.8661},
    'Goa': {'latitude': 15.2993, 'longitude': 74.1240},
    'Gujarat': {'latitude': 22.2587, 'longitude': 71.1924},
    'Haryana': {'latitude': 29.0588, 'longitude': 76.0856},
    'Himachal Pradesh': {'latitude': 31.1048, 'longitude': 77.1734},
    'Jharkhand': {'latitude': 23.6102, 'longitude': 85.2799},
    'Karnataka': {'latitude': 15.3173, 'longitude': 75.7139},
    'Kerala': {'latitude': 10.8505, 'longitude': 76.2711},
    'Madhya Pradesh': {'latitude': 22.9734, 'longitude': 78.6569},
    'Maharashtra': {'latitude': 19.7515, 'longitude': 75.7139},
    'Manipur': {'latitude': 24.6637, 'longitude': 93.9063},
    'Meghalaya': {'latitude': 25.4670, 'longitude': 91.3662},
    'Mizoram': {'latitude': 23.1645, 'longitude': 92.9376},
    'Nagaland': {'latitude': 26.1584, 'longitude': 94.5624},
    'Odisha': {'latitude': 20.9517, 'longitude': 85.0985},
    'Punjab': {'latitude': 31.1471, 'longitude': 75.3412},
    'Rajasthan': {'latitude': 27.0238, 'longitude': 74.2179},
    'Sikkim': {'latitude': 27.5330, 'longitude': 88.5122},
    'Tamil Nadu': {'latitude': 11.1271, 'longitude': 78.6569},
    'Telangana': {'latitude': 18.1124, 'longitude': 79.0193},
    'Tripura': {'latitude': 23.9408, 'longitude': 91.9882},
    'Uttar Pradesh': {'latitude': 26.8467, 'longitude': 80.9462},
    'Uttarakhand': {'latitude': 30.0668, 'longitude': 79.0193},
    'West Bengal': {'latitude': 22.9868, 'longitude': 87.8550},
    'Andaman and Nicobar Islands': {'latitude': 11.7401, 'longitude': 92.6586},
    'Chandigarh': {'latitude': 30.7333, 'longitude': 76.7794},
    'Dadra and Nagar Haveli and Daman and Diu': {'latitude': 20.1809, 'longitude': 73.0169},
    'Delhi': {'latitude': 28.7041, 'longitude': 77.1025},
    'Jammu and Kashmir': {'latitude': 33.7782, 'longitude': 76.5762},
    'Ladakh': {'latitude': 34.1526, 'longitude': 77.5771},
    'Lakshadweep': {'latitude': 10.5667, 'longitude': 72.6417},
    'Puducherry': {'latitude': 11.9416, 'longitude': 79.8083}
  };

  // geocodes a state name via OSM Nominatim with hardcoded fallbacks
  Future<Map<String, double>> _geocodeState(String stateName) async {
    try {
      final query = Uri.encodeComponent('$stateName, India');
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
      final response = await http.get(url, headers: {
        'User-Agent': 'Hashzone-App',
      }).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        if (results.isNotEmpty) {
          final double lat = double.parse(results[0]['lat']);
          final double lon = double.parse(results[0]['lon']);
          return {'latitude': lat, 'longitude': lon};
        }
      }
    } catch (_) {
      // Fallback to static mapping below
    }

    final fallback = fallbackCoordinates[stateName];
    if (fallback != null) {
      return fallback;
    }
    return {'latitude': 20.5937, 'longitude': 78.9629}; // Center of India fallback
  }

  // Adds a city to a state. Creates state document if missing.
  // Throws Exception if city name already exists.
  Future<void> addLocation(String stateName, String cityName) async {
    final cleanCityName = cityName.trim();

    // Find if the state already exists
    final existing = _states.firstWhere(
      (s) => s.state.toLowerCase() == stateName.toLowerCase(),
      orElse: () => SupplyState(id: '', state: stateName, latitude: 0, longitude: 0, cities: []),
    );

    final List<String> updatedCities = List<String>.from(existing.cities);
    if (cleanCityName.isNotEmpty) {
      // Duplicate city check (case-insensitive)
      final isDuplicate = existing.cities.any(
        (c) => c.toLowerCase() == cleanCityName.toLowerCase(),
      );
      if (isDuplicate) {
        throw Exception('This city already exists.');
      }
      updatedCities.add(cleanCityName);
    }

    if (existing.id.isEmpty) {
      // Create new state
      final coords = await _geocodeState(stateName);
      final newState = SupplyState(
        id: '',
        state: stateName,
        latitude: coords['latitude']!,
        longitude: coords['longitude']!,
        cities: updatedCities,
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestoreService.saveSupplyState(newState);
    } else {
      // Update existing state (only if a new city was actually provided)
      if (cleanCityName.isNotEmpty) {
        final updatedState = SupplyState(
          id: existing.id,
          state: existing.state,
          latitude: existing.latitude,
          longitude: existing.longitude,
          cities: updatedCities,
          active: existing.active,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now(),
        );
        await _firestoreService.saveSupplyState(updatedState);
      }
    }
  }

  // Adds a city name to an existing state.
  // Throws Exception if the new name exists as a duplicate.
  Future<void> addCity(SupplyState state, String cityName) async {
    final cleanCityName = cityName.trim();
    if (cleanCityName.isEmpty) throw Exception('City name cannot be empty');

    final isDuplicate = state.cities.any(
      (c) => c.toLowerCase() == cleanCityName.toLowerCase(),
    );
    if (isDuplicate) {
      throw Exception('This city already exists.');
    }

    final updatedCities = List<String>.from(state.cities)..add(cleanCityName);

    final updatedState = SupplyState(
      id: state.id,
      state: state.state,
      latitude: state.latitude,
      longitude: state.longitude,
      cities: updatedCities,
      active: state.active,
      createdAt: state.createdAt,
      updatedAt: DateTime.now(),
    );

    await _firestoreService.saveSupplyState(updatedState);
  }

  // Edits a city name.
  // Throws Exception if the new name exists as a duplicate.
  Future<void> editCity(SupplyState state, String oldCityName, String newCityName) async {
    final cleanNewCity = newCityName.trim();
    if (cleanNewCity.isEmpty) throw Exception('City name cannot be empty');

    if (oldCityName.toLowerCase() != cleanNewCity.toLowerCase()) {
      final isDuplicate = state.cities.any(
        (c) => c.toLowerCase() == cleanNewCity.toLowerCase(),
      );
      if (isDuplicate) {
        throw Exception('This city already exists.');
      }
    }

    final updatedCities = state.cities.map((c) {
      return c.toLowerCase() == oldCityName.toLowerCase() ? cleanNewCity : c;
    }).toList();

    final updatedState = SupplyState(
      id: state.id,
      state: state.state,
      latitude: state.latitude,
      longitude: state.longitude,
      cities: updatedCities,
      active: state.active,
      createdAt: state.createdAt,
      updatedAt: DateTime.now(),
    );

    await _firestoreService.saveSupplyState(updatedState);
  }

  // Deletes a city.
  Future<void> deleteCity(SupplyState state, String cityName) async {
    final updatedCities = state.cities.where(
      (c) => c.toLowerCase() != cityName.toLowerCase(),
    ).toList();

    if (updatedCities.isEmpty) {
      // If no cities left in the state, delete the state document entirely
      await deleteState(state.id);
    } else {
      final updatedState = SupplyState(
        id: state.id,
        state: state.state,
        latitude: state.latitude,
        longitude: state.longitude,
        cities: updatedCities,
        active: state.active,
        createdAt: state.createdAt,
        updatedAt: DateTime.now(),
      );
      await _firestoreService.saveSupplyState(updatedState);
    }
  }

  // Deletes a state document entirely.
  Future<void> deleteState(String stateId) async {
    await _firestoreService.deleteSupplyState(stateId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
