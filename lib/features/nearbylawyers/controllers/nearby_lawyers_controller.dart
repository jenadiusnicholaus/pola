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

  // Pagination
  final ScrollController scrollController = ScrollController();
  final _currentPage = 1.obs;
  final _hasMore = true.obs;
  final _isLoadingMore = false.obs;
  final pageSize = 20;

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
    // PERFORMANCE: Don't auto-fetch on init - let the screen trigger it when ready
    // fetchNearbyLawyers();
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
    try {
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
        _lawyers.value = response.results;
        _userLocation.value = response.yourLocation;
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
    }
  }

  /// Load more lawyers (pagination)
  Future<void> loadMore() async {
    if (_isLoadingMore.value || !_hasMore.value) return;

    try {
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
        _hasMore.value = response.results.length >= pageSize;
      } else {
        _hasMore.value = false;
      }
    } catch (e) {
      debugPrint('❌ Error loading more lawyers: $e');
    } finally {
      _isLoadingMore.value = false;
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
