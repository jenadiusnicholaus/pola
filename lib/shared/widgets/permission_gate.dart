import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../services/permission_service.dart';
import '../../constants/app_colors.dart';
import '../../routes/app_routes.dart';

/// Widget that gates content based on permissions
/// Shows upgrade prompt if user doesn't have access
class PermissionGate extends StatelessWidget {
  final PermissionFeature feature;
  final Widget child;
  final Widget? upgradeWidget;
  final bool showLockedOverlay;
  final VoidCallback? onUpgradePressed;

  const PermissionGate({
    super.key,
    required this.feature,
    required this.child,
    this.upgradeWidget,
    this.showLockedOverlay = true,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    final permissionService = Get.find<PermissionService>();

    if (permissionService.canAccess(feature)) {
      return child;
    }

    // Feature is locked
    if (upgradeWidget != null) {
      return upgradeWidget!;
    }

    if (showLockedOverlay) {
      return _buildLockedOverlay(context, permissionService);
    }

    return const SizedBox.shrink();
  }

  Widget _buildLockedOverlay(
      BuildContext context, PermissionService permissionService) {
    return Stack(
      children: [
        // Grayed out content
        Opacity(
          opacity: 0.3,
          child: IgnorePointer(
            child: child,
          ),
        ),
        // Lock overlay
        Positioned.fill(
          child: Container(
            color: Colors.black26,
            child: Center(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: AppColors.primaryAmber,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Feature Locked',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        permissionService.getPermissionDeniedMessage(feature),
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: onUpgradePressed ??
                            () {
                              Get.toNamed(AppRoutes.subscriptionPlans);
                            },
                        icon: const Icon(Icons.arrow_upward),
                        label: const Text('Upgrade Now'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget for menu items that require permissions
class PermissionMenuItem extends StatelessWidget {
  final PermissionFeature feature;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showLockIcon;

  const PermissionMenuItem({
    super.key,
    required this.feature,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.showLockIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final permissionService = Get.find<PermissionService>();
    final hasAccess = permissionService.canAccess(feature);

    return ListTile(
      leading: Icon(
        icon,
        color: hasAccess ? AppColors.primaryAmber : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: hasAccess ? null : Colors.grey,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: hasAccess ? null : Colors.grey,
              ),
            )
          : null,
      trailing: showLockIcon && !hasAccess
          ? Icon(Icons.lock_outline, color: Colors.grey.shade400)
          : const Icon(Icons.chevron_right),
      onTap: hasAccess
          ? onTap
          : () {
              _showUpgradeDialog(context, permissionService);
            },
    );
  }

  void _showUpgradeDialog(
      BuildContext context, PermissionService permissionService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade Required'),
        content: Text(permissionService.getPermissionDeniedMessage(feature)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Get.toNamed(AppRoutes.subscriptionPlans);
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}

/// Widget showing quota remaining for limited features
class QuotaIndicator extends StatelessWidget {
  final PermissionFeature feature;
  final bool showIcon;

  const QuotaIndicator({
    super.key,
    required this.feature,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final permissionService = Get.find<PermissionService>();

    String quotaText;
    int remaining;
    int total;
    bool hasAccess;

    if (feature == PermissionFeature.askQuestions) {
      quotaText = permissionService.questionsQuotaText;
      remaining = permissionService.questionsRemaining;
      total = permissionService.questionsLimit;
      hasAccess = permissionService.canAskQuestions;
    } else if (feature == PermissionFeature.generateDocuments) {
      quotaText = permissionService.documentsQuotaText;
      remaining = permissionService.documentsRemaining;
      total = permissionService.freeDocumentsLimit;
      hasAccess = permissionService.canGenerateDocuments;
    } else {
      return const SizedBox.shrink();
    }

    if (!hasAccess) {
      return Chip(
        avatar: showIcon ? const Icon(Icons.lock, size: 16) : null,
        label: const Text('Not available'),
        backgroundColor: Colors.grey.shade200,
      );
    }

    // Color coding based on remaining quota
    Color backgroundColor;
    if (remaining == 0) {
      backgroundColor = Colors.red.shade100;
    } else if (remaining <= total * 0.2) {
      // 20% or less remaining
      backgroundColor = Colors.orange.shade100;
    } else {
      backgroundColor = Colors.green.shade100;
    }

    return Chip(
      avatar: showIcon
          ? Icon(
              _getIconForFeature(feature),
              size: 16,
            )
          : null,
      label: Text(quotaText),
      backgroundColor: backgroundColor,
    );
  }

  IconData _getIconForFeature(PermissionFeature feature) {
    switch (feature) {
      case PermissionFeature.askQuestions:
        return Icons.question_answer;
      case PermissionFeature.generateDocuments:
        return Icons.description;
      default:
        return Icons.info;
    }
  }
}

/// Widget showing subscription status banner
class SubscriptionStatusBanner extends StatelessWidget {
  final bool showUpgradeButton;

  const SubscriptionStatusBanner({
    super.key,
    this.showUpgradeButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final permissionService = Get.find<PermissionService>();
    final subscription = permissionService.subscription;

    // Debug subscription status
    if (kDebugMode && subscription != null) {
      debugPrint('🏠 Home Banner Check:');
      debugPrint('   subscription.isActive: ${subscription.isActive}');
      debugPrint(
          '   permissions.isActive: ${subscription.permissions.isActive}');
      debugPrint(
          '   isSubscriptionActive: ${permissionService.isSubscriptionActive}');
      debugPrint('   planName: ${subscription.planName}');
      debugPrint('   status: ${subscription.status}');
    }

    // Only show banner if subscription itself is not active
    // (Don't check permissions.isActive for banner display)
    if (subscription == null || !subscription.isActive) {
      return _buildInactiveBanner(context, permissionService);
    }

    if (permissionService.isExpiringSoon) {
      return _buildExpiringSoonBanner(context, permissionService);
    }

    if (permissionService.isTrialSubscription) {
      return _buildTrialBanner(context, permissionService);
    }

    return const SizedBox.shrink();
  }

  Widget _buildInactiveBanner(
      BuildContext context, PermissionService permissionService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.red.shade100,
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Active Subscription',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const Text(
                  'Subscribe now to access all features',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          if (showUpgradeButton)
            ElevatedButton(
              onPressed: () {
                Get.toNamed(AppRoutes.subscriptionPlans);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Subscribe'),
            ),
        ],
      ),
    );
  }

  Widget _buildExpiringSoonBanner(
      BuildContext context, PermissionService permissionService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.orange.shade100,
      child: Row(
        children: [
          Icon(Icons.access_time, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscription Expiring Soon',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                Text(
                  permissionService.daysRemainingText,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          if (showUpgradeButton)
            ElevatedButton(
              onPressed: () {
                Get.toNamed(AppRoutes.subscriptionPlans);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Renew'),
            ),
        ],
      ),
    );
  }

  Widget _buildTrialBanner(
      BuildContext context, PermissionService permissionService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade100,
      child: Row(
        children: [
          Icon(Icons.stars, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trial Subscription',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                Text(
                  permissionService.daysRemainingText,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          if (showUpgradeButton)
            ElevatedButton(
              onPressed: () {
                Get.toNamed(AppRoutes.subscriptionPlans);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upgrade'),
            ),
        ],
      ),
    );
  }
}
