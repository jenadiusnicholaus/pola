import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import '../models/verification_models.dart';
import '../services/verification_service.dart';
import '../../../utils/navigation_helper.dart';

class VerificationController extends GetxController {
  final VerificationService _verificationService = VerificationService();

  // Observable state
  final Rx<VerificationStatus?> _verificationStatus =
      Rx<VerificationStatus?>(null);
  final RxBool _isLoading = false.obs;
  final RxBool _isUploading = false.obs;
  final RxString _error = ''.obs;

  // Getters
  VerificationStatus? get verificationStatus => _verificationStatus.value;
  bool get isLoading => _isLoading.value;
  bool get isUploading => _isUploading.value;
  String get error => _error.value;
  bool get hasError => _error.value.isNotEmpty;

  // Computed properties
  bool get needsVerification {
    final status = _verificationStatus.value;
    if (status == null) return false;
    return status.needsVerification;
  }

  bool get isVerified {
    final status = _verificationStatus.value;
    if (status == null) return false;
    return status.isVerified;
  }

  bool get hasVerificationData => _verificationStatus.value != null;

  List<RequiredDocument> get requiredDocuments {
    return _verificationStatus.value?.requiredDocuments ?? [];
  }

  List<RequiredDocument> get missingRequiredDocuments {
    return requiredDocuments.where((doc) => doc.needsUpload).toList();
  }

  List<VerificationDocument> get uploadedDocuments {
    return _verificationStatus.value?.documents ?? [];
  }

  MissingInformation? get missingInformation {
    return _verificationStatus.value?.missingInformation;
  }

  List<String> get allIssues {
    return missingInformation?.allIssues ?? [];
  }

  double get verificationProgress {
    return _verificationStatus.value?.progress ?? 0.0;
  }

  String get currentStep {
    return _verificationStatus.value?.currentStep ?? 'documents';
  }

  String get currentStepDisplay {
    return _verificationStatus.value?.currentStepDisplay ?? 'Documents';
  }

  @override
  void onInit() {
    super.onInit();
    // Load verification status when controller initializes
    loadVerificationStatus();
  }

  /// Load user's verification status
  Future<void> loadVerificationStatus() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      debugPrint('🔄 Loading verification status...');

      final status = await _verificationService.getMyVerificationStatus();
      _verificationStatus.value = status;

