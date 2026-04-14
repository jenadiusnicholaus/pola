import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/legal_education_models.dart';
import '../services/legal_education_service.dart';
import '../../../../services/token_storage_service.dart';
import '../../../../utils/navigation_helper.dart';

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
  final RxBool _hasMoreSubtopicMaterials = true.obs;
  static const int pageSize = 20;

  // Current active data for navigation
  final Rxn<Topic> _currentTopic = Rxn<Topic>(null);
  Topic? get currentTopic => _currentTopic.value;
  void setCurrentTopic(Topic topic) => _currentTopic.value = topic;
  String? _currentMaterialsTopicSlug;
  String? _currentSubtopicMaterialsSlug;
  String? _currentMaterialsLanguage;
  String? _currentSubtopicMaterialsLanguage;

  // Getters
  List<Topic> get topics => _topics;
  List<LearningMaterial> get materials => _materials;
  bool get isLoadingTopics => _isLoadingTopics.value;
  bool get isLoadingMaterials => _isLoadingMaterials.value;
  bool get isLoadingSubtopicMaterials =>
      _isLoadingSubtopicMaterials.value; // New
  String get error => _error.value;
  String get materialsError => _materialsError.value;
  String get subtopicMaterialsError => _subtopicMaterialsError.value; // New
  LanguageFilter get languageFilter => _languageFilter.value;
  String get searchQuery => _searchQuery.value;
  bool get hasMoreTopics => _hasMoreTopics.value;
  bool get hasMoreMaterials => _hasMoreMaterials.value;
  bool get hasMoreSubtopicMaterials => _hasMoreSubtopicMaterials.value;

  @override
  void onInit() {
    super.onInit();
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
    super.onClose();
  }

  // Method to check if we should load more topics (called from screen)
  void onTopicsScroll(ScrollController scrollController) {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingTopics.value && _hasMoreTopics.value) {
        _loadMoreTopics();
      }
    }
  }

  // Method to check if we should load more materials (called from screen)
  void onMaterialsScroll(ScrollController scrollController) {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMaterials.value && _hasMoreMaterials.value) {
        _loadMoreMaterials();
      }
    }
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
      NavigationHelper.showSafeSnackbar(
        title: 'Error Loading Topics',
        message: isAuthError
            ? 'Please log in to access legal education content'
            : 'Failed to load topics. Please try again.',
        backgroundColor: Colors.red,
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

  // Subtopic materials functionality
  final RxList<LearningMaterial> _subtopicMaterials = <LearningMaterial>[].obs;
  final RxBool _isLoadingSubtopicMaterials = false.obs;
  final RxString _subtopicMaterialsError = ''.obs;
  final RxInt _currentSubtopicMaterialsPage = 1.obs;

  List<LearningMaterial> get subtopicMaterials => _subtopicMaterials;

  Future<void> fetchSubtopicMaterials(String subtopicSlug,
      {String? language, bool refresh = false}) async {
    _currentSubtopicMaterialsSlug = subtopicSlug;
    _currentSubtopicMaterialsLanguage = language;

    try {
      _isLoadingSubtopicMaterials.value = true;
      _subtopicMaterialsError.value = '';

      if (refresh) {
        _currentSubtopicMaterialsPage.value = 1;
        _hasMoreSubtopicMaterials.value = true;
        _subtopicMaterials.clear();
      }

      // Check for token initialization
      final tokenService = Get.find<TokenStorageService>();
      await tokenService.waitForInitialization();

      final response = await _service.getSubtopicMaterials(
        subtopicSlug,
        language: language,
        page: _currentSubtopicMaterialsPage.value,
        pageSize: 10,
      );

      if (refresh) {
        _subtopicMaterials.assignAll(response.materials);
      } else {
        _subtopicMaterials.addAll(response.materials);
      }

      _hasMoreSubtopicMaterials.value = response.materials.length == pageSize;
      _currentSubtopicMaterialsPage.value++;
    } catch (e) {
      _subtopicMaterialsError.value = e.toString();
    } finally {
      _isLoadingSubtopicMaterials.value = false;
    }
  }

  void refreshSubtopicMaterials() {
    if (_currentSubtopicMaterialsSlug != null) {
      fetchSubtopicMaterials(
        _currentSubtopicMaterialsSlug!,
        language: _currentSubtopicMaterialsLanguage,
        refresh: true,
      );
    }
  }

  // Existing methods for subtopics, etc.
  final RxList<Subtopic> _subtopics = <Subtopic>[].obs;
  final RxBool _isLoadingSubtopics = false.obs;
  String? _currentTopicSlug; // Added _currentTopicSlug

  List<Subtopic> get subtopics => _subtopics;
  bool get isLoadingSubtopics => _isLoadingSubtopics.value;

  Future<void> fetchSubtopics(String topicSlug, {String? language}) async {
    try {
      _isLoadingSubtopics.value = true;
      _error.value = '';
      _currentTopicSlug = topicSlug; // Set _currentTopicSlug
      _currentMaterialsTopicSlug = topicSlug; // Store it for materials access

      // Check for token initialization
      final tokenService = Get.find<TokenStorageService>();
      await tokenService.waitForInitialization();

      final response =
          await _service.getSubtopics(topicSlug: topicSlug, language: language);
      print(
          '🔍 DEBUG SUBTOPICS RES: count=${response.count}, results_length=${response.results.length}');
      if (response.results.isEmpty) {
        print(
            '⚠️ DEBUG SUBTOPICS EMPTY: Ensure API response format matches expected JSON parsing.');
      }
      _subtopics.assignAll(response.results);
    } catch (e, stackTrace) {
      print('❌ ERROR fetching subtopics: $e');
      print('❌ STACK TRACE: $stackTrace');
      _error.value = e.toString();
    } finally {
      _isLoadingSubtopics.value = false;
    }
  }
}
