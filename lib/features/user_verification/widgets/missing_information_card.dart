import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/verification_controller.dart';
import '../models/verification_models.dart';

class MissingInformationCard extends StatelessWidget {
  const MissingInformationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.find<VerificationController>(tag: 'verification_screen');

    return Obx(() {
      if (!controller.hasVerificationData) {
        return const SizedBox.shrink();
      }

      final status = controller.verificationStatus!;

      // Check if there are missing items
      if (!status.missingInformation.hasMissingItems &&
          status.requiredDocuments.isEmpty) {
        return const SizedBox.shrink();
      }

      // Safely get missing info items
      List<MissingInformationItem> missingInfoItems = [];
      try {
        missingInfoItems = status.missingInformation
            .where((info) => !info.isProvided)
            .toList();
      } catch (e) {
        debugPrint('Error getting missing info items: $e');
        // If there's an error, create items from incomplete steps
        missingInfoItems = status.missingInformation.incompleteSteps
            .expand((step) => step.issues.map((issue) => MissingInformationItem(
                  fieldName: step.title,
                  fieldDisplayName: step.title,
                  description: issue,
                  isProvided: false,
                )))
            .toList();
      }

      final missingDocs =
          status.requiredDocuments.where((doc) => !doc.isSubmitted).toList();

      if (missingInfoItems.isEmpty && missingDocs.isEmpty) {
        return const SizedBox.shrink();
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Missing Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${missingInfoItems.length + missingDocs.length}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'Complete these items to continue your verification:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 12),

              // Missing Information
              if (missingInfoItems.isNotEmpty) ...[
                _buildSectionHeader(
                    context, 'Personal Information', Icons.person),
                const SizedBox(height: 8),
                ...missingInfoItems
                    .map((info) => _buildMissingInfoItem(context, info)),
                const SizedBox(height: 16),
              ],

              // Missing Documents
              if (missingDocs.isNotEmpty) ...[
                _buildSectionHeader(
                    context, 'Required Documents', Icons.description),
                const SizedBox(height: 8),
                ...missingDocs.map(
                    (doc) => _buildMissingDocItem(context, doc, controller)),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildMissingInfoItem(
      BuildContext context, MissingInformationItem info) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.orange[400],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.fieldDisplayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.orange[800],
                      ),
                ),
                if (info.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    info.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange[700],
                        ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.edit,
            size: 16,
            color: Colors.orange[600],
          ),
        ],
      ),
    );
  }

  Widget _buildMissingDocItem(BuildContext context, RequiredDocument doc,
      VerificationController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.orange[400],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.documentTypeDisplay,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.orange[800],
                      ),
                ),
                if (doc.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    doc.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange[700],
                        ),
                  ),
                ],
                if (doc.maxSizeMB > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Max size: ${doc.maxSizeMB} MB',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () => controller.pickAndUploadDocument(doc.documentType),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.upload_file,
                    size: 14,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Upload',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
