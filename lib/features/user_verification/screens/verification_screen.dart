import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/verification_controller.dart';
import '../widgets/verification_status_header.dart';
import '../widgets/verification_progress_card.dart';
import '../widgets/detailed_verification_step.dart';
import '../models/verification_models.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  late final VerificationController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(VerificationController(), tag: 'verification_screen');
  }

  @override
  void dispose() {
    Get.delete<VerificationController>(tag: 'verification_screen');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshVerificationStatus,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading && !controller.hasVerificationData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading verification status...'),
              ],
            ),
          );
        }

        if (controller.hasError && !controller.hasVerificationData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading verification status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  controller.error,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: controller.loadVerificationStatus,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshVerificationStatus,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Header
                const VerificationStatusHeader(),
                const SizedBox(height: 16),

                // Progress Card
                const VerificationProgressCard(),
                const SizedBox(height: 24),

                // Detailed Verification Steps
                Text(
                  'Verification Steps',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  final status = controller.verificationStatus;
                  final isLegalProfessional = status != null &&
                      _isLegalProfessional(status.userRole.name);

                  return Text(
                    isLegalProfessional
                        ? 'Complete each step to verify your account. As a ${status.userRole.display.toLowerCase()}, you\'ll need to provide additional professional credentials. Expand any step to see details and take action.'
                        : 'Complete each step to verify your account. Expand any step to see details and take action.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  );
                }),
                const SizedBox(height: 20),

                ..._buildDetailedSteps(controller),

                // Submit for Review Button
                if (controller.needsVerification &&
                    _canSubmitForReview(controller)) ...[
                  const SizedBox(height: 24),
                  _buildSubmitForReviewCard(),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  List<Widget> _buildDetailedSteps(VerificationController controller) {
    if (!controller.hasVerificationData) return [];

    final status = controller.verificationStatus!;
    final userRole = status.userRole.name;

    // Define verification steps in correct API order: documents -> identity -> contact -> role_specific -> final
    final steps = [
      // 1. Documents (first step)
      () {
        final documentsStep = status.missingInformation.byStep['documents'];
        final isCompleted = documentsStep?.status == 'complete';
        return {
          'id': 'documents',
          'title': 'Documents Verification',
          'description': 'Upload required identification documents',
          'icon': Icons.description,
          'isCompleted': isCompleted,
          'isCurrent': isCompleted ? false : (documentsStep?.isCurrent == true),
          'userInfo': _getDocumentsInfo(status),
          'missingInfo': _getMissingDocumentsInfo(status),
        };
      }(),
      // 2. Identity (personal information)
      () {
        final identityStep = status.missingInformation.byStep['identity'];
        final isCompleted = identityStep?.status == 'complete';
        return {
          'id': 'identity',
          'title': 'Identity Information',
          'description': 'Verify identity information',
          'icon': Icons.person,
          'isCompleted': isCompleted,
          'isCurrent': isCompleted ? false : (identityStep?.isCurrent == true),
          'userInfo': _getPersonalInfo(status),
          'missingInfo': _getMissingPersonalInfo(status),
        };
      }(),
      // 3. Contact Information
      () {
        final contactStep = status.missingInformation.byStep['contact'];
        final isCompleted = contactStep?.status == 'complete';
        return {
          'id': 'contact',
          'title': 'Contact Information',
          'description': 'Verify your contact details',
          'icon': Icons.contact_phone,
          'isCompleted': isCompleted,
          'isCurrent': isCompleted ? false : (contactStep?.isCurrent == true),
          'userInfo': _getContactInfo(status),
          'missingInfo': _getMissingContactInfo(status),
        };
      }(),
      // 4. Role-specific step (only for legal professionals)
      if (_isLegalProfessional(userRole)) ...[
        () {
          final roleStep = status.missingInformation.byStep['role_specific'];
          final isCompleted = roleStep?.status == 'complete';
          return {
            'id': 'role_specific',
            'title': _getRoleSpecificTitle(userRole),
            'description': _getRoleSpecificDescription(userRole),
            'icon': _getRoleSpecificIcon(userRole),
            'isCompleted': isCompleted,
            'isCurrent': isCompleted ? false : (roleStep?.isCurrent == true),
            'userInfo': _getRoleSpecificInfo(status, userRole),
            'missingInfo': _getMissingRoleSpecificInfo(status, userRole),
          };
        }(),
      ],
      // 5. Final (admin review)
      () {
        final finalStep = status.missingInformation.byStep['final'];
        final isComplete = finalStep?.status == 'complete' || status.isVerified;
        return {
          'id': 'final',
          'title': isComplete ? 'Verification Complete' : 'Admin Review',
          'description': isComplete
              ? 'Your verification has been completed successfully'
              : 'Wait for administrator to review your information',
          'icon': isComplete ? Icons.verified : Icons.admin_panel_settings,
          'isCompleted': isComplete,
          'isCurrent': isComplete ? false : finalStep?.isCurrent == true,
          'userInfo': _getFinalInfo(status),
          'missingInfo': _getMissingFinalInfo(status),
        };
      }(),
    ];

    return steps
        .map((step) => DetailedVerificationStep(
              stepId: step['id'] as String,
              title: step['title'] as String,
              description: step['description'] as String,
              icon: step['icon'] as IconData,
              isCompleted: step['isCompleted'] as bool,
              isCurrent: step['isCurrent'] as bool,
              documents: step['id'] == 'documents' ? status.documents : [],
              requiredDocuments:
                  step['id'] == 'documents' ? status.requiredDocuments : [],
              userInfo: step['userInfo'] as Map<String, String>,
              missingInfo: step['missingInfo'] as List<String>,
            ))
        .toList();
  }

  Map<String, String> _getPersonalInfo(VerificationStatus status) {
    final info = <String, String>{};

    // Get verified identity fields from API data
    final identityStep = status.missingInformation.byStep['identity'];
    if (identityStep != null) {
      for (final verifiedField in identityStep.verifiedFields) {
        if (verifiedField.isVerified && verifiedField.value != null) {
          String displayValue;
          if (verifiedField.value is Map) {
            final valueMap = verifiedField.value as Map;
            displayValue = valueMap.values
                .where((v) => v != null && v.toString().isNotEmpty)
                .join(', ');
          } else {
            displayValue = verifiedField.value.toString();
          }

          if (displayValue.isNotEmpty) {
            info[verifiedField.label] = displayValue;
          }
        }
      }
    }

    return info;
  }

  List<String> _getMissingPersonalInfo(VerificationStatus status) {
    final missing = <String>[];

    // Get missing identity fields from API data
    final identityStep = status.missingInformation.byStep['identity'];
    if (identityStep != null) {
      // Add issues/missing items
      if (identityStep.issues.isNotEmpty) {
        missing.addAll(identityStep.issues);
      }

      // Check required fields that don't have verified values
      final verifiedFieldNames = identityStep.verifiedFields
          .where((field) => field.isVerified)
          .map((field) => field.field)
          .toSet();

      for (final requiredField in identityStep.requiredFields) {
        if (!verifiedFieldNames.contains(requiredField)) {
          final displayName = _formatFieldName(requiredField);
          if (!missing.contains(displayName)) {
            missing.add(displayName);
          }
        }
      }
    }

    return missing;
  }

  Map<String, String> _getContactInfo(VerificationStatus status) {
    final info = <String, String>{};

    // Get verified contact fields from API data
    final contactStep = status.missingInformation.byStep['contact'];
    if (contactStep != null) {
      for (final verifiedField in contactStep.verifiedFields) {
        if (verifiedField.isVerified && verifiedField.value != null) {
          String displayValue;
          if (verifiedField.value is Map) {
            final valueMap = verifiedField.value as Map;
            displayValue = valueMap.values
                .where((v) => v != null && v.toString().isNotEmpty)
                .join(', ');
          } else {
            displayValue = verifiedField.value.toString();
          }

          if (displayValue.isNotEmpty) {
            info[verifiedField.label] = displayValue;
          }
        }
      }
    }

    return info;
  }

  List<String> _getMissingContactInfo(VerificationStatus status) {
    final missing = <String>[];

    // Get missing contact fields from API data
    final contactStep = status.missingInformation.byStep['contact'];
    if (contactStep != null) {
      // Add issues/missing items
      if (contactStep.issues.isNotEmpty) {
        missing.addAll(contactStep.issues);
      }

      // Check required fields that don't have verified values
      final verifiedFieldNames = contactStep.verifiedFields
          .where((field) => field.isVerified)
          .map((field) => field.field)
          .toSet();

      for (final requiredField in contactStep.requiredFields) {
        if (!verifiedFieldNames.contains(requiredField)) {
          final displayName = _formatFieldName(requiredField);
          if (!missing.contains(displayName)) {
            missing.add(displayName);
          }
        }
      }
    }

    return missing;
  }

  bool _canSubmitForReview(VerificationController controller) {
    if (!controller.hasVerificationData) return false;
    final status = controller.verificationStatus!;

    // Use API's is_ready_for_approval field instead of hardcoded logic
    return status.missingInformation.isReadyForApproval &&
        !status.isSubmittedForReview;
  }

  Widget _buildSubmitForReviewCard() {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.05),
              Theme.of(context).primaryColor.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.send,
                color: Theme.of(context).primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ready to Submit',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'All required information and documents have been provided. Submit your verification for admin review.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton.icon(
                    onPressed: controller.isLoading
                        ? null
                        : () => _showSubmitConfirmation(),
                    icon: controller.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      controller.isLoading
                          ? 'Submitting...'
                          : 'Submit for Review',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubmitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit for Review'),
        content: const Text(
          'Are you sure you want to submit your verification for admin review? '
          'Make sure all your information and documents are correct as you won\'t be able to make changes during the review process.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.submitForReview();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  // Role-specific helper methods
  bool _isLegalProfessional(String roleName) {
    return ['advocate', 'lawyer', 'law_firm', 'paralegal'].contains(roleName);
  }

  String _getRoleSpecificTitle(String roleName) {
    switch (roleName) {
      case 'advocate':
        return 'Advocate Credentials';
      case 'lawyer':
        return 'Lawyer Credentials';
      case 'paralegal':
        return 'Paralegal Credentials';
      case 'law_firm':
        return 'Law Firm Information';
      default:
        return 'Professional Credentials';
    }
  }

  String _getRoleSpecificDescription(String roleName) {
    switch (roleName) {
      case 'advocate':
        return 'Provide your bar admission details, license number, and practice areas';
      case 'lawyer':
        return 'Provide your bar admission, license information, and specialization areas';
      case 'paralegal':
        return 'Provide your certification, education, and supervising attorney details';
      case 'law_firm':
        return 'Provide firm registration, practicing lawyers, and business license';
      default:
        return 'Provide your professional credentials and certifications';
    }
  }

  IconData _getRoleSpecificIcon(String roleName) {
    switch (roleName) {
      case 'advocate':
        return Icons.gavel;
      case 'lawyer':
        return Icons.balance;
      case 'paralegal':
        return Icons.support_agent;
      case 'law_firm':
        return Icons.business;
      default:
        return Icons.work;
    }
  }

  Map<String, String> _getRoleSpecificInfo(
      VerificationStatus status, String roleName) {
    final info = <String, String>{};

    // Get verified role-specific fields from API data
    final roleSpecificStep = status.missingInformation.byStep['role_specific'];
    if (roleSpecificStep != null) {
      // Add verified fields to info
      for (final verifiedField in roleSpecificStep.verifiedFields) {
        if (verifiedField.isVerified && verifiedField.value != null) {
          String displayValue;
          if (verifiedField.value is Map) {
            // Handle complex values like addresses
            final valueMap = verifiedField.value as Map;
            displayValue = valueMap.values
                .where((v) => v != null && v.toString().isNotEmpty)
                .join(', ');
          } else {
            displayValue = verifiedField.value.toString();
          }

          if (displayValue.isNotEmpty) {
            info[verifiedField.label] = displayValue;
          }
        }
      }
    }

    // Always add role display as first item
    if (status.userRole.display.isNotEmpty) {
      final roleInfo = <String, String>{'Role': status.userRole.display};
      roleInfo.addAll(info);
      return roleInfo;
    }

    return info;
  }

  List<String> _getMissingRoleSpecificInfo(
      VerificationStatus status, String roleName) {
    final missing = <String>[];

    // Get missing role-specific fields from API data
    final roleSpecificStep = status.missingInformation.byStep['role_specific'];
    if (roleSpecificStep != null) {
      // Check for issues/missing items
      if (roleSpecificStep.issues.isNotEmpty) {
        missing.addAll(roleSpecificStep.issues);
      }

      // Check required fields that don't have verified values
      final verifiedFieldNames = roleSpecificStep.verifiedFields
          .where((field) => field.isVerified)
          .map((field) => field.field)
          .toSet();

      for (final requiredField in roleSpecificStep.requiredFields) {
        if (!verifiedFieldNames.contains(requiredField)) {
          // Convert field name to display name
          final displayName = _formatFieldName(requiredField);
          if (!missing.contains(displayName)) {
            missing.add(displayName);
          }
        }
      }
    }

    return missing;
  }

  // Helper method to format field names for display
  String _formatFieldName(String fieldName) {
    return fieldName
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // Documents step methods
  Map<String, String> _getDocumentsInfo(VerificationStatus status) {
    final info = <String, String>{};

    // Get verified documents step fields from API data
    final documentsStep = status.missingInformation.byStep['documents'];
    if (documentsStep != null) {
      for (final verifiedField in documentsStep.verifiedFields) {
        if (verifiedField.isVerified && verifiedField.value != null) {
          String displayValue;
          if (verifiedField.value is Map) {
            final valueMap = verifiedField.value as Map;
            displayValue = valueMap.values
                .where((v) => v != null && v.toString().isNotEmpty)
                .join(', ');
          } else {
            displayValue = verifiedField.value.toString();
          }

          if (displayValue.isNotEmpty) {
            info[verifiedField.label] = displayValue;
          }
        }
      }
    }

    // Also show uploaded documents count
    final uploadedDocs =
        status.documents.where((doc) => doc.status != 'rejected').length;
    final totalRequired =
        status.requiredDocuments.where((req) => req.required).length;

    if (uploadedDocs > 0) {
      info['Uploaded Documents'] =
          '$uploadedDocs of $totalRequired required documents';
    }

    // Show verified documents
    final verifiedDocs =
        status.documents.where((doc) => doc.status == 'verified').length;
    if (verifiedDocs > 0) {
      info['Verified Documents'] = '$verifiedDocs documents verified';
    }

    return info;
  }

  List<String> _getMissingDocumentsInfo(VerificationStatus status) {
    final missing = <String>[];

    // Get missing documents step fields from API data
    final documentsStep = status.missingInformation.byStep['documents'];
    if (documentsStep != null) {
      // Add issues/missing items
      if (documentsStep.issues.isNotEmpty) {
        missing.addAll(documentsStep.issues);
      }

      // Check required fields that don't have verified values
      final verifiedFieldNames = documentsStep.verifiedFields
          .where((field) => field.isVerified)
          .map((field) => field.field)
          .toSet();

      for (final requiredField in documentsStep.requiredFields) {
        if (!verifiedFieldNames.contains(requiredField)) {
          final displayName = _formatFieldName(requiredField);
          if (!missing.contains(displayName)) {
            missing.add(displayName);
          }
        }
      }
    }

    // Check for missing required documents
    for (final requiredDoc in status.requiredDocuments) {
      if (requiredDoc.required) {
        final hasValidDoc = status.documents.any((doc) =>
            doc.documentType.toLowerCase() == requiredDoc.type.toLowerCase() &&
            doc.status != 'rejected');

        if (!hasValidDoc) {
          missing.add('${requiredDoc.label} (Required)');
        }
      }
    }

    return missing;
  }

  // Final step methods
  Map<String, String> _getFinalInfo(VerificationStatus status) {
    final info = <String, String>{};

    // Get verified final step fields from API data
    final finalStep = status.missingInformation.byStep['final'];
    if (finalStep != null) {
      for (final verifiedField in finalStep.verifiedFields) {
        if (verifiedField.isVerified && verifiedField.value != null) {
          String displayValue;
          if (verifiedField.value is Map) {
            final valueMap = verifiedField.value as Map;
            displayValue = valueMap.values
                .where((v) => v != null && v.toString().isNotEmpty)
                .join(', ');
          } else {
            displayValue = verifiedField.value.toString();
          }

          if (displayValue.isNotEmpty) {
            info[verifiedField.label] = displayValue;
          }
        }
      }
    }

    // Show verification status information
    if (status.isVerified) {
      info['Verification Status'] = 'Verified';
      if (status.verificationDate != null) {
        info['Verification Date'] = status.verificationDate!;
      }
      if (status.verifiedByName != null) {
        info['Verified By'] = status.verifiedByName!;
      }
    } else if (status.isSubmittedForReview) {
      info['Status'] = 'Submitted for Review';
    } else {
      info['Status'] = 'Pending Submission';
    }

    return info;
  }

  List<String> _getMissingFinalInfo(VerificationStatus status) {
    final missing = <String>[];

    // Get missing final step fields from API data
    final finalStep = status.missingInformation.byStep['final'];
    if (finalStep != null) {
      // Add issues/missing items
      if (finalStep.issues.isNotEmpty) {
        missing.addAll(finalStep.issues);
      }

      // Check required fields that don't have verified values
      final verifiedFieldNames = finalStep.verifiedFields
          .where((field) => field.isVerified)
          .map((field) => field.field)
          .toSet();

      for (final requiredField in finalStep.requiredFields) {
        if (!verifiedFieldNames.contains(requiredField)) {
          final displayName = _formatFieldName(requiredField);
          if (!missing.contains(displayName)) {
            missing.add(displayName);
          }
        }
      }
    }

    // Check if ready for submission but not submitted
    if (!status.isSubmittedForReview && !status.isVerified) {
      if (status.missingInformation.isReadyForApproval) {
        missing.add('Submit for admin review');
      } else {
        missing.add('Complete all previous steps before submission');
      }
    }

    // If submitted but not verified, show pending status (unless already complete)
    final isComplete = finalStep?.status == 'complete' || status.isVerified;
    if (status.isSubmittedForReview && !status.isVerified && !isComplete) {
      missing.add('Waiting for admin review');
    }

    return missing;
  }
}
