import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/hub_content_service.dart';
import '../models/hub_content_models.dart';
import '../utils/user_role_manager.dart';
import '../../legal_education/models/legal_education_models.dart';

class HubContentController extends GetxController {
  final String hubType;
  final HubContentService _service = Get.find<HubContentService>();

  HubContentController({required this.hubType});

  // Observable variables
  final RxList<HubContentItem> content = <HubContentItem>[].obs;
  final RxList<HubContentItem> trendingContent = <HubContentItem>[].obs;
  final RxList<HubContentItem> recentContent = <HubContentItem>[].obs;
  final RxList<HubContentItem> filteredContent = <HubContentItem>[].obs;
  final RxList<HubContentItem> searchResults = <HubContentItem>[].obs;
  final RxList<HubContentItem> bookmarkedContent = <HubContentItem>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasMoreData = true.obs;

  final RxInt currentPage = 1.obs;
  final RxInt totalContent = 0.obs;
  final RxInt activeUsers = 0.obs;

  // Enhanced comments functionality
  final RxBool isAddingComment = false.obs;
  final RxBool isLoadingComments = false.obs;
  final RxMap<int, int> commentPages = <int, int>{}.obs;

  // Comments-related observables
  final RxMap<int, RxList<HubComment>> contentComments =
      <int, RxList<HubComment>>{}.obs;
  final RxMap<int, RxBool> commentsLoading = <int, RxBool>{}.obs;
  final RxMap<int, RxBool> commentsExpanded = <int, RxBool>{}.obs;
  final Map<int, TextEditingController> commentControllers =
      <int, TextEditingController>{};
  final RxMap<int, RxBool> addingComment = <int, RxBool>{}.obs;

  final RxString searchQuery = ''.obs;
  final RxString selectedFilter = 'all'.obs;
  final RxString selectedContentType = 'all'.obs;
  final RxString selectedUploaderType = 'all'.obs;
  final RxString sortBy = 'recent'.obs;
  final RxBool showDownloadableOnly = false.obs;
  final RxBool showPinnedOnly = false.obs;
  final RxBool showLectureMaterialOnly = false.obs;
  final RxDouble minPrice = 0.0.obs;
  final RxDouble maxPrice = 1000.0.obs;
  final RxBool showFreeOnly = false.obs;
  final RxnInt selectedTopicId = RxnInt();

