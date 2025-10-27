import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/verification_controller.dart';

class VerificationStepsCard extends StatelessWidget {
  const VerificationStepsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.find<VerificationController>(tag: 'verification_screen');

    return Obx(() {
      if (!controller.hasVerificationData) {
        return const SizedBox.shrink();
      }

      final status = controller.verificationStatus!;
      final steps = _getVerificationSteps(status.currentStep);

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.list_alt,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Verification Steps',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'Follow these steps to complete your verification:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),

              // Verification Steps
              ...steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                final isLast = index == steps.length - 1;

                return _buildStepItem(
                  context,
                  step,
                  index + 1,
                  isLast,
                  status.currentStep,
                );
              }),

              // Submit for review button
              if (status.currentStep == 'final' &&
                  !status.isVerified &&
                  !status.isSubmittedForReview) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.send,
                        color: Theme.of(context).primaryColor,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ready to Submit',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All required information and documents have been provided. Submit for admin review.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: controller.isLoading
                              ? null
                              : () => controller.submitForReview(),
                          icon: controller.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send),
                          label: Text(controller.isLoading
                              ? 'Submitting...'
                              : 'Submit for Review'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Submitted for review status
              if (status.isSubmittedForReview && !status.isVerified) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        color: Colors.blue[600],
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Under Review',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your verification request is being reviewed by our admin team. You will be notified once the review is complete.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.blue[700],
                            ),
                        textAlign: TextAlign.center,
                      ),
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

  Widget _buildStepItem(BuildContext context, VerificationStep step,
      int stepNumber, bool isLast, String currentStep) {
    final isCurrentOrPast = _isCurrentOrPastStep(step.stepKey, currentStep);
    final isCurrent = step.stepKey == currentStep;
    final isPast = _isStepCompleted(step.stepKey, currentStep);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isPast
                    ? Colors.green[600]
                    : isCurrent
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isPast
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : Text(
                        stepNumber.toString(),
                        style: TextStyle(
                          color:
                              isCurrentOrPast ? Colors.white : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isPast ? Colors.green[300] : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),

        // Step content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.w500,
                        color:
                            isCurrentOrPast ? Colors.black87 : Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isCurrentOrPast
                            ? Colors.grey[600]
                            : Colors.grey[500],
                      ),
                ),

                // Current step indicator
                if (isCurrent) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Current Step',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<VerificationStep> _getVerificationSteps(String currentStep) {
    return [
      const VerificationStep(
        stepKey: 'documents',
        title: 'Upload Documents',
        description: 'Submit required identity and professional documents',
      ),
      const VerificationStep(
        stepKey: 'identity',
        title: 'Identity Verification',
        description: 'Verify your personal identity information',
      ),
      const VerificationStep(
        stepKey: 'contact',
        title: 'Contact Information',
        description: 'Provide and verify contact details',
      ),
      const VerificationStep(
        stepKey: 'role_specific',
        title: 'Professional Information',
        description: 'Complete role-specific requirements and details',
      ),
      const VerificationStep(
        stepKey: 'final',
        title: 'Final Review',
        description: 'Submit for admin review and approval',
      ),
    ];
  }

  bool _isCurrentOrPastStep(String stepKey, String currentStep) {
    final stepOrder = [
      'documents',
      'identity',
      'contact',
      'role_specific',
      'final'
    ];
    final currentIndex = stepOrder.indexOf(currentStep);
    final stepIndex = stepOrder.indexOf(stepKey);
    return stepIndex <= currentIndex;
  }

  bool _isStepCompleted(String stepKey, String currentStep) {
    final stepOrder = [
      'documents',
      'identity',
      'contact',
      'role_specific',
      'final'
    ];
    final currentIndex = stepOrder.indexOf(currentStep);
    final stepIndex = stepOrder.indexOf(stepKey);
    return stepIndex < currentIndex;
  }
}

class VerificationStep {
  final String stepKey;
  final String title;
  final String description;

  const VerificationStep({
    required this.stepKey,
    required this.title,
    required this.description,
  });
}
