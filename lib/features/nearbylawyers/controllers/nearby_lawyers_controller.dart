import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../models/nearby_lawyer_model.dart';
import '../services/nearby_lawyers_service.dart';
import '../../../services/location_service.dart';

class NearbyLawyersController extends GetxController {
  final NearbyLawyersService _service = Get.find<NearbyLawyersService>();

  final List<NearbyLawyer> _lawyers = [];
  final _isLoading = false.obs;
  final _error = Rx<String?>(null);
  final _radius = 20.0.obs;
  final List<String> _selectedTypes = [
    'advocate',
    'lawyer',
    'paralegal',
    'law_firm'
  ];
  final _userLocation = Rx<UserLocation?>(null);

  // Pagination
  final ScrollController scrollController = ScrollController();
  final _currentPage = 1.obs;
  final _hasMore = true.obs;
  final _isLoadingMore = false.obs;
  final pageSize = 20;

  // Static debounce: persists even if controller is recreated
  static DateTime? _lastFetchTime;
  static bool _fetchInProgress = false;

  List<NearbyLawyer> get lawyers => _lawyers;
  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  bool get hasMore => _hasMore.value;
  String? get error => _error.value;
  double get radius => _radius.value;
  List<String> get selectedTypes => _selectedTypes;
  UserLocation? get userLocation => _userLocation.value;
  int get count => _lawyers.length;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_scrollListener);
    // Request location permission and fetch
    _ensureLocationPermissionAndFetch();
  }

  Future<void> _ensureLocationPermissionAndFetch() async {
    // 1. Check if GPS hardware is on
    final gpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!gpsEnabled) {
      debugPrint('⚠️ GPS hardware is off — opening location settings');
      await Geolocator.openLocationSettings();
    }

    // 2. Check and request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      debugPrint('📍 Permission result after request: $permission');
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint(
          '⚠️ Location permission permanently denied — opening app settings');
      await Geolocator.openAppSettings();
    }

    // 3. Trigger location update so coordinates are fresh
    if (Get.isRegistered<LocationService>()) {
      await Get.find<LocationService>().triggerLocationUpdate(force: true);
    }

    // 4. Fetch nearby lawyers
    if (_lawyers.isEmpty) {
      fetchNearbyLawyers();
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore.value &&
        _hasMore.value) {
      loadMore();
    }
  }

  /// Fetch nearby lawyers (initial load)
  Future<void> fetchNearbyLawyers() async {
    if (_fetchInProgress) return;
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) <
            const Duration(seconds: 3)) {
      debugPrint('⏳ Skipping nearby lawyers fetch — called too recently');
      return;
    }

    try {
      _fetchInProgress = true;
      _isLoading.value = true;
      _error.value = null;
      _currentPage.value = 1;
      _hasMore.value = true;

      // Sync user's latest device location in background
      if (Get.isRegistered<LocationService>()) {
        Get.find<LocationService>().triggerLocationUpdate();
      }

      final typesString = _selectedTypes.join(',');

      final response = await _service.fetchNearbyLawyers(
        radius: _radius.value,
        types: typesString,
        page: 1,
        pageSize: pageSize,
      );

      if (response != null) {
        _lawyers.clear();
        _lawyers.addAll(response.results);
        _userLocation.value = response.yourLocation;
        update();
        _hasMore.value = response.results.length >= pageSize;

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
      _fetchInProgress = false;
      _lastFetchTime = DateTime.now();
    }
  }

  /// Load more lawyers (pagination)
  Future<void> loadMore() async {
    if (_isLoadingMore.value || !_hasMore.value || _fetchInProgress) return;

    try {
      _fetchInProgress = true;
      _isLoadingMore.value = true;
      final nextPage = _currentPage.value + 1;
      final typesString = _selectedTypes.join(',');

      final response = await _service.fetchNearbyLawyers(
        radius: _radius.value,
        types: typesString,
        page: nextPage,
        pageSize: pageSize,
      );

      if (response != null && response.results.isNotEmpty) {
        _lawyers.addAll(response.results);
        _currentPage.value = nextPage;
        update();
        _hasMore.value = response.results.length >= pageSize;
      } else {
        _hasMore.value = false;
      }
    } catch (e) {
      debugPrint('❌ Error loading more lawyers: $e');
    } finally {
      _isLoadingMore.value = false;
      _fetchInProgress = false;
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
        update();
        fetchNearbyLawyers();
      }
    } else {
      _selectedTypes.add(type);
      update();
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
  @override
  Future<void> refresh() async {
    await fetchNearbyLawyers();
  }
}
