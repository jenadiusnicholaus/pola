import 'package:get/get.dart';
import '../models/consultant_models.dart';
import '../services/call_service.dart';

class ConsultantController extends GetxController {
  final CallService _service = CallService();

  // State
  final consultants = <Consultant>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;

  // Filters
  final selectedType = 'mobile'.obs; // 'mobile' or 'physical'
  final selectedConsultantType = ''.obs; // 'advocate', 'lawyer', 'paralegal'
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchConsultants();
  }

  /// Fetch consultants with current filters
  Future<void> fetchConsultants() async {
    try {
      isLoading.value = true;
      error.value = '';

      final results = await _service.getConsultants(
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
