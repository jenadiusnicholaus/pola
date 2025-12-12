import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/nearby_lawyer_model.dart';
import '../services/nearby_lawyers_service.dart';

class NearbyLawyersController extends GetxController {
  final NearbyLawyersService _service = Get.find<NearbyLawyersService>();

  final _lawyers = <NearbyLawyer>[].obs;
  final _isLoading = false.obs;
  final _error = Rx<String?>(null);
  final _radius = 20.0.obs;
  final _selectedTypes =
      <String>['advocate', 'lawyer', 'paralegal', 'law_firm'].obs;
  final _userLocation = Rx<UserLocation?>(null);

  List<NearbyLawyer> get lawyers => _lawyers;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  double get radius => _radius.value;
  List<String> get selectedTypes => _selectedTypes;
  UserLocation? get userLocation => _userLocation.value;
  int get count => _lawyers.length;

  @override
  void onInit() {
    super.onInit();
    fetchNearbyLawyers();
  }

  /// Fetch nearby lawyers
  Future<void> fetchNearbyLawyers() async {
    try {
      _isLoading.value = true;
      _error.value = null;

      final typesString = _selectedTypes.join(',');

      final response = await _service.fetchNearbyLawyers(
        radius: _radius.value,
        types: typesString,
        limit: 100,
      );

      if (response != null) {
        _lawyers.value = response.results;
        _userLocation.value = response.yourLocation;

        if (response.count == 0) {
          _error.value = 'No lawyers found within ${_radius.value}km radius';
        }
      } else {
        _error.value = 'Failed to load nearby lawyers';
      }
    } catch (e) {
      _error.value = 'Error: $e';
      debugPrint('❌ Error in fetchNearbyLawyers: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update radius and refresh
  void updateRadius(double newRadius) {
    _radius.value = newRadius;
    fetchNearbyLawyers();
  }

  /// Toggle user type filter
  void toggleUserType(String type) {
    if (_selectedTypes.contains(type)) {
      if (_selectedTypes.length > 1) {
        // Don't allow removing all types
        _selectedTypes.remove(type);
        fetchNearbyLawyers();
      }
    } else {
      _selectedTypes.add(type);
      fetchNearbyLawyers();
    }
  }

  /// Filter lawyers by specialization
  List<NearbyLawyer> filterBySpecialization(String specialization) {
    return _lawyers
        .where((lawyer) =>
            lawyer.specialization
                ?.toLowerCase()
                .contains(specialization.toLowerCase()) ??
            false)
        .toList();
  }

  /// Get closest lawyer
  NearbyLawyer? getClosestLawyer() {
    if (_lawyers.isEmpty) return null;
    return _lawyers.reduce((a, b) => a.distanceKm < b.distanceKm ? a : b);
  }

  /// Refresh data
  Future<void> refresh() async {
    await fetchNearbyLawyers();
  }
}
