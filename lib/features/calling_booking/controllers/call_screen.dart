import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/call_controller.dart';
import '../models/consultant_models.dart';
import '../../../routes/app_routes.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  CallController? controller;
  Consultant? consultant;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    try {
      // Get consultant from arguments
      final args = Get.arguments;
      if (args == null || args is! Map || !args.containsKey('consultant')) {
        _hasError = true;
        _errorMessage = 'No consultant data provided';
        return;
      }

      consultant = args['consultant'] as Consultant;

      // Initialize controller
      controller = Get.put(CallController());

      // Start call
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (consultant != null && controller != null) {
          controller!.initiateCall(consultant!);
        }
      });
    } catch (e) {
      print('Error initializing call screen: $e');
      _hasError = true;
      _errorMessage = 'Failed to initialize call: ${e.toString()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show error if initialization failed
    if (_hasError || consultant == null || controller == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Call'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage.isNotEmpty
                      ? _errorMessage
                      : 'Failed to load call',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        // If there's an error (insufficient credits), allow direct back navigation
        if (controller!.error.value.isNotEmpty) {
          return true;
        }
        // If call is in progress, show end call dialog
        _showEndCallDialog();
        return false;
      },
      child: Obx(() {
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            title: Text(
              controller!.error.value.isNotEmpty
                  ? (controller!.isInsufficientCreditsError
                      ? 'Insufficient Credits'
                      : 'Call Failed')
                  : 'Voice Call',
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // If there's an error, go back directly
                if (controller!.error.value.isNotEmpty) {
                  Get.back();
                } else {
                  // If call is in progress, show end call dialog
                  _showEndCallDialog();
                }
              },
            ),
          ),
          body: SafeArea(
            child: Obx(() {
              // Show loading while checking credits
              if (controller!.isCheckingCredits.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Checking credits...',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Show error if any
              if (controller!.error.value.isNotEmpty) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        controller!.isInsufficientCreditsError
                            ? Icons.account_balance_wallet_outlined
                            : Icons.error_outline,
                        size: 80,
                        color: controller!.isInsufficientCreditsError
                            ? theme.colorScheme.primary.withOpacity(0.5)
                            : theme.colorScheme.error.withOpacity(0.5),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        controller!.isInsufficientCreditsError
                            ? 'Insufficient Credits'
                            : 'Call Failed',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        controller!.error.value,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Show available bundles only if it's a credit error
                      if (controller!.isInsufficientCreditsError &&
                          controller!.availableBundles.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Text(
                          'Available Packages',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...controller!.availableBundles.map((bundle) {
                          return Obx(() {
                            final isSelected =
                                controller!.selectedBundleId.value == bundle.id;
                            return InkWell(
                              onTap: () => controller!.selectBundle(bundle.id),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primaryContainer
                                          .withOpacity(0.3)
                                      : theme
                                          .colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline
                                            .withOpacity(0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              if (isSelected)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 8),
                                                  child: Icon(
                                                    Icons.check_circle,
                                                    color: theme
                                                        .colorScheme.primary,
                                                    size: 20,
                                                  ),
                                                ),
                                              Expanded(
                                                child: Text(
                                                  bundle.name,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme
                                                        .colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme
                                                    .primaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            bundle.priceFormatted,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? theme.colorScheme.onPrimary
                                                  : theme.colorScheme
                                                      .onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${bundle.minutes} minutes',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Valid ${bundle.validityDays} days',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (bundle.description.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        bundle.description,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          });
                        }).toList(),
                      ],

                      const SizedBox(height: 32),
                      Obx(() {
                        final selectedBundle = controller!.selectedBundle;
                        return Column(
                          children: [
                            if (selectedBundle != null)
                              Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Selected Package',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          selectedBundle.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      selectedBundle.priceFormatted,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: selectedBundle != null
                                    ? () {
                                        Get.toNamed(
                                          AppRoutes.payment,
                                          arguments: {'bundle': selectedBundle},
                                        );
                                      }
                                    : null,
                                icon: const Icon(Icons.shopping_cart),
                                label: Text(selectedBundle != null
                                    ? 'Checkout - ${selectedBundle.priceFormatted}'
                                    : 'Select a Package'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: selectedBundle != null
                                      ? theme.colorScheme.primary
                                      : theme
                                          .colorScheme.surfaceContainerHighest,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              }

              // Call in progress
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top section - Consultant info
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        // Avatar
                        CircleAvatar(
                          radius: 60,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          child: Text(
                            consultant!.userDetails.firstName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Name
                        Text(
                          consultant!.userDetails.fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Type
                        Text(
                          consultant!.consultantType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Call status
                        Text(
                          controller!.isCallConnected.value
                              ? 'Connected'
                              : 'Connecting...',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Duration
                        Text(
                          controller!.callDuration.value,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w300,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom section - Controls
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        // Credits remaining
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${controller!.creditsRemaining.value} minutes remaining',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Call controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Note: With ZegoCloud prebuilt UI, mute/speaker/end call
                            // buttons are handled by the ZegoUIKitPrebuiltCall widget

                            // End call button
                            _buildCallButton(
                              icon: Icons.call_end,
                              label: 'End Call',
                              onPressed: () => _showEndCallDialog(),
                              backgroundColor: theme.colorScheme.error,
                              iconColor: theme.colorScheme.onError,
                              size: 70,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
    double size = 60,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: iconColor),
            iconSize: size * 0.45,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  void _showEndCallDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('End Call?'),
        content: const Text('Are you sure you want to end this call?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              controller?.endCall();
            },
            child: const Text('End Call'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.endCall();
    super.dispose();
  }
}
