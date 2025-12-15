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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final successColor = theme.colorScheme.primary;
    final warningColor = theme.colorScheme.error.withOpacity(0.7);
    final errorColor = theme.colorScheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified
              ? successColor.withOpacity(0.3)
              : isPending
                  ? warningColor.withOpacity(0.3)
                  : errorColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
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
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  status.status,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Current Step
          Text(
            'Current Step: ${status.currentStep}',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),

          // Progress Bar
          LinearProgressIndicator(
            value: status.progress / 100,
            backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
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
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),

          // Notes
          if (status.notes != null && status.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              status.notes!,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.65),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
