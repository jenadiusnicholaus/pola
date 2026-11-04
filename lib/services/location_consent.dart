import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:localization_lite/translate.dart';

/// Google Play requires a "prominent disclosure" before an app accesses
/// sensitive data such as device location. This helper shows that
/// disclosure once and persists the user's choice.
///
/// Call [ensure] before every `Geolocator.requestPermission()`:
/// it returns true when location may be requested, false otherwise.
class LocationConsent {
  LocationConsent._();

  static const String _key = 'location_disclosure_choice';
  static final GetStorage _storage = GetStorage();
  static bool _dialogShowing = false;

  static String? get _choice => _storage.read(_key);

  /// Returns true if location access may be requested.
  ///
  /// [userInitiated] should be true when the call comes from a direct user
  /// action (e.g. tapping "Enable GPS" or opening the Nearby Lawyers
  /// screen). A previous decline is only re-prompted for user-initiated
  /// calls so passive callers don't spam the dialog.
  static Future<bool> ensure({bool userInitiated = false}) async {
    final choice = _choice;
    if (choice == 'accepted') return true;
    if (choice == 'declined' && !userInitiated) return false;
    if (_dialogShowing || Get.context == null) return false;

    _dialogShowing = true;
    try {
      final accepted = await Get.dialog<bool>(
        AlertDialog(
          title: Text(tr('Location access')),
          content: Text(tr(
            'Pola collects your device\'s precise location to show lawyers '
            'and legal services near you, and keeps your location updated '
            'on our servers while the app is in use. This data is linked '
            'to your account.\n\n'
            'You can decline — the app still works, but nearby results '
            'will be limited.',
          )),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text(tr('No thanks')),
            ),
            FilledButton(
              onPressed: () => Get.back(result: true),
              child: Text(tr('Allow')),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      if (accepted == true) {
        await _storage.write(_key, 'accepted');
        return true;
      }
      await _storage.write(_key, 'declined');
      return false;
    } finally {
      _dialogShowing = false;
    }
  }
}