      if (status != null) {
        debugPrint('✅ Verification status loaded successfully');
        debugPrint('Status: ${status.status}, Progress: ${status.progress}%');
      } else {
        debugPrint('ℹ️ No verification status found');
      }
    } catch (e) {
      debugPrint('❌ Error loading verification status: $e');
      _error.value = 'Failed to load verification status';
    } finally {
      _isLoading.value = false;
    }
  }

  /// Refresh verification status
  Future<void> refreshVerificationStatus() async {
    await loadVerificationStatus();
  }

  /// Upload a document
  Future<bool> uploadDocument({
    required String documentType,
    required File file,
    required String title,
    String? description,
  }) async {
    try {
      _isUploading.value = true;
      _error.value = '';

      debugPrint('📄 Uploading document: $documentType');

      final success = await _verificationService.uploadDocument(
        documentType: documentType,
        file: file,
        title: title,
        description: description,
      );

      if (success) {
        debugPrint('✅ Document uploaded successfully');
        // Refresh status to get updated documents
        await refreshVerificationStatus();

        NavigationHelper.showSafeSnackbar(
          title: 'Success',
          message: 'Document uploaded successfully',
          backgroundColor: Colors.green,
        );
        return true;
      } else {
        debugPrint('❌ Failed to upload document');
        _error.value = 'Failed to upload document';

        NavigationHelper.showSafeSnackbar(
          title: 'Upload Failed',
          message: 'Failed to upload document. Please try again.',
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error uploading document: $e');
      _error.value = 'Error uploading document';

      NavigationHelper.showSafeSnackbar(
        title: 'Error',
        message: 'An error occurred while uploading the document',
        backgroundColor: Colors.red,
      );
      return false;
    } finally {
      _isUploading.value = false;
    }
  }

  /// Update user information
  Future<bool> updateUserInformation({
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? gender,
    String? phoneNumber,
    String? officeAddress,
    String? ward,
    String? district,
    String? region,
    Map<String, dynamic>? roleSpecificData,
  }) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      debugPrint('🔄 Updating user information...');

      final success = await _verificationService.updateUserInformation(
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        phoneNumber: phoneNumber,
        officeAddress: officeAddress,
        ward: ward,
        district: district,
        region: region,
        roleSpecificData: roleSpecificData,
      );

      if (success) {
        debugPrint('✅ User information updated successfully');
        // Refresh status to get updated info
        await refreshVerificationStatus();

        NavigationHelper.showSafeSnackbar(
          title: 'Success',
          message: 'Information updated successfully',
          backgroundColor: Colors.green,
        );
        return true;
      } else {
        debugPrint('❌ Failed to update user information');
        _error.value = 'Failed to update information';

        NavigationHelper.showSafeSnackbar(
          title: 'Update Failed',
          message: 'Failed to update information. Please try again.',
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error updating user information: $e');
      _error.value = 'Error updating information';

      NavigationHelper.showSafeSnackbar(
        title: 'Error',
        message: 'An error occurred while updating information',
        backgroundColor: Colors.red,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Submit verification for admin review
  Future<bool> submitForReview() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      debugPrint('📋 Submitting for review...');

      final success = await _verificationService.submitForReview();

      if (success) {
        debugPrint('✅ Submitted for review successfully');
        // Refresh status
        await refreshVerificationStatus();

        NavigationHelper.showSafeSnackbar(
          title: 'Success',
          message: 'Verification submitted for review',
          backgroundColor: Colors.green,
        );
        return true;
      } else {
        debugPrint('❌ Failed to submit for review');
        _error.value = 'Failed to submit for review';

        NavigationHelper.showSafeSnackbar(
          title: 'Submission Failed',
          message: 'Failed to submit for review. Please try again.',
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error submitting for review: $e');
      _error.value = 'Error submitting for review';

      NavigationHelper.showSafeSnackbar(
        title: 'Error',
        message: 'An error occurred while submitting for review',
        backgroundColor: Colors.red,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Delete a document
  Future<bool> deleteDocument(int documentId) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      debugPrint('🗑️ Deleting document: $documentId');

      final success = await _verificationService.deleteDocument(documentId);

      if (success) {
        debugPrint('✅ Document deleted successfully');
        // Refresh status to update documents list
        await refreshVerificationStatus();

        NavigationHelper.showSafeSnackbar(
          title: 'Success',
          message: 'Document deleted successfully',
          backgroundColor: Colors.green,
        );
        return true;
      } else {
        debugPrint('❌ Failed to delete document');
        _error.value = 'Failed to delete document';

        NavigationHelper.showSafeSnackbar(
          title: 'Deletion Failed',
          message: 'Failed to delete document. Please try again.',
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error deleting document: $e');
      _error.value = 'Error deleting document';

      NavigationHelper.showSafeSnackbar(
        title: 'Error',
        message: 'An error occurred while deleting the document',
        backgroundColor: Colors.red,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Clear error message
  void clearError() {
    _error.value = '';
  }

  /// Check if user role needs verification
  static bool roleNeedsVerification(String roleName) {
    return VerificationService.roleNeedsVerification(roleName);
  }

  /// Get verification status color
  Color getStatusColor() {
    final status = _verificationStatus.value;
    if (status == null) return Colors.grey;

    switch (status.status) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get verification status icon
  IconData getStatusIcon() {
    final status = _verificationStatus.value;
    if (status == null) return Icons.help_outline;

    switch (status.status) {
      case 'verified':
        return Icons.verified;
      case 'pending':
        return Icons.pending;
      case 'rejected':
        return Icons.error_outline;
      default:
        return Icons.help_outline;
    }
  }

  /// Pick file and upload document
  Future<void> pickAndUploadDocument(String documentType) async {
    try {
      // For now, just show a placeholder message
      // TODO: Implement file picker when dependency is added
      NavigationHelper.showSafeSnackbar(
        title: 'Feature Coming Soon',
        message: 'Document upload functionality will be available soon',
      );
    } catch (e) {
      debugPrint('❌ Error picking file: $e');
      NavigationHelper.showSafeSnackbar(
        title: 'Error',
        message: 'Failed to pick file',
        backgroundColor: Colors.red,
      );
    }
  }

  /// Upload document from camera
  Future<void> uploadDocumentFromCamera(String documentType) async {
    try {
      _isUploading.value = true;

      // Check camera permission
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus != PermissionStatus.granted) {
        NavigationHelper.showSafeSnackbar(
          title: '⚠️ Permission Required',
          message: 'Camera permission is needed to take photos',
          backgroundColor: Colors.orange,
        );
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90, // Higher quality for camera captures
        maxWidth: 1920,
        maxHeight: 1080,
        preferredCameraDevice:
            CameraDevice.rear, // Use rear camera for documents
      );

      if (image != null) {
        final file = File(image.path);

        // Additional validation before upload
        if (!await file.exists()) {
          throw Exception('Captured image file is not accessible');
        }

        // Check file size (limit to 15MB for camera captures)
        final fileSize = await file.length();
        if (fileSize > 15 * 1024 * 1024) {
          NavigationHelper.showSafeSnackbar(
            title: '⚠️ Image Too Large',
            message: 'Captured image is too large. Please try again with lower quality.',
            backgroundColor: Colors.orange,
          );
          return;
        }

        await _uploadFile(file, documentType, 'Camera Capture');
      } else {
        NavigationHelper.showSafeSnackbar(
          title: 'ℹ️ No Photo Taken',
          message: 'Please take a photo to upload',
          backgroundColor: Colors.blue.withOpacity(0.8),
        );
      }
    } catch (e) {
      debugPrint('❌ Camera upload error: $e');

      String errorMessage = 'Failed to capture image';

      // Provide specific error messages for common camera issues
      if (e.toString().contains('Camera access denied')) {
        errorMessage =
            'Camera access denied. Please enable camera permission in Settings.';
      } else if (e.toString().contains('Camera not available')) {
        errorMessage = 'Camera not available on this device.';
      } else if (e.toString().contains('No camera found')) {
        errorMessage = 'No camera found. Please try using gallery instead.';
      }

      NavigationHelper.showSafeSnackbar(
        title: '📷 Camera Error',
        message: errorMessage,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      );
    } finally {
      _isUploading.value = false;
    }
  }

  /// Upload document from gallery
  Future<void> uploadDocumentFromGallery(String documentType) async {
    try {
      _isUploading.value = true;

      // Check photo library permission
      final photoStatus = await Permission.photos.request();
      if (photoStatus != PermissionStatus.granted) {
        // Try media library permission for Android
        final mediaStatus = await Permission.mediaLibrary.request();
        if (mediaStatus != PermissionStatus.granted) {
          NavigationHelper.showSafeSnackbar(
            title: '⚠️ Permission Required',
            message: 'Photo library access is needed to select images',
            backgroundColor: Colors.orange,
          );
          return;
        }
      }

      final ImagePicker picker = ImagePicker();

      // Try with different image picker configurations for better iOS compatibility
      XFile? image;

      try {
        // First attempt with standard settings
        image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
        );
      } catch (iosError) {
        debugPrint('⚠️ First attempt failed: $iosError');

        // Second attempt with more conservative settings for iOS compatibility
        try {
          image = await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 70,
            maxWidth: 1024,
            maxHeight: 1024,
          );
        } catch (fallbackError) {
          debugPrint('⚠️ Fallback attempt failed: $fallbackError');

          // Check if it's the specific iOS JPEG error
          if (fallbackError
                  .toString()
                  .contains('Cannot load representation of type public.jpeg') ||
              fallbackError.toString().contains('invalid_image')) {
            // Show alternative upload options
            Future.delayed(const Duration(milliseconds: 300), () {
              showAlternativeUploadOptions(documentType);
            });

            return;
          }

          // Re-throw other errors
          throw fallbackError;
        }
      }

      if (image != null) {
        // Additional validation before upload
        final file = File(image.path);

        // Check if file exists and is accessible
        if (!await file.exists()) {
          throw Exception('Selected image file is not accessible');
        }

        // Check file size (limit to 10MB)
        final fileSize = await file.length();
        if (fileSize > 10 * 1024 * 1024) {
          NavigationHelper.showSafeSnackbar(
            title: '⚠️ File Too Large',
            message: 'Image size must be less than 10MB. Please select a smaller image or reduce quality.',
            backgroundColor: Colors.orange,
          );
          return;
        }

        await _uploadFile(file, documentType, 'Gallery Selection');
      } else {
        NavigationHelper.showSafeSnackbar(
          title: 'ℹ️ No Image Selected',
          message: 'Please select an image to upload',
          backgroundColor: Colors.blue.withOpacity(0.8),
        );
      }
    } catch (e) {
      debugPrint('❌ Gallery upload error: $e');

      String errorMessage = 'Failed to select image';

      // Provide specific error messages for common issues
      if (e.toString().contains('Cannot load representation')) {
        errorMessage =
            'Image format not supported. Please try a different image or take a new photo.';
      } else if (e.toString().contains('invalid_image')) {
        errorMessage =
            'Invalid image file. Please select a valid image from your gallery.';
      } else if (e.toString().contains('Permission denied')) {
        errorMessage =
            'Gallery access permission denied. Please enable photo library access in Settings.';
      }

      NavigationHelper.showSafeSnackbar(
        title: '📱 Gallery Error',
        message: errorMessage,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      );
    } finally {
      _isUploading.value = false;
    }
  }

  /// Upload document from files
  Future<void> uploadDocumentFromFiles(String documentType) async {
    try {
      _isUploading.value = true;

      // Check storage permission for Android
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.request();
        if (storageStatus != PermissionStatus.granted) {
          // Try manage external storage for Android 11+
          final manageStorageStatus =
              await Permission.manageExternalStorage.request();
          if (manageStorageStatus != PermissionStatus.granted) {
            NavigationHelper.showSafeSnackbar(
              title: '⚠️ Permission Required',
              message: 'Storage access is needed to browse files',
              backgroundColor: Colors.orange,
            );
            return;
          }
        }
      }

      // Try file picker first, fallback to gallery if it fails
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
          allowMultiple: false,
        );

        if (result != null && result.files.single.path != null) {
          final file = File(result.files.single.path!);
          await _uploadFile(file, documentType, result.files.single.name);
          return; // Success with file picker
        } else {
          NavigationHelper.showSafeSnackbar(
            title: 'ℹ️ No File Selected',
            message: 'Please select a file to upload',
            backgroundColor: Colors.blue.withOpacity(0.8),
          );
          return;
        }
      } catch (filePickerError) {
        debugPrint(
            '⚠️ File picker failed, trying gallery fallback: $filePickerError');

        // Show fallback message
        NavigationHelper.showSafeSnackbar(
          title: '📱 Using Gallery Instead',
          message: 'File browser unavailable. Opening photo gallery...',
          backgroundColor: Colors.blue.withOpacity(0.8),
          duration: const Duration(seconds: 2),
        );

        await Future.delayed(const Duration(milliseconds: 500));

        // Fallback to gallery picker with improved error handling
        final ImagePicker picker = ImagePicker();
        XFile? image;

        try {
          // First attempt with standard settings
          image = await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
            maxWidth: 1920,
            maxHeight: 1080,
          );
        } catch (galleryError) {
          debugPrint('⚠️ Gallery fallback failed: $galleryError');

          // Try with conservative settings for iOS compatibility
          try {
            image = await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 70,
              maxWidth: 1024,
              maxHeight: 1024,
            );
          } catch (finalError) {
            if (finalError.toString().contains(
                    'Cannot load representation of type public.jpeg') ||
                finalError.toString().contains('invalid_image')) {
              NavigationHelper.showSafeSnackbar(
                title: '📱 Image Format Issue',
                message: 'Unable to load this image format. Please try taking a new photo with the camera instead.',
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              );
              return;
            }
            throw finalError;
          }
        }

        if (image != null) {
          final file = File(image.path);

          // Check file accessibility and size
          if (!await file.exists()) {
            throw Exception('Selected image file is not accessible');
          }

          final fileSize = await file.length();
          if (fileSize > 10 * 1024 * 1024) {
            NavigationHelper.showSafeSnackbar(
              title: '⚠️ File Too Large',
              message: 'Image size must be less than 10MB. Please select a smaller image.',
              backgroundColor: Colors.orange,
            );
            return;
          }

          await _uploadFile(file, documentType, image.name);
        } else {
          NavigationHelper.showSafeSnackbar(
            title: 'ℹ️ No Image Selected',
            message: 'Please select an image from gallery',
            backgroundColor: Colors.blue.withOpacity(0.8),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ File upload error: $e');
      NavigationHelper.showSafeSnackbar(
        title: 'Error',
        message: 'Failed to select file: $e',
        backgroundColor: Colors.red,
      );
    } finally {
      _isUploading.value = false;
    }
  }

  /// Helper method to upload file to server
  Future<void> _uploadFile(
      File file, String documentType, String fileName) async {
    try {
      // Validate file size (10MB limit)
      final fileSize = await file.length();
      const maxSize = 10 * 1024 * 1024; // 10MB

      if (fileSize > maxSize) {
        NavigationHelper.showSafeSnackbar(
          title: '⚠️ File Too Large',
          message: 'File size must be less than 10MB. Selected file is ${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB',
          backgroundColor: Colors.orange,
        );
        return;
      }

      // Show loading dialog with progress
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Uploading...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getDocumentDisplayName(documentType),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Convert file to base64
      final bytes = await file.readAsBytes();
      final base64File = base64Encode(bytes);

      // Upload to server
      final success = await _verificationService.uploadDocumentBase64(
        documentType: documentType,
        base64Data: base64File,
        fileName: _getDocumentDisplayName(documentType),
        description: 'Uploaded via mobile app',
      );

      // Close loading dialog
      Get.back();

      if (!success) {
        throw Exception('Server rejected the upload');
      }

      // Show success message
      NavigationHelper.showSafeSnackbar(
        title: '✅ Upload Successful',
        message: '${_getDocumentDisplayName(documentType)} uploaded successfully!',
        backgroundColor: Colors.green,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      // Refresh verification status
      await loadVerificationStatus();
    } catch (e) {
      debugPrint('❌ Upload to server error: $e');

      // Close loading dialog if still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      NavigationHelper.showSafeSnackbar(
        title: 'Upload Failed',
        message: 'Failed to upload document: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  /// Get display name for document type
  String _getDocumentDisplayName(String documentType) {
    final requiredDoc = _verificationStatus.value?.requiredDocuments
        .firstWhereOrNull((doc) => doc.documentType == documentType);
    return requiredDoc?.documentTypeDisplay ??
        documentType.replaceAll('_', ' ').toUpperCase();
  }

  /// Upload document wrapper for detailed verification step
  Future<void> uploadDocumentByType(String documentType) async {
    await pickAndUploadDocument(documentType);
  }

  /// Re-upload document for rejected documents
  Future<void> reuploadDocument(int documentId) async {
    try {
      // Find the document type
      final doc = uploadedDocuments.firstWhereOrNull((d) => d.id == documentId);
      if (doc != null) {
        await pickAndUploadDocument(doc.documentType);
      } else {
        NavigationHelper.showSafeSnackbar(
          title: 'Error',
          message: 'Document not found',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      debugPrint('❌ Error re-uploading document: $e');
      NavigationHelper.showSafeSnackbar(
        title: 'Error',
        message: 'Failed to re-upload document',
        backgroundColor: Colors.red,
      );
    }
  }

  /// Show alternative upload options when gallery fails
  void showAlternativeUploadOptions(String documentType) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📱 Alternative Upload Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gallery selection failed. Try these alternatives:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Camera option
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera to capture document'),
              onTap: () {
                Get.back();
                uploadDocumentFromCamera(documentType);
              },
            ),

            // File browser option
            ListTile(
              leading: const Icon(Icons.file_present, color: Colors.green),
              title: const Text('Browse Files'),
              subtitle: const Text('Select from file manager'),
              onTap: () {
                Get.back();
                uploadDocumentFromFiles(documentType);
              },
            ),

            // Tips section
            const Divider(),
            const ListTile(
              leading: Icon(Icons.lightbulb_outline, color: Colors.orange),
              title: Text('💡 Tips for iOS Users'),
              subtitle: Text(
                '• Convert images to JPEG format before selecting\n'
                '• Use camera for better compatibility\n'
                '• Ensure images are not corrupted or too large',
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }
}
