import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/permission_service.dart';
import '../../../shared/widgets/permission_gate.dart';
import '../../../constants/app_colors.dart';

/// Example screen showing how to use permission-based features
/// This demonstrates various ways to implement permission gates
class PermissionExampleScreen extends StatelessWidget {
  const PermissionExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final permissionService = Get.find<PermissionService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission System Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              // Debug permissions in console
              permissionService.debugPermissions();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subscription status banner
            const SubscriptionStatusBanner(),
            const SizedBox(height: 24),

            // Subscription info card
            _buildSubscriptionInfoCard(context, permissionService),
            const SizedBox(height: 24),

            // Example 1: Permission Gate with overlay
            _buildExample1(context),
            const SizedBox(height: 24),

            // Example 2: Permission Menu Items
            _buildExample2(context),
            const SizedBox(height: 24),

            // Example 3: Quota Indicators
            _buildExample3(context, permissionService),
            const SizedBox(height: 24),

            // Example 4: Manual Permission Check
            _buildExample4(context, permissionService),
            const SizedBox(height: 24),

            // Example 5: Feature with Quota
            _buildExample5(context, permissionService),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionInfoCard(
      BuildContext context, PermissionService permissionService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.card_membership,
                  color: AppColors.primaryAmber,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Subscription',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Plan', permissionService.planName),
            _buildInfoRow('Status', permissionService.statusBadgeText),
            _buildInfoRow(
                'Days Remaining', permissionService.daysRemainingText),
            _buildInfoRow(
                'Trial', permissionService.isTrialSubscription ? 'Yes' : 'No'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  /// Example 1: Using PermissionGate widget with locked overlay
  Widget _buildExample1(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Example 1: Permission Gate with Overlay',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'The legal library content is wrapped in a PermissionGate. If the user doesn\'t have access, a lock overlay is shown.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        PermissionGate(
          feature: PermissionFeature.legalLibrary,
          child: Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.library_books, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Legal Library Content',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'This content is only visible to users with Legal Library access. It contains important legal resources, case studies, and reference materials.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Example 2: Using PermissionMenuItem for navigation
  Widget _buildExample2(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Example 2: Permission Menu Items',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Menu items that check permissions before allowing navigation. Locked items show upgrade dialog.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              PermissionMenuItem(
                feature: PermissionFeature.legalLibrary,
                icon: Icons.library_books,
                title: 'Legal Library',
                subtitle: 'Access legal resources',
                onTap: () {
                  Get.snackbar(
                    'Success',
                    'Navigating to Legal Library',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              const Divider(height: 1),
              PermissionMenuItem(
                feature: PermissionFeature.forum,
                icon: Icons.forum,
                title: 'Legal Forum',
                subtitle: 'Join discussions',
                onTap: () {
                  Get.snackbar(
                    'Success',
                    'Navigating to Forum',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              const Divider(height: 1),
              PermissionMenuItem(
                feature: PermissionFeature.studentHub,
                icon: Icons.school,
                title: 'Student Hub',
                subtitle: 'Educational resources',
                onTap: () {
                  Get.snackbar(
                    'Success',
                    'Navigating to Student Hub',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Example 3: Quota Indicators
  Widget _buildExample3(
      BuildContext context, PermissionService permissionService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Example 3: Quota Indicators',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Shows remaining quota for features with usage limits.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Questions Quota',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const QuotaIndicator(
                      feature: PermissionFeature.askQuestions,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Documents Quota',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const QuotaIndicator(
                      feature: PermissionFeature.generateDocuments,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Example 4: Manual Permission Checks
  Widget _buildExample4(
      BuildContext context, PermissionService permissionService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Example 4: Manual Permission Checks',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Using PermissionService directly in code to check permissions.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPermissionStatusRow(
                  context,
                  'Legal Library',
                  permissionService.canAccessLegalLibrary,
                ),
                _buildPermissionStatusRow(
                  context,
                  'Ask Questions',
                  permissionService.canAskQuestion,
                ),
                _buildPermissionStatusRow(
                  context,
                  'Generate Documents',
                  permissionService.canGenerateDocument,
                ),
                _buildPermissionStatusRow(
                  context,
                  'Forum Access',
                  permissionService.canAccessForum,
                ),
                _buildPermissionStatusRow(
                  context,
                  'Student Hub',
                  permissionService.canAccessStudentHub,
                ),
                _buildPermissionStatusRow(
                  context,
                  'Purchase Consultations',
                  permissionService.canPurchaseConsultations,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionStatusRow(
      BuildContext context, String feature, bool hasAccess) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(feature),
          Row(
            children: [
              Icon(
                hasAccess ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: hasAccess ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                hasAccess ? 'Allowed' : 'Denied',
                style: TextStyle(
                  color: hasAccess ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Example 5: Feature with Quota Check
  Widget _buildExample5(
      BuildContext context, PermissionService permissionService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Example 5: Feature with Quota Check',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Checking both permission AND quota before allowing action.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ask a Legal Question',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const QuotaIndicator(
                      feature: PermissionFeature.askQuestions,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'You can ask questions to get expert legal advice. Each question uses one credit from your quota.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: permissionService.canAskQuestion
                        ? () {
                            Get.snackbar(
                              'Success',
                              'Opening question form...',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.question_answer),
                    label: Text(
                      permissionService.canAskQuestion
                          ? 'Ask Question'
                          : permissionService.canAskQuestions
                              ? 'No Questions Remaining'
                              : 'Upgrade to Ask Questions',
                    ),
                  ),
                ),
                if (!permissionService.canAskQuestion &&
                    permissionService.isSubscriptionActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      permissionService.getPermissionDeniedMessage(
                          PermissionFeature.askQuestions),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
