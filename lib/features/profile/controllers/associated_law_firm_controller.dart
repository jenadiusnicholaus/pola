import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/services/lookup_service.dart';
import '../../../utils/navigation_helper.dart';
import '../services/profile_service.dart';

class AssociatedLawFirmController extends GetxController {
  final ProfileService _profileService = Get.find<ProfileService>();
  final LookupService lookupService = Get.find<LookupService>();

  final selectedLawFirm = RxnInt();
  final isLoading = false.obs;
  final isSaving = false.obs;

  @override
  void onReady() {
    super.onReady();
    _loadCurrentAssociation();
  }

  Future<void> _loadCurrentAssociation() async {
    final profile = _profileService.currentProfile;
    if (profile != null) {
      selectedLawFirm.value = profile.associatedLawFirm;
    }

    try {
      isLoading.value = true;
      await lookupService.fetchLawFirms();
    } catch (e) {
      debugPrint('❌ Error loading law firms: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save() async {
    if (isSaving.value) return false;

    isSaving.value = true;
    try {
      await _profileService.updateAssociatedLawFirm(selectedLawFirm.value);

      NavigationHelper.showSafeSnackbar(
        title: 'Success',
        message: 'Associated law firm updated',
      );
      return true;
    } catch (e) {
      NavigationHelper.showSafeSnackbar(
        title: 'Error',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
