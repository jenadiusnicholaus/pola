import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/legal_education_models.dart';
import '../services/legal_education_service.dart';
import '../../../../services/token_storage_service.dart';

enum LanguageFilter { both, english, swahili }

class LegalEducationController extends GetxController {
  final LegalEducationService _service = Get.put(LegalEducationService());

  // Observable variables
  final RxList<Topic> _topics = <Topic>[].obs;
  final RxBool _isLoadingTopics = false.obs;
  final RxString _error = ''.obs;
  final Rx<LanguageFilter> _languageFilter = LanguageFilter.both.obs;
  final RxString _searchQuery = ''.obs;

  // Materials variables
  final RxList<LearningMaterial> _materials = <LearningMaterial>[].obs;
  final RxBool _isLoadingMaterials = false.obs;
  final RxString _materialsError = ''.obs;

  // Pagination variables
  final RxInt _currentTopicsPage = 1.obs;
  final RxInt _currentMaterialsPage = 1.obs;
  final RxBool _hasMoreTopics = true.obs;
  final RxBool _hasMoreMaterials = true.obs;
  static const int pageSize = 20;

  // Scroll controllers for infinite scroll
  late ScrollController topicsScrollController;
  late ScrollController materialsScrollController;

  // Current material's topic (for pagination)
  String? _currentMaterialsTopicSlug;
  String? _currentMaterialsLanguage;

  // Getters
  List<Topic> get topics => _topics;
  List<LearningMaterial> get materials => _materials;
  bool get isLoadingTopics => _isLoadingTopics.value;
  bool get isLoadingMaterials => _isLoadingMaterials.value;
  String get error => _error.value;
  String get materialsError => _materialsError.value;
  LanguageFilter get languageFilter => _languageFilter.value;
  String get searchQuery => _searchQuery.value;
  bool get hasMoreTopics => _hasMoreTopics.value;
  bool get hasMoreMaterials => _hasMoreMaterials.value;

  @override
  void onInit() {
    super.onInit();
    _initializeScrollControllers();
    _debugAuthStatus();
    fetchTopics();
  }

  void _debugAuthStatus() {
    try {
      final tokenService = Get.find<TokenStorageService>();
      print('🔍 DEBUG AUTH STATUS:');
      print('  - Is logged in: ${tokenService.isLoggedIn}');
      print('  - User email: ${tokenService.getUserEmail()}');
      print('  - User role: ${tokenService.getUserRole()}');
      print('  - Is verified: ${tokenService.isUserVerified()}');
      print('  - Access token length: ${tokenService.accessToken.length}');
    } catch (e) {
      print('❌ ERROR checking auth status: $e');
    }
  }

  @override
  void onClose() {
    topicsScrollController.dispose();
    materialsScrollController.dispose();
    super.onClose();
  }

  void _initializeScrollControllers() {
    topicsScrollController = ScrollController();
    materialsScrollController = ScrollController();

    // Add listeners for infinite scroll
    topicsScrollController.addListener(() {
      if (topicsScrollController.position.pixels >=
          topicsScrollController.position.maxScrollExtent * 0.8) {
        if (!_isLoadingTopics.value && _hasMoreTopics.value) {
          _loadMoreTopics();
        }
      }
    });

    materialsScrollController.addListener(() {
      if (materialsScrollController.position.pixels >=
          materialsScrollController.position.maxScrollExtent * 0.8) {
        if (!_isLoadingMaterials.value && _hasMoreMaterials.value) {
          _loadMoreMaterials();
        }
      }
    });
  }

