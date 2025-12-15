import 'package:flutter/material.dart';
import '../models/profile_models.dart';

class SubscriptionCard extends StatelessWidget {
  final SubscriptionInfo subscription;

  const SubscriptionCard({
    super.key,
    required this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
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
                    : Icons.info_outline,
                color: subscription.isActive
                    ? activeColor
                    : theme.colorScheme.onSurface.withOpacity(0.4),
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
                        color: theme.colorScheme.onSurface,
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
              Text(
                subscription.status.toUpperCase(),
                style: TextStyle(
                  color: subscription.isActive
                      ? activeColor
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
          const Text(
            'Key Features:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildPermissionChip(
            'Legal Library',
            subscription.permissions.canAccessLegalLibrary,
          ),
          _buildPermissionChip(
            'Ask Questions (${subscription.permissions.questionsRemaining}/${subscription.permissions.questionsLimit})',
            subscription.permissions.canAskQuestions,
          ),
          _buildPermissionChip(
            'Generate Documents',
            subscription.permissions.canGenerateDocuments,
          ),
          _buildPermissionChip(
            'Forum Access',
            subscription.permissions.canAccessForum,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionChip(String label, bool enabled) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Row(
          children: [
            Icon(
              enabled ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: enabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: enabled
                    ? Theme.of(context).textTheme.bodyLarge?.color
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
