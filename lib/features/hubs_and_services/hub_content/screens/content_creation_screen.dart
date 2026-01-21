import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/content_creation_controller.dart';
import '../utils/user_role_manager.dart';
import '../../legal_education/models/legal_education_models.dart';

class ContentCreationScreen extends StatefulWidget {
  const ContentCreationScreen({super.key});

  @override
  State<ContentCreationScreen> createState() => _ContentCreationScreenState();
}

class _ContentCreationScreenState extends State<ContentCreationScreen> {
  late String hubType;
  late ContentCreationController controller;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _videoUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Get hub type from arguments
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    hubType = args['hubType'] ?? 'forum';
    final defaultContentType = args['defaultContentType'] as String?;
    final presetTopic = args['currentTopic'] as Map<String, dynamic>?;
    final presetLanguage = args['selectedLanguage'] as String?;

    print('🔍 CONTENT CREATION SCREEN: Arguments received: $args');
    print('🔍 CONTENT CREATION SCREEN: Hub Type set to: "$hubType"');
    print(
        '🔍 CONTENT CREATION SCREEN: Default Content Type: $defaultContentType');
    print('🔍 CONTENT CREATION SCREEN: Preset Topic: $presetTopic');
    print('🔍 CONTENT CREATION SCREEN: Preset Language: $presetLanguage');

    // Initialize controller
    controller = Get.put(ContentCreationController(hubType: hubType));

    // Set initial content type and initialize topics if legal_ed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contentType =
          defaultContentType ?? controller.getAvailableContentTypes().first;
      controller.setContentType(contentType);

      // Set preset language if provided
      if (presetLanguage != null) {
        controller.setLanguage(presetLanguage);
      }

