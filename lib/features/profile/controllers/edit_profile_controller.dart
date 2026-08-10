import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/models/lookup_models.dart';
import '../../auth/services/lookup_service.dart';
import '../models/profile_models.dart';
import '../services/profile_service.dart';
import '../../../utils/navigation_helper.dart';

class EditProfileController extends GetxController {
  final ProfileService _profileService = Get.find<ProfileService>();
  final LookupService lookupService = Get.find<LookupService>();

  final formKey = GlobalKey<FormState>();

  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController wardController;
  late final TextEditingController addressController;
  late final TextEditingController idNumberController;

  final RxString gender = ''.obs;
  final Rxn<DateTime> dateOfBirth = Rxn<DateTime>();
  final RxnInt selectedRegion = RxnInt();
  final RxnInt selectedDistrict = RxnInt();
  final RxList<District> filteredDistricts = <District>[].obs;
  final RxBool isSaving = false.obs;
  final RxBool isLawFirm = false.obs;
  final RxBool isCitizen = false.obs;
  final RxBool showPersonalFields = true.obs;

  UserProfile? get profile => _profileService.currentProfile;

  @override
  void onInit() {
    super.onInit();
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    wardController = TextEditingController();
    addressController = TextEditingController();
    idNumberController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    var current = profile;
    if (current == null) {
      current = await _profileService.fetchProfile();
    }
    if (current == null) return;

    final role = current.userRole.roleName;
    isLawFirm.value = role == 'law_firm';
    isCitizen.value = role == 'citizen';
    showPersonalFields.value = role != 'law_firm';

    firstNameController.text = current.firstName;
    lastNameController.text = current.lastName;
    emailController.text = current.email;
    phoneController.text = current.contact.phoneNumber;
    wardController.text = current.address.ward ?? '';
    addressController.text = current.address.officeAddress ?? '';
    idNumberController.text = current.idNumber ?? '';
    gender.value = current.gender;

    if (current.dateOfBirth.isNotEmpty) {
      try {
        dateOfBirth.value = DateTime.parse(current.dateOfBirth);
      } catch (_) {
        dateOfBirth.value = null;
      }
    }

    selectedRegion.value = current.address.region;
    selectedDistrict.value = current.address.district;

    await lookupService.fetchRegions();
    if (selectedRegion.value != null) {
      await loadDistrictsForRegion(selectedRegion.value!);
    }
  }

  Future<void> loadDistrictsForRegion(int regionId) async {
    try {
      final districts = await lookupService.fetchDistricts(regionId: regionId);
      filteredDistricts.value.assignAll(districts);
    } catch (e) {
      filteredDistricts.value.clear();
      NavigationHelper.showSafeSnackbar(
        title: 'Error',
        message: 'Failed to load districts. Please try again.',
      );
    }
  }

  void onRegionChanged(int? regionId) {
    selectedRegion.value = regionId;
    selectedDistrict.value = null;
    filteredDistricts.value.clear();
    if (regionId != null) {
      loadDistrictsForRegion(regionId);
    }
  }

  Future<void> pickDateOfBirth(BuildContext context) async {
    final initial = dateOfBirth.value ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      dateOfBirth.value = picked;
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<bool> saveProfile() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return false;
    }

    isSaving.value = true;
    try {
      final updates = <String, dynamic>{
        'contact': {
          'phone_number': phoneController.text.trim(),
        },
        'address': {
          'region': selectedRegion.value,
          'district': selectedDistrict.value,
          'ward': wardController.text.trim().isEmpty
              ? null
              : wardController.text.trim(),
          'office_address': addressController.text.trim().isEmpty
              ? null
              : addressController.text.trim(),
        },
      };

      if (showPersonalFields.value) {
        updates['first_name'] = firstNameController.text.trim();
        updates['last_name'] = lastNameController.text.trim();
        if (gender.value.isNotEmpty) {
          updates['gender'] = gender.value;
        }
        if (dateOfBirth.value != null) {
          updates['date_of_birth'] = _formatDate(dateOfBirth.value!);
        }
      }

      if (isCitizen.value) {
        if (idNumberController.text.trim().isNotEmpty) {
          updates['id_number'] = idNumberController.text.trim();
        }
      }

      await _profileService.updateProfile(updates);
      NavigationHelper.showSafeSnackbar(
        title: 'Success',
        message: 'Profile updated successfully',
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

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    wardController.dispose();
    addressController.dispose();
    idNumberController.dispose();
    super.onClose();
  }
}