  // Scroll controller for pagination
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    debugPrint('🏛️ HubContentController initialized for hubType: "$hubType"');
    _setupScrollListener();
    fetchInitialContent();
  }

  @override
  void onClose() {
    // Clean up comment controllers
    for (var controller in commentControllers.values) {
      controller.dispose();
    }
    scrollController.dispose();
    super.onClose();
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        if (!isLoadingMore.value && hasMoreData.value) {
          loadMoreContent();
        }
      }
    });
  }

  /// Fetch initial content when screen loads
  Future<void> fetchInitialContent() async {
    try {
      debugPrint('🔄 Fetching initial content for hubType: "$hubType"');
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';
      currentPage.value = 1;

      // Fetch main content
      final response = await _service.fetchHubContent(
        hubType: hubType,
        page: currentPage.value,
      );

      debugPrint(
          '📊 Content response for "$hubType": ${response.results.length} items, total: ${response.count}');

      if (response.results.isEmpty) {
        debugPrint('❌ NO CONTENT RETURNED for hub "$hubType"');
        debugPrint('🔍 Response count: ${response.count}');
        debugPrint('🔍 Response next: ${response.next}');
        debugPrint('🔍 Response previous: ${response.previous}');
      } else {
        debugPrint('✅ Content found for hub "$hubType":');
        for (int i = 0; i < response.results.length && i < 5; i++) {
          final item = response.results[i];
          debugPrint(
              '   ${i + 1}. "${item.title}" (ID: ${item.id}) - ${item.contentType}');
        }
        if (response.results.length > 5) {
          debugPrint('   ... and ${response.results.length - 5} more items');
        }
      }

      content.assignAll(response.results);
      totalContent.value = response.count;
      hasMoreData.value = response.next != null;

      // Fetch trending content separately
      await fetchTrendingContent();
      await fetchRecentContent();

      // Update stats
      activeUsers.value = response.activeUsers ?? 0;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('Error fetching initial content: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more content for pagination
  Future<void> loadMoreContent() async {
    if (isLoadingMore.value || !hasMoreData.value) return;

    try {
      isLoadingMore.value = true;
      currentPage.value++;

      final response = await _service.fetchHubContent(
        hubType: hubType,
        page: currentPage.value,
        filters: _getCurrentFilters(),
      );

      content.addAll(response.results);
      hasMoreData.value = response.next != null;
    } catch (e) {
      currentPage.value--;
      Get.snackbar(
        'Error',
        'Failed to load more content: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Fetch trending content
  Future<void> fetchTrendingContent() async {
    try {
      final response = await _service.getTrendingContent(hubType);
      trendingContent.assignAll(response.results);
    } catch (e) {
      print('Error fetching trending content: $e');
    }
  }

  /// Fetch recent content
  Future<void> fetchRecentContent() async {
    try {
      final response = await _service.getRecentContent(hubType);
      recentContent.assignAll(response.results);
    } catch (e) {
      print('Error fetching recent content: $e');
    }
  }

  /// Search content
  Future<void> searchContent(String query) async {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    try {
      isSearching.value = true;
      searchQuery.value = query;

      final response = await _service.searchContentAdvanced(
        query: query,
        hubType: hubType,
        contentType: selectedContentType.value != 'all'
            ? selectedContentType.value
            : null,
      );

      searchResults.assignAll(response.results);
    } catch (e) {
      Get.snackbar(
        'Search Error',
        'Failed to search content: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSearching.value = false;
    }
  }

  /// Clear search and reload content
  void clearSearch() {
    searchQuery.value = '';
    searchResults.clear();
    isSearching.value = false;
  }

  /// Apply comprehensive filters
  Future<void> applyFilters({
    String? filter,
    String? contentType,
    String? uploaderType,
    String? sort,
    bool? downloadableOnly,
    bool? pinnedOnly,
    bool? lectureMaterialOnly,
    double? minPrice,
    double? maxPrice,
    bool? freeOnly,
    int? topicId,
  }) async {
    selectedFilter.value = filter ?? selectedFilter.value;
    selectedContentType.value = contentType ?? selectedContentType.value;
    selectedUploaderType.value = uploaderType ?? selectedUploaderType.value;
    sortBy.value = sort ?? sortBy.value;

    if (downloadableOnly != null) {
      showDownloadableOnly.value = downloadableOnly;
    }
    if (pinnedOnly != null) {
      showPinnedOnly.value = pinnedOnly;
    }
    if (lectureMaterialOnly != null) {
      showLectureMaterialOnly.value = lectureMaterialOnly;
    }
    if (minPrice != null) {
      this.minPrice.value = minPrice;
    }
    if (maxPrice != null) {
      this.maxPrice.value = maxPrice;
    }
    if (freeOnly != null) {
      showFreeOnly.value = freeOnly;
    }
    if (topicId != null) {
      selectedTopicId.value = topicId;
    }

    debugPrint('🎯 Applying filters for hub: $hubType');
    await fetchInitialContent();
  }

  /// Reset all filters to default values
  Future<void> resetFilters() async {
    selectedFilter.value = 'all';
    selectedContentType.value = 'all';
    selectedUploaderType.value = 'all';
    sortBy.value = 'recent';
    showDownloadableOnly.value = false;
    showPinnedOnly.value = false;
    showLectureMaterialOnly.value = false;
    minPrice.value = 0.0;
    maxPrice.value = 1000.0;
    showFreeOnly.value = false;
    selectedTopicId.value = null;
    searchQuery.value = '';

    debugPrint('🔄 Filters reset for hub: $hubType');
    await fetchInitialContent();
  }

  /// Get current filter parameters - Comprehensive implementation
  Map<String, dynamic> _getCurrentFilters() {
    final filters = <String, dynamic>{};

    // Search query
    if (searchQuery.value.isNotEmpty) {
      filters['search'] = searchQuery.value;
    }

    // Content type filter
    if (selectedContentType.value != 'all') {
      filters['content_type'] = selectedContentType.value;
    }

    // Uploader type filter
    if (selectedUploaderType.value != 'all') {
      filters['uploader_type'] = selectedUploaderType.value;
    }

    // Downloadable content filter
    if (showDownloadableOnly.value) {
      filters['is_downloadable'] = true;
    }

    // Pinned content filter
    if (showPinnedOnly.value) {
      filters['is_pinned'] = true;
    }

    // Lecture material filter
    if (showLectureMaterialOnly.value) {
      filters['is_lecture_material'] = true;
    }

    // Price range filters
    if (showFreeOnly.value) {
      filters['max_price'] = 0;
    } else {
      if (minPrice.value > 0) {
        filters['min_price'] = minPrice.value;
      }
      if (maxPrice.value < 1000) {
        filters['max_price'] = maxPrice.value;
      }
    }

    // Topic filter
    if (selectedTopicId.value != null) {
      filters['topic'] = selectedTopicId.value;
    }

    // Admin privileges - can see all content regardless of restrictions
    if (UserRoleManager.canViewAllContent()) {
      filters['admin_view'] = true;
      debugPrint('🔐 Admin viewing all content in hub: $hubType');
    }

    // Sort options
    switch (sortBy.value) {
      case 'recent':
        filters['ordering'] = '-created_at';
        break;
      case 'popular':
        filters['ordering'] = '-views_count';
        break;
      case 'trending':
        filters['ordering'] = '-downloads_count';
        break;
      case 'likes':
        filters['ordering'] = '-likes_count';
        break;
      case 'price_high':
        filters['ordering'] = '-price';
        break;
      case 'price_low':
        filters['ordering'] = 'price';
        break;
      case 'alphabetical':
        filters['ordering'] = 'title';
        break;
      case 'pinned_first':
        filters['ordering'] = '-is_pinned,-created_at';
        break;
    }

    debugPrint('🔍 Applied filters: $filters');
    return filters;
  }

  /// Toggle like on content
  Future<void> toggleLike(HubContentItem contentItem) async {
    try {
      print(
          '❤️ ${contentItem.isLiked ? 'Unliking' : 'Liking'} content: ${contentItem.id}');

      // Track view for this interaction
      trackViewOnInteraction(contentItem, 'like');

      Map<String, dynamic> result;
      bool newLikeState;
      int newLikesCount;

      // The likeContent method handles both like and unlike
      result = await _service.likeContent(contentItem.id);

      // Toggle the like state
      newLikeState = !contentItem.isLiked;
      newLikesCount = newLikeState
          ? contentItem.likesCount + 1
          : (contentItem.likesCount > 0 ? contentItem.likesCount - 1 : 0);

      print('📝 Like API response: $result');

      // Check if API returned updated counts
      if (result.containsKey('is_liked')) {
        newLikeState = result['is_liked'] ?? newLikeState;
      }
      if (result.containsKey('likes_count')) {
        newLikesCount = result['likes_count'] ?? newLikesCount;
      }

      // Update the content item locally
      final updatedItem = contentItem.copyWith(
        isLiked: newLikeState,
        likesCount: newLikesCount,
      );

      // Update in all lists to ensure UI consistency
      _updateContentInLists(updatedItem);

      print(
          '✅ Like updated: ${updatedItem.isLiked ? 'Liked' : 'Unliked'} (${updatedItem.likesCount} likes)');

      // No snackbar feedback - just visual icon change
    } catch (e) {
      print('❌ Error toggling like: $e');
      Get.snackbar(
        'Error',
        'Failed to update like: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Toggle bookmark on content
  Future<void> toggleBookmark(HubContentItem contentItem) async {
    try {
      print('🔖 Toggling bookmark for content: ${contentItem.id}');
      print(
          '🔖 Current bookmark status: ${contentItem.isBookmarked}, count: ${contentItem.bookmarksCount}');

      // Track view for this interaction
      trackViewOnInteraction(contentItem, 'bookmark');

      Map<String, dynamic> result;
      if (contentItem.isBookmarked) {
        result = await _service.removeBookmark(contentItem.id);
      } else {
        result = await _service.bookmarkContent(contentItem.id);
      }

      print('🔖 API Response: $result');

      // Extract values from API response
      final newIsBookmarked =
          result['is_bookmarked'] ?? !contentItem.isBookmarked;
      final apiBookmarksCount = result['bookmarks_count'];

      // Handle bookmark count logic properly
      int newBookmarksCount;
      if (apiBookmarksCount != null) {
        // API provided count, use it
        newBookmarksCount = apiBookmarksCount;
        print('🔖 Using API count: $newBookmarksCount');
      } else {
        // API didn't provide count, calculate based on action
        if (contentItem.isBookmarked && !newIsBookmarked) {
          // Was bookmarked, now unbookmarked - decrease count
          newBookmarksCount = (contentItem.bookmarksCount - 1)
              .clamp(0, double.infinity)
              .toInt();
          print('🔖 Calculated count (unbookmarked): $newBookmarksCount');
        } else if (!contentItem.isBookmarked && newIsBookmarked) {
          // Was not bookmarked, now bookmarked - increase count
          newBookmarksCount = contentItem.bookmarksCount + 1;
          print('🔖 Calculated count (bookmarked): $newBookmarksCount');
        } else {
          // No change in status, keep same count
          newBookmarksCount = contentItem.bookmarksCount;
          print('🔖 No status change, keeping count: $newBookmarksCount');
        }
      }

      // Update the content item in all lists
      final updatedItem = contentItem.copyWith(
        isBookmarked: newIsBookmarked,
        bookmarksCount: newBookmarksCount,
      );

      print(
          '🔖 Updated item - bookmarked: ${updatedItem.isBookmarked}, count: ${updatedItem.bookmarksCount}');

      _updateContentInLists(updatedItem);

      // If API didn't return bookmarks count and our calculated count seems wrong,
      // let's try to refresh the content to get accurate counts
      if (apiBookmarksCount == null &&
          newBookmarksCount <= 0 &&
          newIsBookmarked) {
        print(
            '🔖 Warning: Bookmarked item has count of $newBookmarksCount, this might be incorrect');
        print('🔖 Consider refreshing content to get accurate counts');
        // Optionally refresh content here: await refreshContent();
      }
    } catch (e) {
      print('❌ Error toggling bookmark: $e');
      Get.snackbar(
        'Error',
        'Failed to update bookmark: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Rate content
  Future<void> rateContent(
      HubContentItem contentItem, double rating, String? review) async {
    try {
      print('⭐ Rating content: ${contentItem.id} with $rating stars');

      final ratingRequest = CreateRatingRequest(
        rating: rating,
        review: review,
      );

      final result = await _service.rateContent(
        contentId: contentItem.id,
        ratingRequest: ratingRequest,
      );

      // Update the content item with new rating information
      final updatedItem = contentItem.copyWith(
        rating: result.contentAverageRating,
        totalRatings: result.totalRatings,
      );

      _updateContentInLists(updatedItem);

      Get.snackbar(
        'Success',
        'Content rated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('❌ Error rating content: $e');
      Get.snackbar(
        'Error',
        'Failed to rate content: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Track viewed content to prevent duplicate views
  final Set<int> _viewedContentIds = <int>{};

  /// Track content view with debouncing to prevent spam
  Future<void> trackView(HubContentItem contentItem,
      {String source = 'unknown'}) async {
    // Prevent tracking the same content multiple times in a session
    if (_viewedContentIds.contains(contentItem.id)) {
      print('👁️ Content ${contentItem.id} already viewed in this session');
      return;
    }

    try {
      print(
          '👁️ Tracking view for content: ${contentItem.id} (source: $source)');

      // Mark as viewed immediately to prevent duplicate calls
      _viewedContentIds.add(contentItem.id);

      // Update view count locally first (optimistic update)
      final updatedItem = contentItem.copyWith(
        viewsCount: contentItem.viewsCount + 1,
      );
      _updateContentInLists(updatedItem);

      // Then send to server
      await _service.trackContentView(contentItem.id);

      print('✅ View tracked successfully for content: ${contentItem.id}');
    } catch (e) {
      print('❌ Error tracking view: $e');
      // Remove from viewed set if server call failed so it can be retried
      _viewedContentIds.remove(contentItem.id);

      // Revert optimistic update on server error
      _updateContentInLists(contentItem);
    }
  }

  /// Track view when content becomes visible (for automatic tracking)
  Future<void> trackViewOnVisible(HubContentItem contentItem) async {
    return trackView(contentItem, source: 'auto_visible');
  }

  /// Track view on user interaction (tap, etc.)
  Future<void> trackViewOnInteraction(
      HubContentItem contentItem, String interaction) async {
    return trackView(contentItem, source: 'interaction_$interaction');
  }

  /// Advanced search with filters
  Future<void> searchWithFilters({
    required String query,
    String? contentType,
    String? ordering,
    bool? isDownloadable,
    bool? isFree,
    int? topicId,
    int page = 1,
  }) async {
    try {
      isSearching.value = true;

      final response = await _service.searchContentAdvanced(
        query: query,
        hubType: hubType,
        contentType: contentType,
        ordering: ordering,
        isDownloadable: isDownloadable,
        isFree: isFree,
        topicId: topicId,
        page: page,
      );

      if (page == 1) {
        searchResults.assignAll(response.results);
      } else {
        searchResults.addAll(response.results);
      }
    } catch (e) {
      print('❌ Error searching with filters: $e');
      Get.snackbar(
        'Search Error',
        'Failed to search content: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSearching.value = false;
    }
  }

  /// Get user's bookmarked content
  Future<void> fetchBookmarkedContent({int page = 1}) async {
    try {
      print(
          '🔖 Controller: Starting fetchBookmarkedContent for hubType: $hubType');
      isLoading.value = true;

      final response = await _service.getBookmarkedContent(
        hubType: hubType,
        page: page,
      );

      // Store in dedicated bookmarked content list
      print(
          '🔖 Controller: Received ${response.results.length} bookmarked items for $hubType');
      print(
          '🔖 Controller: Current bookmarked list size before update: ${bookmarkedContent.length}');

      if (page == 1) {
        // For first page, intelligently merge instead of replacing
        final serverIds = response.results.map((item) => item.id).toSet();

        // Start with server results as the base
        final mergedList = <HubContentItem>[...response.results];

        // Add any local items that aren't in the server response
        // (these might be recently bookmarked items that haven't synced yet)
        for (final localItem in bookmarkedContent) {
          if (!serverIds.contains(localItem.id) && localItem.isBookmarked) {
            mergedList.insert(0, localItem); // Add recent items at the top
            print(
                '🔖 Controller: Keeping locally bookmarked item ${localItem.id} that\'s not in server response');
          }
        }

        bookmarkedContent.assignAll(mergedList);
        print(
            '🔖 Controller: Merged local and server bookmarks - final count: ${mergedList.length}');
      } else {
        bookmarkedContent.addAll(response.results);
        print(
            '🔖 Controller: Added ${response.results.length} items to existing bookmarked list');
      }

      print(
          '🔖 Controller: Final bookmarked list size: ${bookmarkedContent.length}');
      if (bookmarkedContent.isNotEmpty) {
        print(
            '🔖 Controller: First few bookmarked items: ${bookmarkedContent.take(3).map((item) => 'ID:${item.id} Title:"${item.title}"').join(", ")}');
      }
    } catch (e) {
      print('❌ Error fetching bookmarked content for $hubType: $e');
      // Don't show user-facing error for bookmarks endpoint 404 -
      // the endpoint may not be implemented yet on backend
      if (!e.toString().contains('404') &&
          !e.toString().contains('Not found')) {
        Get.snackbar(
          'Error',
          'Failed to fetch bookmarked content: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      // Clear bookmarked content on error to show empty state
      bookmarkedContent.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Get user's liked content
  Future<void> fetchLikedContent({int page = 1}) async {
    try {
      isLoading.value = true;

      final response = await _service.getLikedContent(
        hubType: hubType,
        page: page,
      );

      // You might want to store this in a separate list for liked content view
      searchResults.assignAll(response.results);
    } catch (e) {
      print('❌ Error fetching liked content: $e');
      Get.snackbar(
        'Error',
        'Failed to fetch liked content: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Helper method to update content in all lists
  void _updateContentInLists(HubContentItem updatedItem) {
    int updatesCount = 0;

    // Update in main content list
    final mainIndex = content.indexWhere((item) => item.id == updatedItem.id);
    if (mainIndex != -1) {
      content[mainIndex] = updatedItem;
      updatesCount++;
    }

    // Update in trending content list
    final trendingIndex =
        trendingContent.indexWhere((item) => item.id == updatedItem.id);
    if (trendingIndex != -1) {
      trendingContent[trendingIndex] = updatedItem;
      updatesCount++;
    }

    // Update in recent content list
    final recentIndex =
        recentContent.indexWhere((item) => item.id == updatedItem.id);
    if (recentIndex != -1) {
      recentContent[recentIndex] = updatedItem;
      updatesCount++;
    }

    // Update in search results
    final searchIndex =
        searchResults.indexWhere((item) => item.id == updatedItem.id);
    if (searchIndex != -1) {
      searchResults[searchIndex] = updatedItem;
      updatesCount++;
    }

    // Update in filtered content
    final filteredIndex =
        filteredContent.indexWhere((item) => item.id == updatedItem.id);
    if (filteredIndex != -1) {
      filteredContent[filteredIndex] = updatedItem;
      updatesCount++;
    }

    // Update in bookmarked content list
    final bookmarkedIndex =
        bookmarkedContent.indexWhere((item) => item.id == updatedItem.id);
    print(
        '🔖 Bookmark list update - Item ${updatedItem.id}, isBookmarked: ${updatedItem.isBookmarked}, currentIndex: $bookmarkedIndex, listSize: ${bookmarkedContent.length}');

    if (updatedItem.isBookmarked) {
      // If item is bookmarked but not present in list, add it
      if (bookmarkedIndex == -1) {
        bookmarkedContent.insert(0, updatedItem);
        updatesCount++;
        print(
            '🔖 Added item ${updatedItem.id} to bookmarks list (new size: ${bookmarkedContent.length})');
      } else {
        bookmarkedContent[bookmarkedIndex] = updatedItem;
        updatesCount++;
        print(
            '🔖 Updated item ${updatedItem.id} in bookmarks list at index $bookmarkedIndex');
      }
    } else {
      // If item is unbookmarked and present in the list, remove it
      if (bookmarkedIndex != -1) {
        bookmarkedContent.removeAt(bookmarkedIndex);
        updatesCount++;
        print(
            '🔖 Removed item ${updatedItem.id} from bookmarks list (new size: ${bookmarkedContent.length})');
      }
    }

    print('🔄 Updated content ${updatedItem.id} in $updatesCount lists');

    // Force UI update by triggering reactive variable changes
    content.refresh();
    trendingContent.refresh();
    recentContent.refresh();
    searchResults.refresh();
    filteredContent.refresh();
    bookmarkedContent.refresh();
  }

  /// Convert hub content to LearningMaterial for viewer compatibility
  LearningMaterial convertToLearningMaterial(HubContentItem item) {
    return LearningMaterial(
      id: item.id,
      hubType: hubType,
      contentType: item.contentType,
      uploaderInfo: item.uploader,
      title: item.title,
      description: item.description,
      fileUrl: item.fileUrl,
      language: 'en', // Default language
      price: '0.00', // Hub content is typically free
      isDownloadable: item.isDownloadable,
      isLectureMaterial: false,
      isVerified: item.isVerified,
      downloadsCount: item.downloadsCount,
      likesCount: item.likesCount,
      isLiked: item.isLiked,
      createdAt: item.createdAt,
      lastUpdated: item.updatedAt,
    );
  }

  /// Refresh content
  Future<void> refreshContent() async {
    print('🔄 HubContentController: refreshContent called for hub: $hubType');
    print('🔄 Current content count before refresh: ${content.length}');

    // Clear current state to force fresh data
    content.clear();
    trendingContent.clear();
    recentContent.clear();
    currentPage.value = 1;
    hasMoreData.value = true;

    await fetchInitialContent();

    print('🔄 HubContentController: refreshContent completed');
    print('🔄 Content count after refresh: ${content.length}');
    print('🔄 Content titles: ${content.map((e) => e.title).join(", ")}');
  }

  /// Get content by ID
  Future<HubContentItem?> getContentById(int id) async {
    try {
      return await _service.getContentById(id, hubType);
    } catch (e) {
      print('Error fetching content by ID: $e');
      return null;
    }
  }

  /// Get available content types for filtering - Based on API documentation
  List<String> getAvailableContentTypes() {
    return [
      'all',
      'pdf',
      'video',
      'image',
      'audio',
      'document',
    ];
  }

  /// Get available uploader types for filtering
  List<String> getAvailableUploaderTypes() {
    return [
      'all',
      'lecturer',
      'student',
      'advocate',
      'admin',
    ];
  }

  /// Get comprehensive sort options based on API documentation
  List<Map<String, String>> getSortOptions() {
    return [
      {'value': 'recent', 'label': 'Most Recent'},
      {'value': 'popular', 'label': 'Most Viewed'},
      {'value': 'trending', 'label': 'Most Downloaded'},
      {'value': 'likes', 'label': 'Most Liked'},
      {'value': 'price_high', 'label': 'Price: High to Low'},
      {'value': 'price_low', 'label': 'Price: Low to High'},
      {'value': 'alphabetical', 'label': 'Alphabetical'},
      {'value': 'pinned_first', 'label': 'Pinned First'},
    ];
  }

  // Comment Management Methods

  /// Initialize comment controller for a content item
  void initializeCommentController(int contentId) {
    if (!commentControllers.containsKey(contentId)) {
      commentControllers[contentId] = TextEditingController();
      commentsLoading[contentId] = false.obs;
      commentsExpanded[contentId] = false.obs;
      addingComment[contentId] = false.obs;
      contentComments[contentId] = <HubComment>[].obs;
    }
  }

  /// Toggle comments visibility for a content item
  void toggleComments(int contentId) {
    initializeCommentController(contentId);

    final isExpanded = commentsExpanded[contentId]!.value;
    commentsExpanded[contentId]!.value = !isExpanded;

    // Load comments if expanding for the first time
    if (!isExpanded && contentComments[contentId]!.isEmpty) {
      loadComments(contentId);
    }
  }

  /// Load ALL comments for a content item with smart pagination
  Future<void> loadComments(int contentId) async {
    try {
      initializeCommentController(contentId);
      commentsLoading[contentId]!.value = true;

      print('Loading ALL comments for content ID: $contentId');

      // Get expected comment count from the content item
      final currentContentItem =
          content.firstWhere((item) => item.id == contentId);
      final expectedCount = currentContentItem.commentsCount;

      List<HubComment> allComments = [];

      if (expectedCount <= 100) {
        // For posts with <= 100 comments, load all in one request
        print('Loading all $expectedCount comments in single request...');
        final comments = await _service.getComments(contentId);
        allComments.addAll(comments);
        print('Loaded ${allComments.length} comments in single request');
      } else {
        // For posts with many comments, use pagination
        print('Post has $expectedCount comments, using pagination...');
        int currentPage = 1;
        bool hasMorePages = true;

        while (hasMorePages && allComments.length < expectedCount) {
          print('Loading comments page $currentPage...');
          final comments = await _service.getComments(contentId);

          allComments.addAll(comments);
          print(
              'Page $currentPage: ${comments.length} comments loaded (total: ${allComments.length})');

          // Since getComments returns all comments, we can break after first call
          hasMorePages = false;
          currentPage++;

          // Safety check
          if (currentPage > 20) {
            print(
                'WARNING: Stopped loading at page 20 (${allComments.length} comments loaded)');
            break;
          }
        }
      }

      print(
          'Successfully loaded ${allComments.length} comments (expected: $expectedCount)');

      // Debug: Check if there's a mismatch between API count and actual comments
      final apiCount = currentContentItem.commentsCount;
      final actualCount = _calculateTotalCommentCount(allComments);

      if (apiCount != actualCount) {
        print(
            'COMMENT COUNT MISMATCH: API says $apiCount, but loaded $actualCount comments');
      }

      // Debug: print comment summary
      print('Comment summary for content $contentId:');
      for (int i = 0; i < allComments.length && i < 5; i++) {
        final comment = allComments[i];
        print(
            'Comment ${i + 1}: ${comment.comment.length > 50 ? comment.comment.substring(0, 50) + "..." : comment.comment} by ${comment.author.fullName}');
      }
      if (allComments.length > 5) {
        print('... and ${allComments.length - 5} more comments');
      }

      contentComments[contentId]!.assignAll(allComments);

      // Update the comment count in the content item to reflect actual loaded comments
      _updateContentCommentCountToActual(contentId, actualCount);
    } catch (e) {
      print('Error loading comments: $e');
      Get.snackbar(
        'Error',
        'Failed to load comments: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      commentsLoading[contentId]!.value = false;
    }
  }

  /// Add a new comment to a content item
  Future<void> addComment(int contentId,
      {int? parentCommentId, String? customText}) async {
    try {
      initializeCommentController(contentId);
      final controller = commentControllers[contentId]!;

      // Use custom text if provided (for replies), otherwise use controller text
      final commentText = customText?.trim() ?? controller.text.trim();

      print(
          'Adding comment - Content ID: $contentId, Parent ID: $parentCommentId');
      print('Comment text: "$commentText"');
      print('Is reply: ${parentCommentId != null}');

      if (commentText.isEmpty) {
        Get.snackbar('Error', 'Comment cannot be empty');
        return;
      }

      // Get the hub type from the content item
      final contentItem = content.firstWhere((item) => item.id == contentId);
      final hubType = contentItem.hubType;

      // Track view for this interaction
      trackViewOnInteraction(contentItem, 'comment');

      addingComment[contentId]!.value = true;

      final commentRequest = CreateCommentRequest(
        contentId: contentId,
        comment: commentText,
        hubType: hubType,
        parentCommentId: parentCommentId,
      );

      final newComment = await _service.addComment(
        contentId: contentId,
        commentRequest: commentRequest,
      );

      // Add comment to the list
      if (parentCommentId == null) {
        // Top-level comment
        contentComments[contentId]!.insert(0, newComment);
      } else {
        // Reply to a comment - find parent and add to replies
        _addReplyToComment(contentId, parentCommentId, newComment);
      }

      // Update comment count in content item
      _updateContentCommentCount(contentId, 1);

      // Clear the input only if we used the controller text (not custom reply text)
      if (customText == null) {
        controller.clear();
      }

      Get.snackbar(
        'Success',
        'Comment added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add comment: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      addingComment[contentId]!.value = false;
    }
  }

  /// Add a reply to a specific comment
  void _addReplyToComment(
      int contentId, int parentCommentId, HubComment reply) {
    final comments = contentComments[contentId]!;
    bool found = false;

    // Create a new list with updated comments to trigger reactive update
    final updatedComments = <HubComment>[];

    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == parentCommentId) {
        // Set correct depth for the reply (parent depth + 1)
        final replyWithDepth = reply.copyWith(depth: comments[i].depth + 1);
        final updatedComment = comments[i].copyWith(
          replies: [...comments[i].replies, replyWithDepth],
          repliesCount: comments[i].replies.length + 1, // Update replies count
        );
        updatedComments.add(updatedComment);
        found = true;
      } else {
        // Check in replies recursively and update if needed
        final updatedComment = _addReplyToCommentRecursively(
            comments[i], parentCommentId, reply, comments[i].depth + 1);
        updatedComments.add(updatedComment);
      }
    }

    // Replace the entire list to trigger reactive update
    if (found || updatedComments.isNotEmpty) {
      contentComments[contentId]!.assignAll(updatedComments);
    }
  }

  HubComment _addReplyToCommentRecursively(HubComment comment,
      int parentCommentId, HubComment reply, int parentDepth) {
    final updatedReplies = <HubComment>[];
    bool found = false;

    for (int i = 0; i < comment.replies.length; i++) {
      if (comment.replies[i].id == parentCommentId) {
        // Set correct depth for the reply (parent depth + 1)
        final replyWithDepth = reply.copyWith(depth: parentDepth + 1);
        // Update the parent comment to include the new reply
        final updatedParent = comment.replies[i].copyWith(
          replies: [...comment.replies[i].replies, replyWithDepth],
          repliesCount:
              comment.replies[i].replies.length + 1, // Update replies count
        );
        updatedReplies.add(updatedParent);
        found = true;
      } else {
        // Recursively check deeper levels
        final updatedReply = _addReplyToCommentRecursively(comment.replies[i],
            parentCommentId, reply, comment.replies[i].depth);
        updatedReplies.add(updatedReply);
      }
    }

    // Return updated comment if any changes were made
    if (found) {
      return comment.copyWith(replies: updatedReplies);
    } else {
      return comment; // No changes needed
    }
  }

  /// Update comment count in the content item
  void _updateContentCommentCount(int contentId, int increment) {
    final contentIndex = content.indexWhere((item) => item.id == contentId);
    if (contentIndex != -1) {
      final updatedContent = content[contentIndex].copyWith(
        commentsCount: content[contentIndex].commentsCount + increment,
      );
      content[contentIndex] = updatedContent;
    }
  }

  /// Update comment count to actual number (used when loading comments)
  void _updateContentCommentCountToActual(int contentId, int actualCount) {
    final contentIndex = content.indexWhere((item) => item.id == contentId);
    if (contentIndex != -1) {
      final updatedContent = content[contentIndex].copyWith(
        commentsCount: actualCount,
      );
      content[contentIndex] = updatedContent;
    }
  }

  /// Calculate total comment count including replies
  int _calculateTotalCommentCount(List<HubComment> comments) {
    int total = comments.length; // Count main comments

    // Add replies count recursively
    for (final comment in comments) {
      total += _countRepliesRecursively(comment);
    }

    return total;
  }

  /// Recursively count replies in a comment
  int _countRepliesRecursively(HubComment comment) {
    int count = comment.replies.length;

    // Recursively count replies of replies
    for (final reply in comment.replies) {
      count += _countRepliesRecursively(reply);
    }

    return count;
  }

  /// Toggle like on a comment
  Future<void> toggleCommentLike(int commentId, int contentId) async {
    try {
      // Find the comment to get current like status
      final comments = contentComments[contentId];
      HubComment? targetComment;

      if (comments != null) {
        targetComment = _findCommentById(comments, commentId);
      }

      if (targetComment != null) {
        await _service.toggleCommentLike(commentId);
        // Update the comment's like status in the local list
        _updateCommentLikeStatus(contentId, commentId);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to toggle comment like: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _updateCommentLikeStatus(int contentId, int commentId) {
    final comments = contentComments[contentId];
    if (comments != null) {
      bool found = false;
      final updatedComments = <HubComment>[];

      for (int i = 0; i < comments.length; i++) {
        if (comments[i].id == commentId) {
          final comment = comments[i];
          final updatedComment = comment.copyWith(
            userHasLiked: !comment.userHasLiked,
            likesCount: comment.userHasLiked
                ? comment.likesCount - 1
                : comment.likesCount + 1,
          );
          updatedComments.add(updatedComment);
          found = true;
        } else {
          // Check in replies recursively
          final updatedComment =
              _updateCommentLikeStatusRecursively(comments[i], commentId);
          updatedComments.add(updatedComment);
        }
      }

      // Replace the entire list to trigger reactive update
      if (found || updatedComments.isNotEmpty) {
        contentComments[contentId]!.assignAll(updatedComments);
      }
    }
  }

  HubComment _updateCommentLikeStatusRecursively(
      HubComment comment, int commentId) {
    final updatedReplies = <HubComment>[];
    bool found = false;

    for (int i = 0; i < comment.replies.length; i++) {
      if (comment.replies[i].id == commentId) {
        final reply = comment.replies[i];
        final updatedReply = reply.copyWith(
          userHasLiked: !reply.userHasLiked,
          likesCount:
              reply.userHasLiked ? reply.likesCount - 1 : reply.likesCount + 1,
        );
        updatedReplies.add(updatedReply);
        found = true;
      } else {
        // Recursively check deeper levels
        final updatedReply =
            _updateCommentLikeStatusRecursively(comment.replies[i], commentId);
        updatedReplies.add(updatedReply);
      }
    }

    // Return updated comment if any changes were made
    if (found) {
      return comment.copyWith(replies: updatedReplies);
    } else {
      return comment; // No changes needed
    }
  }

  /// Find a comment by ID in the comment list and replies
  HubComment? _findCommentById(List<HubComment> comments, int commentId) {
    for (final comment in comments) {
      if (comment.id == commentId) {
        return comment;
      }
      // Search in replies recursively
      final found = _findCommentByIdRecursively(comment, commentId);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  /// Recursively find a comment by ID in replies
  HubComment? _findCommentByIdRecursively(HubComment comment, int commentId) {
    for (final reply in comment.replies) {
      if (reply.id == commentId) {
        return reply;
      }
      final found = _findCommentByIdRecursively(reply, commentId);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  /// Delete a comment
  Future<void> deleteComment(int commentId, int contentId) async {
    try {
      await _service.deleteComment(commentId);
      _removeCommentFromList(contentId, commentId);
      Get.snackbar(
        'Success',
        'Comment deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete comment: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Load more replies for a comment
  Future<void> loadCommentReplies(int commentId, int contentId,
      {int page = 1}) async {
    try {
      final replies = await _service.getCommentReplies(commentId);

      _updateCommentReplies(contentId, commentId, replies, page);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load replies: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Remove a comment from the local list
  void _removeCommentFromList(int contentId, int commentId) {
    final comments = contentComments[contentId];
    if (comments != null) {
      comments.removeWhere((comment) => comment.id == commentId);
      // Also remove from replies
      for (final comment in comments) {
        _removeCommentFromRepliesRecursively(comment, commentId);
      }
    }
  }

  /// Recursively remove a comment from replies
  void _removeCommentFromRepliesRecursively(HubComment comment, int commentId) {
    comment.replies.removeWhere((reply) => reply.id == commentId);
    for (final reply in comment.replies) {
      _removeCommentFromRepliesRecursively(reply, commentId);
    }
  }

  /// Update a comment in the local list
  void _updateCommentInList(int contentId, HubComment updatedComment) {
    final comments = contentComments[contentId];
    if (comments != null) {
      for (int i = 0; i < comments.length; i++) {
        if (comments[i].id == updatedComment.id) {
          comments[i] = updatedComment;
          return;
        }
        // Also update in replies
        _updateCommentInRepliesRecursively(comments[i], updatedComment);
      }
    }
  }

  /// Recursively update a comment in replies
  void _updateCommentInRepliesRecursively(
      HubComment comment, HubComment updatedComment) {
    for (int i = 0; i < comment.replies.length; i++) {
      if (comment.replies[i].id == updatedComment.id) {
        comment.replies[i] = updatedComment;
        return;
      }
      _updateCommentInRepliesRecursively(comment.replies[i], updatedComment);
    }
  }

  /// Update comment replies with new data
  void _updateCommentReplies(
      int contentId, int commentId, List<HubComment> newReplies, int page) {
    final comments = contentComments[contentId];
    if (comments != null) {
      for (final comment in comments) {
        if (comment.id == commentId) {
          if (page == 1) {
            comment.replies.clear();
          }
          comment.replies.addAll(newReplies);
          return;
        }
        // Also search in replies
        _updateCommentRepliesRecursively(comment, commentId, newReplies, page);
      }
    }
  }

  /// Recursively update comment replies
  void _updateCommentRepliesRecursively(HubComment comment, int commentId,
      List<HubComment> newReplies, int page) {
    for (final reply in comment.replies) {
      if (reply.id == commentId) {
        if (page == 1) {
          reply.replies.clear();
        }
        reply.replies.addAll(newReplies);
        return;
      }
      _updateCommentRepliesRecursively(reply, commentId, newReplies, page);
    }
  }

  /// Load more comments for pagination
  Future<void> loadMoreComments(int contentId) async {
    if (isLoadingComments.value) return;

    final currentCommentsPage = commentPages[contentId] ?? 1;
    final nextPage = currentCommentsPage + 1;

    try {
      isLoadingComments.value = true;
      final comments = await _service.getComments(contentId);

      if (comments.isNotEmpty) {
        if (contentComments[contentId] == null) {
          contentComments[contentId] = <HubComment>[].obs;
        }
        contentComments[contentId]!.addAll(comments);
        commentPages[contentId] = nextPage;
      }
    } catch (e) {
      print('Error loading more comments: $e');
    } finally {
      isLoadingComments.value = false;
    }
  }
}
