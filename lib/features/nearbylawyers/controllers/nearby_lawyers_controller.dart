import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../models/nearby_lawyer_model.dart';
import '../services/nearby_lawyers_service.dart';
import '../../../config/dio_config.dart';
import '../../../config/environment_config.dart';
import '../../../services/device_info_service.dart';
import '../../../services/location_consent.dart';

/// Nearby Lawyers search controller.
///
/// Google Play location-compliance design: the app NEVER reads device GPS
/// automatically. The user either taps a point on the map picker or
/// explicitly presses "Use my current location". The chosen location is
/// POSTed to the backend exactly once per user action (the nearby-lawyers
/// GET endpoint resolves "nearby" from the device location stored on the
/// server — it accepts no lat/lng parameters).
class NearbyLawyersController extends GetxController {
  final NearbyLawyersService _service = Get.find<NearbyLawyersService>();
  final Dio _dio = DioConfig.instance;
  final GetStorage _storage = GetStorage();

  static const String _storedLocationKey = 'nearby_search_location';

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

  /// The location the user deliberately chose (map pin or one-off GPS read).
  /// Persisted so returning users keep their last search location.
  final _userSelectedLocation = Rx<UserLocation?>(null);

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
  UserLocation? get userSelectedLocation => _userSelectedLocation.value;

  /// Whether the user has deliberately provided a search location.
  /// When false the UI shows a "choose a location" prompt instead of
  /// touching GPS or fetching.
  bool get hasSelectedLocation => _userSelectedLocation.value != null;
  int get count => _lawyers.length;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_scrollListener);
    _restoreSelectedLocationAndFetch();
  }

  /// Restore the location the user picked previously and fetch results for
  /// it. Does NOT touch GPS — this is a cached user-provided value, not a
  /// sensor read. If nothing was ever chosen, the screen shows the
  /// location prompt instead.
  void _restoreSelectedLocationAndFetch() {
    final stored = _storage.read(_storedLocationKey);
    if (stored is Map) {
      final lat = (stored['latitude'] as num?)?.toDouble();
      final lng = (stored['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        final restored = UserLocation(latitude: lat, longitude: lng);
        _userSelectedLocation.value = restored;
        _userLocation.value = restored;
        fetchNearbyLawyers();
      }
    }
  }

  /// Apply a user-chosen search location: remember it, tell the backend
  /// once, then refresh the list.
  Future<void> _applySelectedLocation(UserLocation location) async {
    _userSelectedLocation.value = location;
    _userLocation.value = location;
    await _storage.write(_storedLocationKey, {
      'latitude': location.latitude,
      'longitude': location.longitude,
    });
    await _postLocationUpdate(location);
    await fetchNearbyLawyers();
  }

  /// Called when the user picks a point on the map picker.
  Future<void> applyManualLocation(double latitude, double longitude) {
    debugPrint('📍 User picked location on map: $latitude, $longitude');
    return _applySelectedLocation(
      UserLocation(latitude: latitude, longitude: longitude),
    );
  }

  /// "Use my current location" — explicit user action, so a single
  /// foreground GPS read is allowed after the prominent disclosure.
  Future<void> useCurrentLocation() async {
    try {
      // 1. Check if GPS hardware is on
      if (!await Geolocator.isLocationServiceEnabled()) {
        debugPrint('⚠️ GPS hardware is off — opening location settings');
        await Geolocator.openLocationSettings();
        if (!await Geolocator.isLocationServiceEnabled()) {
          _error.value =
              'Location services are off. Turn on GPS or pick a location on the map.';
          update();
          return;
        }
      }

      // 2. Prominent disclosure, then runtime permission (user-initiated).
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!await LocationConsent.ensure(userInitiated: true)) return;
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        debugPrint('⚠️ Location permission denied');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint(
            '⚠️ Location permission permanently denied — opening app settings');
        await Geolocator.openAppSettings();
        return;
      }

      // 3. Single foreground position read — no tracking, no stream.
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (e) {
        debugPrint('⚠️ getCurrentPosition failed ($e), trying last known');
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) {
        _error.value =
            'Could not get your location. Try picking a location on the map.';
        update();
        return;
      }

      await _applySelectedLocation(
        UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } catch (e) {
      debugPrint('❌ useCurrentLocation error: $e');
    }
  }

  /// POST the user-provided location to the backend exactly once. Same
  /// payload the old tracker used; the nearby-lawyers endpoint resolves
  /// distance from this stored value.
  Future<void> _postLocationUpdate(UserLocation location) async {
    try {
      final deviceId = await DeviceInfoService().getDeviceId();

      final data = <String, dynamic>{
        'latitude': location.latitude,
        'longitude': location.longitude,
        'device_id': deviceId,
      };

      debugPrint('📤 Posting user-selected location: $data');

      final response = await _dio.post(
        EnvironmentConfig.updateLocationUrl,
        data: data,
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Location updated: ${response.data}');
      } else {
        debugPrint(
            '⚠️ Location update returned ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      // Non-fatal — the user can still retry by picking a location again.
      debugPrint('❌ Location update failed: ${e.message}');
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

  /// Fetch nearby lawyers (initial load).
  ///
  /// The endpoint takes radius/types/page only — the backend uses the
  /// device location last posted via [_postLocationUpdate].
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
