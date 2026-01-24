import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/permission_service.dart';

/// Navigation helper to safely handle GetX navigation
/// This helps avoid the LateInitializationError with SnackbarController
class NavigationHelper {
  /// Safely close a dialog without trying to close snackbars
  /// Use this inside Get.dialog() button callbacks
  static void closeDialog() {
    if (Get.isDialogOpen == true) {
      Get.back(closeOverlays: false);
    }
  }

  /// Safely go back with optional result
  /// Use this when you want to avoid snackbar-related errors
  static void safeBack<T>({T? result}) {
    try {
      if (Get.isDialogOpen == true) {
        Get.back(result: result, closeOverlays: false);
      } else if (Get.isBottomSheetOpen == true) {
        Get.back(result: result, closeOverlays: false);
      } else {
        Get.back(result: result, closeOverlays: false);
      }
    } catch (e) {
      // Fallback: try without closeOverlays parameter
      try {
        Get.back(result: result);
      } catch (_) {
        // If all else fails, just ignore the error
      }
    }
  }

  /// Close all open overlays (dialogs, bottomsheets, snackbars)
  static void closeAllOverlays() {
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    if (Get.isDialogOpen == true) {
      Get.back(closeOverlays: false);
    }
    if (Get.isBottomSheetOpen == true) {
      Get.back(closeOverlays: false);
    }
  }

  /// Check permission and show upgrade dialog if not allowed
  /// Returns true if user has permission, false otherwise
  static bool checkPermissionOrShowUpgrade(
    BuildContext context,
    PermissionFeature feature, {
    String? customTitle,
    String? customMessage,
  }) {
    try {
      final permissionService = Get.find<PermissionService>();

      if (permissionService.canAccess(feature)) {
        return true;
      }

      // Show upgrade dialog
      _showPermissionUpgradeDialog(
        context,
        permissionService,
        feature,
        customTitle: customTitle,
        customMessage: customMessage,
      );
      return false;
    } catch (e) {
      debugPrint('⚠️ Permission check failed: $e');
      // If permission service not available, allow access (fallback)
      return true;
    }
  }

  /// Show the upgrade dialog for permission denied
  static void _showPermissionUpgradeDialog(
    BuildContext context,
    PermissionService permissionService,
    PermissionFeature feature, {
    String? customTitle,
    String? customMessage,
  }) {
    final theme = Theme.of(context);
    final isTrial = permissionService.isTrialSubscription;
    final message =
        customMessage ?? permissionService.getPermissionDeniedMessage(feature);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              isTrial ? Icons.stars : Icons.lock_outline,
              color: isTrial ? Colors.amber : theme.colorScheme.error,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                customTitle ??
                    (isTrial ? 'Trial Restriction' : 'Upgrade Required'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upgrade to Premium to unlock all features!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Later',
              style:
                  TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.toNamed('/subscription');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  /// Show upgrade dialog directly (for use outside of permission checks)
  static void showUpgradeDialog(
    BuildContext context, {
    String title = 'Upgrade Required',
    required String message,
  }) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: theme.colorScheme.error,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upgrade to Premium to unlock all features!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Later',
              style:
                  TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.toNamed('/subscription');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
}
