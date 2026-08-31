import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/models/lookup_models.dart';
import '../controllers/associated_law_firm_controller.dart';
import '../../../constants/app_colors.dart';

class AssociatedLawFirmScreen extends StatelessWidget {
  const AssociatedLawFirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AssociatedLawFirmController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Associated Law Firm'),
        backgroundColor: AppColors.primaryAmber,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select your associated law firm',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This helps clients find you under your firm.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              Obx(() {
                final lawFirms = controller.lookupService.lawFirms;
                final loading = controller.lookupService.isLoadingLawFirms;

                return DropdownButtonFormField<int?>(
                  value: controller.selectedLawFirm.value,
                  decoration: InputDecoration(
                    labelText: 'Law Firm',
                    prefixIcon: const Icon(Icons.business_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: loading
                        ? 'Loading law firms...'
                        : lawFirms.isEmpty
                            ? 'No law firms available'
                            : 'Leave empty if independent',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('None (Independent Practitioner)'),
                    ),
                    ...lawFirms.map((LawFirm lawFirm) {
                      return DropdownMenuItem<int?>(
                        value: lawFirm.id,
                        child: Text(
                          lawFirm.firmName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: loading
                      ? null
                      : (value) => controller.selectedLawFirm.value = value,
                );
              }),
              const SizedBox(height: 24),
              Obx(
                () => ElevatedButton(
                  onPressed: controller.isSaving.value
                      ? null
                      : () async {
                          final ok = await controller.save();
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
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
