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
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  subscription.isActive
                      ? Icons.workspace_premium
                      : Icons.info_outline,
                  color: subscription.isActive ? activeColor : inactiveColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.planName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subscription.planNameSw,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: subscription.isActive ? activeColor : inactiveColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    subscription.status.toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.1),
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