      // Initialize topics for Legal Education hub
      if (hubType == 'legal_ed') {
        controller
            .initializeTopics(hasPresetTopic: presetTopic != null)
            .then((_) {
          // Set preset topic after topics are loaded
          if (presetTopic != null) {
            controller.setPresetTopic(presetTopic);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _videoUrlController.dispose();
    Get.delete<ContentCreationController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create ${_getHubDisplayName()} Content'),
            if (UserRoleManager.isAdmin())
              Text(
                '👑 ${UserRoleManager.getUserRoleDisplayName()}',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              ),
          ],
        ),
        elevation: 0,
        actions: [
          Obx(() => controller.isLoading.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton.icon(
                  onPressed: _submitContent,
                  icon: const Icon(Icons.publish),
                  label: const Text('Publish'),
                )),
          const SizedBox(width: 16),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContentTypeSelector(),
                    const SizedBox(height: 24),
                    if (hubType == 'legal_ed') ...[
                      _buildTopicSelector(),
                      const SizedBox(height: 24),
                    ],
                    _buildTitleField(),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                    const SizedBox(height: 16),
                    _buildContentField(),
                    if (controller.canSetPrice()) ...[
                      const SizedBox(height: 16),
                      _buildPriceField(),
                    ],
                    const SizedBox(height: 16),
                    _buildVideoUrlField(),
                    const SizedBox(height: 24),
                    // Language is defaulted to 'en' (English)
                    if (hubType == 'students') _buildStudentOptions(),
                  ],
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTypeSelector() {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: controller.getAvailableContentTypes().map((type) {
                final isSelected = controller.selectedContentType.value == type;
                return FilterChip(
                  label: Text(_getContentTypeDisplayName(type)),
                  selected: isSelected,
                  onSelected: (_) => controller.setContentType(type),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                );
              }).toList(),
            ),
          ],
        ));
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Title *',
        hintText: 'Enter a clear, descriptive title',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.title),
      ),
      maxLength: 200,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Title is required';
        }
        if (value.trim().length < 5) {
          return 'Title must be at least 5 characters';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description *',
        hintText: 'Brief summary of your content',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 3,
      maxLength: 500,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Description is required';
        }
        if (value.trim().length < 10) {
          return 'Description must be at least 10 characters';
        }
        return null;
      },
    );
  }

  Widget _buildTopicSelector() {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Topic',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            if (controller.isLoadingTopics.value)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Loading topics...'),
                    ],
                  ),
                ),
              )
            else if (controller.availableTopics.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange),
                          SizedBox(width: 12),
                          Expanded(
                              child: Text(
                                  'No topics available. Create a new one:')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildNewTopicForm(),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  // Existing topic selector
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<Topic>(
                      value: controller.selectedTopic.value,
                      hint: const Text('Select a topic'),
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: controller.availableTopics.map((Topic topic) {
                        return DropdownMenuItem<Topic>(
                          value: topic,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                topic.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              if (topic.description.isNotEmpty)
                                Text(
                                  topic.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (Topic? topic) {
                        controller.setSelectedTopic(topic);
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Quick create new topic option
                  Container(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCreateTopicDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Topic'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ));
  }

  Widget _buildNewTopicForm() {
    return Column(
      children: [
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Topic Name *',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (value) => controller.setNewTopicName(value),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Topic Description (optional)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          maxLines: 2,
          onChanged: (value) => controller.setNewTopicDescription(value),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.isLoading.value
                ? null
                : () async {
                    final newTopic = await controller.createNewTopic();
                    if (newTopic != null) {
                      // Topic created and auto-selected
                    }
                  },
            icon: controller.isLoading.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(
                controller.isLoading.value ? 'Creating...' : 'Create Topic'),
          ),
        ),
      ],
    );
  }

  void _showCreateTopicDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Topic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Topic Name *',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => controller.setNewTopicName(value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Topic Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => controller.setNewTopicDescription(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.setNewTopicName('');
              controller.setNewTopicDescription('');
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ||
                        controller.newTopicName.value.isEmpty
                    ? null
                    : () async {
                        final newTopic = await controller.createNewTopic();
                        if (newTopic != null) {
                          Navigator.of(context).pop();
                        }
                      },
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              )),
        ],
      ),
    );
  }

  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced content field with attachment and emoji buttons
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Toolbar with attachments and emoji
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    // Attachment button
                    IconButton(
                      onPressed: _showAttachmentOptions,
                      icon: const Icon(Icons.attach_file),
                      tooltip: 'Attach file',
                      style: IconButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Image button
                    IconButton(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      tooltip: 'Add image',
                      style: IconButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondaryContainer,
                        foregroundColor:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Emoji button
                    IconButton(
                      onPressed: _showEmojiPicker,
                      icon: const Icon(Icons.emoji_emotions),
                      tooltip: 'Add emoji to description',
                      style: IconButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.tertiaryContainer,
                        foregroundColor:
                            Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        ),

        // File preview section
        Obx(() {
          if (controller.selectedFile.value == null) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getFileIcon(controller.selectedFile.value!.name),
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.selectedFile.value!.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatFileSize(controller.selectedFile.value!.size),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => controller.removeFile(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Remove file',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      decoration: const InputDecoration(
        labelText: 'Price (TZS)',
        hintText: '0.00 for free content',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.attach_money),
        suffixText: 'TZS',
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return null; // Optional field
        }
        final price = double.tryParse(value);
        if (price == null || price < 0) {
          return 'Enter a valid price';
        }
        return null;
      },
    );
  }

  Widget _buildVideoUrlField() {
    return TextFormField(
      controller: _videoUrlController,
      decoration: const InputDecoration(
        labelText: 'Video URL (Optional)',
        hintText: 'YouTube, Vimeo, or other video URL',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.video_library),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return null; // Optional field
        }
        final uri = Uri.tryParse(value);
        if (uri == null || !uri.hasScheme) {
          return 'Enter a valid URL';
        }
        return null;
      },
    );
  }

  // Language selector removed - defaulting to 'en' (English)

  Widget _buildStudentOptions() {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Downloadable'),
              subtitle: const Text('Allow users to download attached files'),
              value: controller.isDownloadable.value,
              onChanged: (value) => controller.setDownloadable(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Lecture Material'),
              subtitle: const Text('Mark as official lecture material'),
              value: controller.isLectureMaterial.value,
              onChanged: (value) =>
                  controller.setLectureMaterial(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ));
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _saveDraft,
              child: const Text('Save Draft'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : _submitContent,
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Publish Content'),
                )),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx'],
        withData: true,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        controller.setFile(result.files.single);
      }
    } on PlatformException catch (e) {
      // Handle file picker errors
      String errorMessage = 'Failed to pick document';

      if (e.code == 'read_external_storage_denied') {
        errorMessage =
            'Storage access denied. Please enable storage access in Settings.';
      }

      Get.snackbar(
        'Document Selection Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred while selecting the document',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      // For iOS compatibility, try using file picker for images first
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        await _pickImageWithFilePicker();
      } else {
        await _pickImageWithImagePicker();
      }
    } catch (e) {
      // Fallback to alternative method
      try {
        if (Theme.of(context).platform == TargetPlatform.iOS) {
          await _pickImageWithImagePicker();
        } else {
          await _pickImageWithFilePicker();
        }
      } catch (fallbackError) {
        Get.snackbar(
          'Error',
          'Unable to select image. Please try again or contact support.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _pickImageWithFilePicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        controller.setImageFile(file.path ?? file.name, file.bytes!);
      }
    } on PlatformException catch (e) {
      throw Exception('FilePicker error: ${e.message}');
    }
  }

  Future<void> _pickImageWithImagePicker() async {
    try {
      final picker = ImagePicker();

      // Show source selection dialog
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final result = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
        requestFullMetadata: false, // This helps with iOS compatibility
      );

      if (result != null) {
        final bytes = await result.readAsBytes();
        controller.setImageFile(result.path, bytes);
      }
    } on PlatformException catch (e) {
      // Handle specific iOS image picker errors
      if (e.code == 'invalid_image') {
        throw Exception(
            'Invalid image format detected. This may be due to iOS photo format restrictions.');
      } else {
        throw Exception('ImagePicker error: ${e.message}');
      }
    }
  }

  void _saveDraft() {
    // TODO: Implement save draft functionality
    Get.snackbar(
      'Draft Saved',
      'Your content has been saved as draft',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _submitContent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate topic selection for Legal Education hub
    if (hubType == 'legal_ed' && controller.selectedTopic.value == null) {
      Get.snackbar(
        'Topic Required',
        'Please select a topic for this Legal Education content',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final contentData = HubContentCreateRequest(
      hubType: hubType,
      contentType: controller.selectedContentType.value,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      content: '', // Pass empty string instead of content field
      language: controller.selectedLanguage.value,
      price: _priceController.text.isNotEmpty ? _priceController.text : '0.00',
      videoUrl: _videoUrlController.text.trim().isNotEmpty
          ? _videoUrlController.text.trim()
          : null,
      isDownloadable: controller.isDownloadable.value,
      isLectureMaterial: controller.isLectureMaterial.value,
      fileBytes: controller.selectedFile.value?.bytes,
      fileName: controller.selectedFile.value?.name,
      topicId:
          hubType == 'legal_ed' ? controller.selectedTopic.value?.id : null,
    );

    final success = await controller.createContent(contentData);

    print('🔄 ContentCreationScreen: Content creation success = $success');

    if (success) {
      print(
          '🔄 ContentCreationScreen: Content created successfully, showing success message');

      // Give users time to see the success message before navigating back
      await Future.delayed(const Duration(seconds: 1));

      print('🔄 ContentCreationScreen: Navigating back with result=true');
      Get.back(result: true);
    } else {
      print(
          '🔄 ContentCreationScreen: Content creation failed, not navigating back');
    }
  }

  String _getHubDisplayName() {
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

  String _getContentTypeDisplayName(String type) {
    switch (type) {
      case 'discussion':
        return 'Discussion';
      case 'article':
        return 'Article';
      case 'news':
        return 'News';
      case 'case_study':
        return 'Case Study';
      case 'legal_update':
        return 'Legal Update';
      case 'notes':
        return 'Study Notes';
      case 'past_papers':
        return 'Past Papers';
      case 'assignment':
        return 'Assignment';
      case 'question':
        return 'Question';
      case 'tutorial':
        return 'Tutorial';
      case 'general':
        return 'General';
      case 'lecture':
        return 'Lecture';
      default:
        return type;
    }
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.attach_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Add Attachment',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildAttachmentOption(
                    icon: Icons.attach_file,
                    label: 'Document',
                    subtitle: 'PDF, DOC, PPT, XLS',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _pickDocument();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAttachmentOption(
                    icon: Icons.image,
                    label: 'Image',
                    subtitle: 'JPG, PNG',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    subtitle: 'Take a photo',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _takePicture();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAttachmentOption(
                    icon: Icons.video_library,
                    label: 'Video URL',
                    subtitle: 'YouTube, Vimeo',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _showVideoUrlDialog();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          color: color.withOpacity(0.05),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    final emojis = [
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '😅',
      '😂',
      '🤣',
      '😊',
      '😇',
      '🙂',
      '🙃',
      '😉',
      '😌',
      '😍',
      '🥰',
      '😘',
      '😗',
      '😙',
      '😚',
      '😋',
      '😛',
      '😝',
      '😜',
      '🤪',
      '🤨',
      '🧐',
      '🤓',
      '😎',
      '🤩',
      '🥳',
      '😏',
      '😒',
      '😞',
      '😔',
      '😟',
      '😕',
      '🙁',
      '☹️',
      '😣',
      '😖',
      '😫',
      '😩',
      '🥺',
      '😢',
      '😭',
      '😤',
      '😠',
      '😡',
      '🤬',
      '🤯',
      '😳',
      '🥵',
      '🥶',
      '😱',
      '😨',
      '😰',
      '😥',
      '😓',
      '🤗',
      '🤔',
      '🤭',
      '🤫',
      '🤥',
      '😶',
      '😐',
      '😑',
      '😬',
      '🙄',
      '😯',
      '👍',
      '👎',
      '👌',
      '✌️',
      '🤞',
      '🤟',
      '🤘',
      '🤙',
      '👈',
      '👉',
      '👆',
      '🖕',
      '👇',
      '☝️',
      '👋',
      '🤚',
      '🖐',
      '✋',
      '🖖',
      '👏',
      '🙌',
      '🤲',
      '🙏',
      '✍️',
      '💪',
      '🦾',
      '🦿',
      '🦵',
      '🦶',
      '👂',
      '🔥',
      '💯',
      '💫',
      '⭐',
      '🌟',
      '💥',
      '💦',
      '💨',
      '💤',
      '💢',
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '💜',
      '🖤',
      '🤍',
      '🤎',
      '💔',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Add Emoji',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: emojis.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      _insertEmoji(emojis[index]);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: Center(
                        child: Text(
                          emojis[index],
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _insertEmoji(String emoji) {
    // Insert emoji into the description field instead
    final currentPosition = _descriptionController.selection.base.offset;
    final text = _descriptionController.text;

    final newText = text.substring(0, currentPosition) +
        emoji +
        text.substring(currentPosition);

    _descriptionController.value = _descriptionController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: currentPosition + emoji.length,
      ),
    );
  }

  Future<void> _takePicture() async {
    try {
      final picker = ImagePicker();
      final result = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (result != null) {
        final bytes = await result.readAsBytes();
        controller.setImageFile(result.path, bytes);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to take picture: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showVideoUrlDialog() {
    final videoUrlController =
        TextEditingController(text: _videoUrlController.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Video URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: videoUrlController,
              decoration: const InputDecoration(
                labelText: 'Video URL',
                hintText: 'https://youtube.com/watch?v=...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.video_library),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Supported: YouTube, Vimeo, Dailymotion',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _videoUrlController.text = videoUrlController.text;
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
