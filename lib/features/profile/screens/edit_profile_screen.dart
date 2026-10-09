import 'package:flutter/material.dart';
import 'package:localization_lite/translate.dart';
import 'package:get/get.dart';
import '../../../constants/app_colors.dart';
import '../../auth/models/lookup_models.dart';
import '../controllers/edit_profile_controller.dart';
import '../../../shared/widgets/intl_phone_input.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<EditProfileController>()) {
      Get.delete<EditProfileController>();
    }
    final controller = Get.put(EditProfileController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Edit Profile')),
        backgroundColor: AppColors.primaryAmber,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.profile == null && !controller.isSaving.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (controller.showPersonalFields.value) ...[
                  Text(
                    'Personal Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: controller.firstNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoration('First Name', Icons.person_outline),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'First name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: controller.lastNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoration('Last Name', Icons.person_outline),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Last name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Email — display only
                TextFormField(
                  controller: controller.emailController,
                  enabled: false,
                  decoration: _decoration(
                    'Email',
                    Icons.email_outlined,
                  ).copyWith(
                    helperText: 'Email cannot be changed',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 12),

                if (controller.showPersonalFields.value) ...[
                  Obx(() {
                    final dob = controller.dateOfBirth.value;
                    final label = dob == null
                        ? 'Select date of birth'
                        : '${dob.day}/${dob.month}/${dob.year}';
                    return InkWell(
                      onTap: () => controller.pickDateOfBirth(context),
                      child: InputDecorator(
                        decoration: _decoration(
                          'Date of Birth',
                          Icons.calendar_today_outlined,
                        ),
                        child: Text(label),
                      ),
                    );
                  }),
                  SizedBox(height: 12),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      value: controller.gender.value.isEmpty
                          ? null
                          : controller.gender.value.toUpperCase(),
                      decoration: _decoration('Gender', Icons.wc_outlined),
                      items: [
                        DropdownMenuItem(value: 'M', child: Text(tr('Male'))),
                        DropdownMenuItem(value: 'F', child: Text(tr('Female'))),
                      ],
                      onChanged: (value) {
                        if (value != null) controller.gender.value = value;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (controller.isCitizen.value) ...[
                  TextFormField(
                    controller: controller.idNumberController,
                    decoration: _decoration('ID Number', Icons.badge_outlined),
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 8),
                Text(
                  'Contact',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                IntlPhoneInput(
                  initialValue: _nationalPart(controller.phoneController.text),
                  labelText: tr('Phone Number'),
                  prefixIcon: const Icon(Icons.phone_outlined),
                  borderRadius: 12,
                  invalidNumberMessage:
                      'Enter a valid phone number for the selected country',
                  validator: (phone) {
                    if (phone == null || phone.number.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    return null;
                  },
                  onChanged: (complete) =>
                      controller.phoneController.text = complete,
                ),
                SizedBox(height: 20),

                Text(
                  tr('Address'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final regions = controller.lookupService.regions;
                  final loading = controller.lookupService.isLoadingRegions;
                  return DropdownButtonFormField<int>(
                    value: controller.selectedRegion.value,
                    decoration:
                        _decoration('Region', Icons.map_outlined).copyWith(
                      helperText: loading ? 'Loading regions...' : null,
                    ),
                    items: regions
                        .map(
                          (Region r) => DropdownMenuItem<int>(
                            value: r.id,
                            child:
                                Text(r.name, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: loading ? null : controller.onRegionChanged,
                  );
                }),
                const SizedBox(height: 12),
                Obx(() {
                  final loading = controller.lookupService.isLoadingDistricts;
                  final districts = controller.filteredDistricts;
                  final regionSelected =
                      controller.selectedRegion.value != null;
                  return DropdownButtonFormField<int>(
                    value: districts.value.any(
                            (d) => d.id == controller.selectedDistrict.value)
                        ? controller.selectedDistrict.value
                        : null,
                    decoration:
                        _decoration('District', Icons.location_city).copyWith(
                      helperText: !regionSelected
                          ? 'Select a region first'
                          : loading
                              ? 'Loading districts...'
                              : null,
                    ),
                    items: districts.value
                        .map(
                          (District d) => DropdownMenuItem<int>(
                            value: d.id,
                            child:
                                Text(d.name, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (!regionSelected || loading)
                        ? null
                        : (value) => controller.selectedDistrict.value = value,
                  );
                }),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller.wardController,
                  decoration: _decoration('Ward', Icons.place_outlined),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller.addressController,
                  maxLines: 3,
                  decoration: _decoration(
                    'Street / Office Address',
                    Icons.home_outlined,
                  ),
                ),
                const SizedBox(height: 28),
                Obx(
                  () => ElevatedButton(
                    onPressed: controller.isSaving.value
                        ? null
                        : () async {
                            final ok = await controller.saveProfile();
                            if (ok && context.mounted) {
                              Get.back(result: true);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAmber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isSaving.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Strips a stored phone number down to its national digits
  /// so it can seed the international field's text input.
  String _nationalPart(String stored) {
    var digits = stored.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('255') && digits.length > 9) {
      digits = digits.substring(3);
    }
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits;
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
