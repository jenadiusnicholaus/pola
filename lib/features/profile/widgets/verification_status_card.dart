import 'package:flutter/material.dart';
import '../models/profile_models.dart';

class VerificationStatusCard extends StatelessWidget {
  final VerificationStatus status;

  const VerificationStatusCard({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isVerified = status.status == 'Verified';
    final isPending = status.status == 'Pending Verification';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final successColor = Theme.of(context).colorScheme.primary;
    final warningColor = Theme.of(context).colorScheme.error.withOpacity(0.7);
    final errorColor = Theme.of(context).colorScheme.error;

    return Card(
      elevation: isDark ? 3 : 2,
      color: isVerified
          ? (isDark
              ? successColor.withOpacity(0.15)
              : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3))
          : isPending
              ? (isDark
                  ? warningColor.withOpacity(0.15)
                  : Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withOpacity(0.2))
              : (isDark
                  ? errorColor.withOpacity(0.15)
                  : Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withOpacity(0.3)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isVerified
              ? successColor.withOpacity(0.3)
              : isPending
                  ? warningColor.withOpacity(0.3)
                  : errorColor.withOpacity(0.3),
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
                  isVerified
                      ? Icons.verified_user
                      : isPending
                          ? Icons.pending
                          : Icons.error,
                  color: isVerified
                      ? successColor
                      : isPending
                          ? warningColor
                          : errorColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status.status,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Current Step
            Text(
              'Current Step: ${status.currentStep}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // Progress Bar
            LinearProgressIndicator(
              value: status.progress / 100,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isVerified
                    ? successColor
                    : isPending
                        ? warningColor
                        : errorColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${status.progress.toStringAsFixed(0)}% Complete',
              style: const TextStyle(fontSize: 12),
            ),

            // Notes
            if (status.notes != null && status.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.notes!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
