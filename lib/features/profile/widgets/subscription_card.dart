import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/profile_models.dart';

class SubscriptionCard extends StatelessWidget {
  final SubscriptionInfo subscription;
  final VoidCallback? onUpgrade;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.primary;
    final isExpired = !subscription.isActive;
    final expiredColor = theme.colorScheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired 
              ? expiredColor.withOpacity(0.5)
              : theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: isExpired ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                subscription.isActive
                    ? Icons.workspace_premium
                    : Icons.warning_amber_rounded,
                color: subscription.isActive
                    ? activeColor
                    : expiredColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.planName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isExpired 
                            ? theme.colorScheme.onSurface.withOpacity(0.6)
                            : theme.colorScheme.onSurface,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subscription.planNameSw,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: subscription.isActive
                      ? activeColor.withOpacity(0.1)
                      : expiredColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: subscription.isActive
                        ? activeColor.withOpacity(0.3)
                        : expiredColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  subscription.status.toUpperCase(),
                  style: TextStyle(
                    color: subscription.isActive
                        ? activeColor
                        : expiredColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Expired message
          if (isExpired)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: expiredColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: expiredColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: expiredColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your subscription has expired. Renew to unlock all features.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : expiredColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Days remaining (if active)
          if (subscription.isActive)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Days Remaining:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${subscription.daysRemaining} days',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: subscription.daysRemaining < 7
                        ? Theme.of(context).colorScheme.error
                        : activeColor,
                  ),
                ),
              ],
            ),

          if (subscription.isTrial)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '🎉 Trial Period',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Key Permissions
          const SizedBox(height: 16),
          Text(
            'Key Features:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isExpired 
                  ? theme.colorScheme.onSurface.withOpacity(0.5)
                  : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          // When expired, show all features as disabled
          _buildPermissionChip(
            'Legal Library',
            isExpired ? false : subscription.permissions.canAccessLegalLibrary,
            isExpired: isExpired,
          ),
          _buildPermissionChip(
            'Ask Questions (${subscription.permissions.questionsRemaining}/${subscription.permissions.questionsLimit})',
            isExpired ? false : subscription.permissions.canAskQuestions,
            isExpired: isExpired,
          ),
          _buildPermissionChip(
            'Generate Documents',
            isExpired ? false : subscription.permissions.canGenerateDocuments,
            isExpired: isExpired,
          ),
          _buildPermissionChip(
            'Forum Access',
            isExpired ? false : subscription.permissions.canAccessForum,
            isExpired: isExpired,
          ),

          // Upgrade button when expired
          if (isExpired) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onUpgrade ?? () {
                  Get.toNamed('/subscription-plans');
                },
                icon: const Icon(Icons.diamond_outlined, size: 18),
                label: const Text(
                  'Upgrade to Premium',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionChip(String label, bool enabled, {bool isExpired = false}) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final disabledColor = theme.colorScheme.onSurface.withOpacity(0.3);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(
            children: [
              Icon(
                enabled ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: isExpired
                    ? disabledColor
                    : (enabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error.withOpacity(0.7)),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isExpired
                      ? disabledColor
                      : (enabled
                          ? theme.textTheme.bodyLarge?.color
                          : theme.textTheme.bodySmall?.color),
                  decoration: isExpired ? TextDecoration.lineThrough : null,
                  decorationColor: disabledColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
