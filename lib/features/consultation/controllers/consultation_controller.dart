import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../services/consultation_service.dart';
import '../models/consultation_models.dart';
import '../../../services/permission_service.dart';
import '../../../services/token_storage_service.dart';

class ConsultationController extends GetxController {
  final ConsultationService _service = Get.find<ConsultationService>();
  final PermissionService _permissionService = Get.find<PermissionService>();
  final TokenStorageService _tokenStorage = Get.find<TokenStorageService>();

  final _eligibility = Rxn<ConsultationEligibility>();
  ConsultationEligibility? get eligibility => _eligibility.value;

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final _error = ''.obs;
  String get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    checkEligibility();
  }

  Future<void> checkEligibility() async {
    if (!_tokenStorage.isLoggedIn) {
      debugPrint(
          '🔒 Skipping consultation eligibility check — user not logged in');
      return;
    }
    _isLoading.value = true;
    _error.value = '';
    try {
      final result = await _service.checkEligibility();
      _eligibility.value = result;
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  bool get canApply => eligibility?.canApply ?? false;
  bool get isConsultant => eligibility?.isConsultant ?? false;
  String get applicationStatus => eligibility?.status ?? 'none';

  bool get isLawFirm => _permissionService.isLawFirm;
  String get userRole => _permissionService.userRoleName ?? '';
}
