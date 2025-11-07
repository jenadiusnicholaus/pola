import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../services/hub_content_service.dart';
import '../utils/user_role_manager.dart';
import '../../legal_education/models/legal_education_models.dart';
import '../../legal_education/services/legal_education_service.dart';
import '../../../../services/token_storage_service.dart';
import 'dart:convert';

class ContentCreationController extends GetxController {
  final String hubType;
  final HubContentService _service = Get.find<HubContentService>();
  final LegalEducationService _legalEduService =
      Get.find<LegalEducationService>();

  ContentCreationController({required this.hubType});

  /// Get display name for hub type
  String _getHubDisplayName(String hubType) {
    switch (hubType) {
      case 'advocates':
        return 'Advocates';
      case 'students':
        return 'Students';
      case 'forum':
        return 'Forum';
      case 'legal_ed':
        return 'Legal Education';
      default:
        return 'Content';
    }
  }

  // Observable variables
  final RxString selectedContentType = ''.obs;
  final RxString selectedLanguage = 'en'.obs;
  final RxBool isDownloadable = false.obs;
  final RxBool isLectureMaterial = false.obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<PlatformFile?> selectedFile = Rx<PlatformFile?>(null);

  // Topic-related variables (for Legal Education hub)
  final RxList<Topic> availableTopics = <Topic>[].obs;
  final Rx<Topic?> selectedTopic = Rx<Topic?>(null);
  final RxBool isLoadingTopics = false.obs;
  final RxString newTopicName = ''.obs;
  final RxString newTopicDescription = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Set default content type based on hub
    final types = getAvailableContentTypes();
    if (types.isNotEmpty) {
      selectedContentType.value = types.first;
    }
  }

  /// Get available content types based on hub type
  List<String> getAvailableContentTypes() {
    switch (hubType) {
      case 'advocates':
        return ['discussion', 'article', 'news', 'case_study', 'legal_update'];
      case 'students':
        return [
          'notes',
          'past_papers',
          'assignment',
          'discussion',
          'question',
          'tutorial'
        ];
      case 'forum':
        return ['discussion', 'question', 'news', 'general'];
      case 'legal_ed':
        return ['lecture', 'article', 'tutorial', 'case_study'];
      default:
        return ['discussion'];
    }
  }

  /// Set content type
  void setContentType(String type) {
    selectedContentType.value = type;
  }

  /// Set language
  void setLanguage(String language) {
    selectedLanguage.value = language;
  }

  /// Set preset topic from map data (used when navigating from topic materials screen)
  void setPresetTopic(Map<String, dynamic> topicData) {
    try {
      // Find the topic in available topics by matching ID
      final topicId = topicData['id']?.toString();
      if (topicId != null) {
        Topic? matchingTopic;
        try {
          matchingTopic = availableTopics.firstWhere(
            (topic) => topic.id.toString() == topicId,
          );
        } catch (e) {
          matchingTopic = null;
        }

        if (matchingTopic != null) {
          selectedTopic.value = matchingTopic;
        } else {
          // If not found in loaded topics, create a Topic object from the data
          try {
            final presetTopic = Topic(
              id: int.parse(topicId),
              name: topicData['name']?.toString() ?? 'Unknown Topic',
              nameSw: topicData['name_sw']?.toString() ?? '',
              slug: topicData['slug']?.toString() ?? 'unknown-topic',
              description: topicData['description']?.toString() ?? '',
              descriptionSw: topicData['description_sw']?.toString() ?? '',
              displayOrder: topicData['display_order'] ?? 0,
              isActive: true,
              subtopicsCount: topicData['subtopics_count'] ?? 0,
              materialsCount: topicData['materials_count'] ?? 0,
              createdAt: DateTime.now(),
              lastUpdated: DateTime.now(),
            );
            selectedTopic.value = presetTopic;
          } catch (e) {
            // Handle error silently
          }
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Set downloadable option
  void setDownloadable(bool value) {
    isDownloadable.value = value;
  }

  /// Set lecture material option
  void setLectureMaterial(bool value) {
    isLectureMaterial.value = value;
  }

  /// Set file
  void setFile(PlatformFile file) {
    // Validate file size (50MB limit)
    if (file.size > 50 * 1024 * 1024) {
      Get.snackbar(
        'File Too Large',
        'Please select a file smaller than 50MB',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Validate file type
    if (!_isValidFileType(file.name)) {
      Get.snackbar(
        'Invalid File Type',
        'Please select a supported file type',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    selectedFile.value = file;
  }

  /// Set image file from ImagePicker
  void setImageFile(String path, List<int> bytes) {
    try {
      final fileName = path.split('/').last;

      // Validate image data is not corrupted
      if (bytes.isEmpty) {
        Get.snackbar(
          'Invalid Image',
          'The selected image appears to be corrupted. Please try a different image.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Ensure we have a proper file extension
      String validatedFileName = fileName;
      if (!validatedFileName.toLowerCase().endsWith('.jpg') &&
          !validatedFileName.toLowerCase().endsWith('.jpeg') &&
          !validatedFileName.toLowerCase().endsWith('.png')) {
        // Add .jpg extension if missing
        validatedFileName = '${validatedFileName.split('.').first}.jpg';
      }

      // Create a PlatformFile from image data
      final file = PlatformFile(
        name: validatedFileName,
        size: bytes.length,
        bytes: Uint8List.fromList(bytes),
        path: path,
      );

      setFile(file);
    } catch (e) {
      Get.snackbar(
        'Image Processing Error',
        'Failed to process the selected image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Remove selected file
  void removeFile() {
    selectedFile.value = null;
  }

  /// Create content
  Future<bool> createContent(HubContentCreateRequest request) async {
    try {
      isLoading.value = true;
      error.value = '';

      print('🔍 CREATE CONTENT: Starting content creation...');
      print('🔍 CREATE CONTENT: Hub Type: ${request.hubType}');
      print('🔍 CREATE CONTENT: Content Type: ${request.contentType}');
      print('🔍 CREATE CONTENT: Title: ${request.title}');
      print('🔍 CREATE CONTENT: Has File: ${request.fileBytes != null}');
      if (request.fileBytes != null) {
        print('🔍 CREATE CONTENT: File Name: ${request.fileName}');
        print(
            '🔍 CREATE CONTENT: File Size: ${request.fileBytes!.length} bytes');
      }

      // Validate permissions using UserRoleManager
      if (!UserRoleManager.canCreateContentInHub(hubType)) {
        throw Exception(
            'You do not have permission to create content in this hub');
      }

      final jsonData = request.toJson();
      print('🔍 CREATE CONTENT: JSON Keys: ${jsonData.keys.toList()}');
      if (jsonData['file'] != null) {
        final fileData = jsonData['file'] as String;
        print(
            '🔍 CREATE CONTENT: File data starts with: ${fileData.substring(0, 50)}...');
        print('🔍 CREATE CONTENT: File data length: ${fileData.length}');
        print(
            '🔍 CREATE CONTENT: Is data URL: ${fileData.startsWith('data:')}');
      }

      // Create a safe version for logging (without file data)
      final logData = Map<String, dynamic>.from(jsonData);
      if (logData.containsKey('file')) {
        logData['file'] = '[BASE64_DATA_${logData['file'].length}_CHARS]';
      }
      print('🔍 CREATE CONTENT: Request data: $logData');

      final createdContent = await _service.createHubContent(jsonData);

      Get.snackbar(
        'Success',
        'Your content "${createdContent.title}" has been published successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return true;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        'Error ❌',
        'Failed to create content: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        icon: const Icon(Icons.error_outline, color: Colors.white, size: 28),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Check if user has permission to create content (deprecated - use UserRoleManager)
  bool _hasCreatePermission() {
    return UserRoleManager.canCreateContentInHub(hubType);
  }

  /// Check if user can set pricing for content
  bool canSetPrice() {
    final canSet = UserRoleManager.canSetPrice(hubType);
    print('🔍 CAN SET PRICE: Hub "$hubType" -> $canSet');
    return canSet;
  }

  /// Get content creation limits for current user
  Map<String, dynamic> getContentLimits() {
    return UserRoleManager.getContentLimits();
  }

  /// Validate file type
  bool _isValidFileType(String fileName) {
    final supportedExtensions = [
      'pdf',
      'doc',
      'docx',
      'ppt',
      'pptx',
      'xls',
      'xlsx',
      'jpg',
      'jpeg',
      'png'
    ];

    final extension = fileName.split('.').last.toLowerCase();
    return supportedExtensions.contains(extension);
  }

  /// Get MIME type for file
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    const mimeTypes = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
    };

    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  // ===== TOPIC-RELATED METHODS (Legal Education Hub) =====

  /// Initialize topics loading for Legal Education hub
  Future<void> initializeTopics({bool hasPresetTopic = false}) async {
    if (hubType != 'legal_ed') return;

    // Check token status before loading topics
    final tokenService = Get.find<TokenStorageService>();
    print('🔑 TOKEN DEBUG: Initializing topics...');
    print('🔑 TOKEN DEBUG: Is logged in: ${tokenService.isLoggedIn}');
    print(
        '🔑 TOKEN DEBUG: Has access token: ${tokenService.accessToken.isNotEmpty}');
    print('🔑 TOKEN DEBUG: Token length: ${tokenService.accessToken.length}');

    // Wait for token service to be ready
    await tokenService.waitForInitialization();

    print(
        '🔑 TOKEN DEBUG: After initialization - Is logged in: ${tokenService.isLoggedIn}');
    print(
        '🔑 TOKEN DEBUG: After initialization - Has access token: ${tokenService.accessToken.isNotEmpty}');

    // Don't auto-select first topic if a preset topic will be set
    await loadAvailableTopics(autoSelectFirst: !hasPresetTopic);
  }

  /// Load available topics for Legal Education
  Future<void> loadAvailableTopics({bool autoSelectFirst = true}) async {
    try {
      isLoadingTopics.value = true;

      final response = await _legalEduService.getTopics(
        isActive: true,
        ordering: 'display_order',
      );

      availableTopics.assignAll(response.results);

      // Auto-select first topic if available and not disabled
      if (autoSelectFirst &&
          availableTopics.isNotEmpty &&
          selectedTopic.value == null) {
        selectedTopic.value = availableTopics.first;
      }
    } catch (e) {
      error.value = 'Failed to load topics: $e';
      Get.snackbar(
        'Error Loading Topics',
        'Failed to load available topics: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingTopics.value = false;
    }
  }

  /// Set selected topic
  void setSelectedTopic(Topic? topic) {
    selectedTopic.value = topic;
  }

  /// Set new topic name for quick creation
  void setNewTopicName(String name) {
    newTopicName.value = name;
  }

  /// Set new topic description for quick creation
  void setNewTopicDescription(String description) {
    newTopicDescription.value = description;
  }

  /// Create a new topic on-the-fly
  Future<Topic?> createNewTopic() async {
    if (newTopicName.value.isEmpty) {
      Get.snackbar(
        'Topic Name Required',
        'Please enter a topic name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }

    try {
      isLoading.value = true;

      // Use the API endpoint from the documentation
      final response = await _legalEduService.quickCreateTopic(
        name: newTopicName.value,
        description: newTopicDescription.value.isEmpty
            ? 'Created during content creation'
            : newTopicDescription.value,
      );

      if (response != null) {
        // Add to available topics
        availableTopics.add(response);

        // Select the new topic
        selectedTopic.value = response;

        // Clear form
        newTopicName.value = '';
        newTopicDescription.value = '';

        Get.snackbar(
          'Topic Created! 🎉',
          'New topic "${response.name}" has been created',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        return response;
      }
    } catch (e) {
      error.value = 'Failed to create topic: $e';
      Get.snackbar(
        'Topic Creation Failed',
        'Failed to create new topic: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }

    return null;
  }

  /// Clear form data
  void clearForm() {
    selectedContentType.value = getAvailableContentTypes().first;
    selectedLanguage.value = 'en';
    isDownloadable.value = false;
    isLectureMaterial.value = false;
    selectedFile.value = null;
    selectedTopic.value =
        availableTopics.isNotEmpty ? availableTopics.first : null;
    newTopicName.value = '';
    newTopicDescription.value = '';
    error.value = '';
  }
}

/// Content creation request model
class HubContentCreateRequest {
  final String hubType;
  final String contentType;
  final String title;
  final String description;
  final String content;
  final String language;
  final String price;
  final String? videoUrl;
  final bool isDownloadable;
  final bool isLectureMaterial;
  final List<int>? fileBytes;
  final String? fileName;
  final int? topicId; // For Legal Education hub

  HubContentCreateRequest({
    required this.hubType,
    required this.contentType,
    required this.title,
    required this.description,
    required this.content,
    required this.language,
    required this.price,
    this.videoUrl,
    required this.isDownloadable,
    required this.isLectureMaterial,
    this.fileBytes,
    this.fileName,
    this.topicId,
  });

  Map<String, dynamic> toJson() {
    final data = {
      'hub_type': hubType,
      'content_type': contentType,
      'title': title,
      'description': description,
      'content': content,
      'language': language,
      'price': price,
      'is_downloadable': isDownloadable,
      'is_lecture_material': isLectureMaterial,
    };

    if (videoUrl != null && videoUrl!.isNotEmpty) {
      data['video_url'] = videoUrl!;
    }

    // Add topic for Legal Education hub
    if (topicId != null) {
      data['topic'] = topicId!;
    }

    if (fileBytes != null && fileName != null) {
      // Convert file to base64 data URL format (as per documentation)
      final base64String = base64Encode(fileBytes!);
      final mimeType = _getMimeType(fileName!);

      // Create data URL format as specified in documentation
      data['file'] = 'data:$mimeType;base64,$base64String';

      print(
          '🔍 toJson: Added file data - name: $fileName, type: $mimeType, size: ${base64String.length} chars');
      print(
          '🔍 toJson: Data URL format: data:$mimeType;base64,[${base64String.length} chars]');
    }

    return data;
  }

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    const mimeTypes = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
    };

    return mimeTypes[extension] ?? 'application/octet-stream';
  }
}
