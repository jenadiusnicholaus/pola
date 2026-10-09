import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:localization_lite/translate.dart';

/// App-wide content language preference ('en' or 'sw').
///
/// Some APIs return localized data (e.g. legal education topics/materials
/// support `language=en|sw`). Screens use this service as the default language
/// when no explicit per-item language was chosen by the user.
class LanguageService extends GetxService {
  static const String _storageKey = 'preferred_language';

  final GetStorage _storage = GetStorage();

  /// Reactive language code. Either 'en' or 'sw'.
  final RxString languageObs = 'en'.obs;

  /// Current language code ('en' or 'sw').
  String get language => languageObs.value;

  /// Alias used when calling APIs — same values ('en' | 'sw').
  String get apiCode => language;

  bool get isSwahili => language == 'sw';
  bool get isEnglish => language == 'en';

  /// Human-readable name for the current selection.
  String get displayName => isSwahili ? 'Kiswahili' : 'English';

  @override
  void onInit() {
    super.onInit();
    final stored = _storage.read<String>(_storageKey);
    if (stored != null && (stored == 'en' || stored == 'sw')) {
      languageObs.value = stored;
    }
    _loadTranslations(language);
  }

  /// Persist and apply a new preferred language.
  Future<void> setLanguage(String code) async {
    if (code != 'en' && code != 'sw') return;
    languageObs.value = code;
    _storage.write(_storageKey, code);
    await _loadTranslations(code);
    // localization_lite isn't reactive — rebuild the whole app tree so all
    // tr('...') lookups re-resolve in the new language.
    Get.forceAppUpdate();
  }

  /// Loads assets/localization/<code>.json into Translate's static map.
  /// English keys fall back to themselves, so a missing file is harmless.
  Future<void> _loadTranslations(String code) async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/localization/$code.json');
      Translate.json = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      Translate.json = {};
    }
  }

  /// Resolve an explicitly chosen language (e.g. a per-topic EN/SW button),
  /// falling back to the user's stored preference when null.
  String prefer(String? explicit) => explicit ?? apiCode;
}
