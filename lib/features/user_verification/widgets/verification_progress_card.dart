import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/verification_controller.dart';

class VerificationProgressCard extends StatelessWidget {
  const VerificationProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.find<VerificationController>(tag: 'verification_screen');

    return Obx(() {
      if (!controller.hasVerificationData) {
        return const SizedBox.shrink();
      }

      final progress = controller.verificationProgress;
      final status = controller.verificationStatus!;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    status.isVerified ? Icons.verified : Icons.timeline,
                    color: status.isVerified
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Verification Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${progress.toInt()}%',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: status.isVerified
                              ? Colors.green
                              : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress Bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _getProgressBackgroundColor(
                      context, progress, status.isVerified),
                  border: Border.all(
                    color:
                        _getProgressColor(context, progress, status.isVerified)
                            .withOpacity(0.2),
                  ),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: _getProgressGradient(
                          context, progress, status.isVerified),
                      boxShadow: progress > 0
                          ? [
                              BoxShadow(
                                color: _getProgressColor(
                                        context, progress, status.isVerified)
                                    .withOpacity(0.3),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Current Step
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: status.isVerified
                          ? Colors.green.withOpacity(0.1)
                          : Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: status.isVerified
                            ? Colors.green.withOpacity(0.3)
                            : Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          status.isVerified
                              ? Icons.check_circle
                              : Icons.radio_button_checked,
                          size: 12,
                          color: status.isVerified
                              ? Colors.green
                              : Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status.isVerified
                              ? 'Verification Complete'
                              : 'Current Step: ${status.currentStepDisplay}',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: status.isVerified
                                        ? Colors.green
                                        : Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Days since registration
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${status.daysSinceRegistration} days since registration',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),

              // Verification details for completed status
              if (status.isVerified) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Verification Complete',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      if (status.verifiedByName != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Verified by: ${status.verifiedByName}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.green.shade700,
                                  ),
                        ),
                      ],
                      if (status.verificationDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Date: ${_formatDate(status.verificationDate!)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.green.shade700,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Color _getProgressColor(
      BuildContext context, double progress, bool isVerified) {
    // If fully verified, always show bright green
    if (progress >= 100 && isVerified) {
      return Colors.green[600]!; // Bright green for verified completion
    }
    // If 100% but not verified (waiting for review), show amber
    else if (progress >= 100) {
      return Colors.amber[600]!; // Amber for complete but pending verification
    }
    // Progressive color changes based on percentage
    else if (progress >= 80) {
      return Colors.lightGreen[600]!; // Light green for near completion
    } else if (progress >= 60) {
      return Colors.lime[600]!; // Lime for good progress
    } else if (progress >= 40) {
      return Colors.amber[600]!; // Amber for moderate progress
    } else if (progress >= 20) {
      return Colors.orange[600]!; // Orange for early progress
    } else if (progress > 0) {
      return Colors.deepOrange[600]!; // Deep orange for minimal progress
    } else {
      return Colors.red[600]!; // Red for no progress
    }
  }

  LinearGradient _getProgressGradient(
      BuildContext context, double progress, bool isVerified) {
    final baseColor = _getProgressColor(context, progress, isVerified);

    // Create a subtle gradient for visual enhancement
    return LinearGradient(
      colors: [
        baseColor.withOpacity(0.8),
        baseColor,
        baseColor.withOpacity(0.9),
      ],
      stops: const [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color _getProgressBackgroundColor(
      BuildContext context, double progress, bool isVerified) {
    // Subtle tinted background based on progress status
    if (progress >= 100 && isVerified) {
      return Colors.green
          .withOpacity(0.08); // Light green background for verified
    } else if (progress >= 100) {
      return Colors.amber
          .withOpacity(0.08); // Light amber for complete but unverified
    } else if (progress >= 50) {
      return Colors.blue.withOpacity(0.05); // Light blue for good progress
    } else if (progress > 0) {
      return Colors.orange.withOpacity(0.05); // Light orange for some progress
    } else {
      return Theme.of(context)
          .colorScheme
          .onSurface
          .withOpacity(0.05); // Neutral for no progress
    }
  }
}
