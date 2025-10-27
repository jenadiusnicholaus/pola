import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../profile/services/profile_service.dart';
import '../controllers/verification_controller.dart';
import '../screens/verification_screen.dart';

class ProfileVerificationCard extends StatefulWidget {
  const ProfileVerificationCard({super.key});

  @override
  State<ProfileVerificationCard> createState() =>
      _ProfileVerificationCardState();
}

class _ProfileVerificationCardState extends State<ProfileVerificationCard> {
  late final VerificationController verificationController;

  @override
  void initState() {
    super.initState();
    // Initialize verification controller to fetch status
    verificationController =
        Get.put(VerificationController(), tag: 'profile_verification');
  }

  @override
  void dispose() {
    Get.delete<VerificationController>(tag: 'profile_verification');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileService = Get.find<ProfileService>();

    return Obx(() {
      final user = profileService.currentProfile;

      // Only show for professional roles that require verification
      if (user == null || !_requiresVerification(user.userRole.roleName)) {
        return const SizedBox.shrink();
      }

      // Get verification status from controller
      final verificationStatus = verificationController.verificationStatus;
      final isVerified = verificationStatus?.isVerified ?? user.isVerified;
      final progress = verificationStatus?.progress ?? 0.0;

      // Theme adaptive colors
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final surfaceColor = theme.colorScheme.surface;
      final onSurfaceColor = theme.colorScheme.onSurface;

      final statusColor = isVerified
          ? Colors.green
          : (progress > 0 ? Colors.orange : Colors.grey);

      return Card(
        margin: EdgeInsets.zero,
        color: surfaceColor,
        elevation: isDark ? 2 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: statusColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _navigateToVerification(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isVerified ? Icons.verified : Icons.shield_outlined,
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isVerified
                                ? 'Account Verified'
                                : 'Verify Your Account',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isVerified
                                ? 'Your professional account has been verified'
                                : 'Complete verification to unlock all features',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: onSurfaceColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        if (!isVerified && progress > 0) ...[
                          Text(
                            '${progress.toInt()}%',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: onSurfaceColor.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ],
                ),

                // Progress bar for non-verified accounts
                if (!isVerified && progress > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: statusColor.withOpacity(isDark ? 0.2 : 0.1),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: statusColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    verificationStatus?.currentStepDisplay ??
                        'Getting started...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onSurfaceColor.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],

                if (!isVerified) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withOpacity(isDark ? 0.3 : 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Verification required for ${_getRoleDisplayName(user.userRole.roleName)} professionals',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _navigateToVerification(),
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: Text(progress > 0
                              ? 'Continue Verification'
                              : 'Start Verification'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: BorderSide(color: statusColor),
                            foregroundColor: statusColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.green.withOpacity(isDark ? 0.3 : 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your account is verified and all features are unlocked',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  bool _requiresVerification(String userRole) {
    return ['advocate', 'lawyer', 'law_firm', 'paralegal'].contains(userRole);
  }

  String _getRoleDisplayName(String userRole) {
    switch (userRole) {
      case 'advocate':
        return 'Advocate';
      case 'lawyer':
        return 'Lawyer';
      case 'law_firm':
        return 'Law Firm';
      case 'paralegal':
        return 'Paralegal';
      default:
        return 'Professional';
    }
  }

  void _navigateToVerification() {
    Get.to(() => const VerificationScreen());
  }
}
