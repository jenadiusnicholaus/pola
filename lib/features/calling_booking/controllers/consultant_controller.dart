import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/consultant_models.dart';
import '../services/call_service.dart';

class ConsultantController extends GetxController {
  final CallService _service = CallService();

  // State
  final consultants = <Consultant>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;

  // Pagination
  final ScrollController scrollController = ScrollController();
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  int currentPage = 1;
  final int pageSize = 20;
  int? totalCount;

  // Filters
  final selectedType = 'mobile'.obs; // 'mobile' or 'physical'
  final selectedConsultantType = ''.obs; // 'advocate', 'lawyer', 'paralegal'
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_scrollListener);
    fetchConsultants();
  }

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.onClose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore.value && hasMore.value) {
        loadMore();
      }
    }
  }

  /// Fetch consultants with current filters (resets pagination)
  Future<void> fetchConsultants() async {
    try {
      isLoading.value = true;
      error.value = '';
      currentPage = 1;
      hasMore.value = true;

      final response = await _service.getConsultants(
        type: selectedType.value.isNotEmpty ? selectedType.value : null,
        consultantType: selectedConsultantType.value.isNotEmpty
            ? selectedConsultantType.value
            : null,
        page: currentPage,
        pageSize: pageSize,
      );

      consultants.value = response['results'] as List<Consultant>;
      totalCount = response['count'] as int?;
      hasMore.value = response['next'] != null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more consultants for pagination
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;

    try {
      isLoadingMore.value = true;
      currentPage++;

      final response = await _service.getConsultants(
        type: selectedType.value.isNotEmpty ? selectedType.value : null,
        consultantType: selectedConsultantType.value.isNotEmpty
            ? selectedConsultantType.value
            : null,
        page: currentPage,
        pageSize: pageSize,
      );

      final newConsultants = response['results'] as List<Consultant>;
      consultants.addAll(newConsultants);
      hasMore.value = response['next'] != null;
    } catch (e) {
      debugPrint('Error loading more consultants: $e');
      currentPage--; // Revert page increment on error
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Search consultants
  Future<void> searchConsultants(String query) async {
    try {
      isLoading.value = true;
      error.value = '';
      searchQuery.value = query;

      final results = await _service.searchConsultants(
        query: query.isNotEmpty ? query : null,
        type: selectedType.value.isNotEmpty ? selectedType.value : null,
        consultantType: selectedConsultantType.value.isNotEmpty
            ? selectedConsultantType.value
            : null,
      );

      consultants.value = results;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Get consultant details
  Future<Consultant?> getConsultantDetails(int consultantId) async {
    try {
      return await _service.getConsultantDetails(consultantId);
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// Update filter and refresh
  void updateTypeFilter(String type) {
    selectedType.value = type;
    fetchConsultants();
  }

  void updateConsultantTypeFilter(String type) {
    selectedConsultantType.value = type;
    fetchConsultants();
  }

  /// Refresh consultants
  Future<void> refresh() async {
    await fetchConsultants();
  }
}
