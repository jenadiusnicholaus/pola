import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/consultation_controller.dart';
import '../models/consultation_models.dart';
import 'consultant_application_dialog.dart';

class ConsultantStatusCard extends StatelessWidget {
  const ConsultantStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ConsultationController());

    return Obx(() {
      if (controller.isLoading && controller.eligibility == null) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      final eligibility = controller.eligibility;
      if (eligibility == null) return const SizedBox.shrink();

      // If user is already a consultant or has a pending application
      if (eligibility.isConsultant || eligibility.status != 'none') {
        return _buildStatusCard(context, eligibility);
      }

      // If user is eligible to apply
      if (eligibility.canApply) {
        return _buildApplyCard(context, controller);
      }

      return const SizedBox.shrink();
    });
  }

  Widget _buildStatusCard(BuildContext context, ConsultationEligibility eligibility) {
    final theme = Theme.of(context);
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info_outline;
    String statusText = eligibility.status;

    if (eligibility.isConsultant) {
      statusColor = Colors.green;
      statusIcon = Icons.verified;
      statusText = 'Active Consultant';
    } else if (eligibility.status == 'pending') {
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
      statusText = 'Application Pending Review';
    } else if (eligibility.status == 'rejected') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Application Rejected';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 12),
                Text(
                  'Consultant Status',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (eligibility.message != null) ...[
              const SizedBox(height: 8),
              Text(
                eligibility.message!,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApplyCard(BuildContext context, ConsultationController controller) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Become a Consultant',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Share your legal expertise and earn by providing consultations to Pola users.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showApplyDialog(context, controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: const Text('Apply Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApplyDialog(BuildContext context, ConsultationController controller) async {
    final result = await Get.dialog<bool>(
      ConsultantApplicationDialog(
        consultantType: controller.userRole,
        canOfferPhysical: controller.isLawFirm,
      ),
    );

    if (result == true) {
      controller.checkEligibility();
    }
  }
}