  // Load topics (initial load or refresh)
  Future<void> fetchTopics({bool refresh = false}) async {
    // Store refresh state but don't clear list yet to prevent flickering
    if (refresh) {
      _currentTopicsPage.value = 1;
      _hasMoreTopics.value = true;
      // Don't clear the list here - wait until we have new data
    }

    try {
      _isLoadingTopics.value = true;
      _error.value = '';

      // Check if user is logged in
      final tokenService = Get.find<TokenStorageService>();
      await tokenService.waitForInitialization();

      print('📚 LEGAL EDU: Fetching topics...');
      print('📚 LEGAL EDU: Is logged in: ${tokenService.isLoggedIn}');
      print('📚 LEGAL EDU: Search query: ${_searchQuery.value}');
      print('📚 LEGAL EDU: Language: ${_getLanguageCode()}');
      print('📚 LEGAL EDU: Page: ${_currentTopicsPage.value}');

      final response = await _service.getTopics(
        search: _searchQuery.value.isEmpty ? null : _searchQuery.value,
        language: _getLanguageCode(),
        page: _currentTopicsPage.value,
        pageSize: pageSize,
      );

      print(
          '📚 LEGAL EDU: Response received with ${response.results.length} topics');

      // Now replace or add the data
      if (refresh) {
        _topics.assignAll(response.results);
      } else {
        _topics.addAll(response.results);
      }

      _hasMoreTopics.value = response.results.length == pageSize;
      _currentTopicsPage.value++;

      print('📚 LEGAL EDU: Total topics now: ${_topics.length}');
    } catch (e) {
      _error.value = e.toString();
      print('❌ LEGAL EDU ERROR: $e');

      // Check if it's an authentication error
      final isAuthError = e.toString().contains('401') ||
          e.toString().contains('Authentication') ||
          e.toString().contains('credentials were not provided');

      if (isAuthError) {
        _error.value =
            'Authentication required. Please log in to access legal education topics.';
        print('🔒 LEGAL EDU: Authentication required - user not logged in');
      }

      // Show user-friendly error message
      Get.snackbar(
        'Error Loading Topics',
        isAuthError
            ? 'Please log in to access legal education content'
            : 'Failed to load topics. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      _isLoadingTopics.value = false;
    }
  }

  Future<void> _loadMoreTopics() async {
    await fetchTopics(refresh: false);
  }

  // Search functionality
  void searchTopics(String query) {
    _searchQuery.value = query;
    fetchTopics(refresh: true);
  }

  void clearSearch() {
    _searchQuery.value = '';
    fetchTopics(refresh: true);
  }

  // Language filter functionality
  void setLanguageFilter(LanguageFilter filter) {
    _languageFilter.value = filter;
    fetchTopics(refresh: true);
  }

  String? _getLanguageCode() {
    switch (_languageFilter.value) {
      case LanguageFilter.english:
        return 'en';
      case LanguageFilter.swahili:
        return 'sw';
      case LanguageFilter.both:
        return null;
    }
  }

  // Materials functionality
  Future<void> fetchMaterials(String topicSlug,
      {String? language, bool refresh = false}) async {
    _currentMaterialsTopicSlug = topicSlug;
    _currentMaterialsLanguage = language;

    if (refresh) {
      _currentMaterialsPage.value = 1;
      _hasMoreMaterials.value = true;
      _materials.clear();
    }

    try {
      _isLoadingMaterials.value = true;
      _materialsError.value = '';

      final response = await _service.getTopicMaterials(
        topicSlug,
        language: language,
        page: _currentMaterialsPage.value,
        pageSize: pageSize,
      );

      if (refresh) {
        _materials.assignAll(response.results.materials);
      } else {
        _materials.addAll(response.results.materials);
      }

      _hasMoreMaterials.value = response.results.materials.length == pageSize;
      _currentMaterialsPage.value++;
    } catch (e) {
      _materialsError.value = e.toString();
    } finally {
      _isLoadingMaterials.value = false;
    }
  }

  Future<void> _loadMoreMaterials() async {
    if (_currentMaterialsTopicSlug != null) {
      await fetchMaterials(
        _currentMaterialsTopicSlug!,
        language: _currentMaterialsLanguage,
        refresh: false,
      );
    }
  }

  void refreshMaterials() {
    print('🔄 LegalEducationController: refreshMaterials called');
    print('🔄 Current topic slug: $_currentMaterialsTopicSlug');
    print('🔄 Current language: $_currentMaterialsLanguage');

    if (_currentMaterialsTopicSlug != null) {
      print(
          '🔄 LegalEducationController: Fetching materials with refresh=true');
      fetchMaterials(
        _currentMaterialsTopicSlug!,
        language: _currentMaterialsLanguage,
        refresh: true,
      );
    } else {
      print('🔄 LegalEducationController: No current topic slug available');
    }
  }

  // Existing methods for subtopics, etc.
  final RxList<Subtopic> _subtopics = <Subtopic>[].obs;
  final RxBool _isLoadingSubtopics = false.obs;

  List<Subtopic> get subtopics => _subtopics;
  bool get isLoadingSubtopics => _isLoadingSubtopics.value;

  Future<void> fetchSubtopics(String topicSlug, {String? language}) async {
    try {
      _isLoadingSubtopics.value = true;
      _error.value = '';

      final response =
          await _service.getSubtopics(topicSlug: topicSlug, language: language);
      _subtopics.assignAll(response.results);
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoadingSubtopics.value = false;
    }
  }
}
