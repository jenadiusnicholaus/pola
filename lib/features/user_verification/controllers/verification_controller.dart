import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import '../models/verification_models.dart';
import '../services/verification_service.dart';

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

        Get.snackbar(
          'Success',
          'Document uploaded successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return true;
      } else {
        debugPrint('❌ Failed to upload document');
        _error.value = 'Failed to upload document';

        Get.snackbar(
          'Upload Failed',
          'Failed to upload document. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error uploading document: $e');
      _error.value = 'Error uploading document';

      Get.snackbar(
        'Error',
        'An error occurred while uploading the document',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
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

        Get.snackbar(
          'Success',
          'Information updated successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return true;
      } else {
        debugPrint('❌ Failed to update user information');
        _error.value = 'Failed to update information';

        Get.snackbar(
          'Update Failed',
          'Failed to update information. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error updating user information: $e');
      _error.value = 'Error updating information';

      Get.snackbar(
        'Error',
        'An error occurred while updating information',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
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

        Get.snackbar(
          'Success',
          'Verification submitted for review',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return true;
      } else {
        debugPrint('❌ Failed to submit for review');
        _error.value = 'Failed to submit for review';

        Get.snackbar(
          'Submission Failed',
          'Failed to submit for review. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error submitting for review: $e');
      _error.value = 'Error submitting for review';

      Get.snackbar(
        'Error',
        'An error occurred while submitting for review',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
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

        Get.snackbar(
          'Success',
          'Document deleted successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return true;
      } else {
        debugPrint('❌ Failed to delete document');
        _error.value = 'Failed to delete document';

        Get.snackbar(
          'Deletion Failed',
          'Failed to delete document. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error deleting document: $e');
      _error.value = 'Error deleting document';

      Get.snackbar(
        'Error',
        'An error occurred while deleting the document',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
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
      Get.snackbar(
        'Feature Coming Soon',
        'Document upload functionality will be available soon',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('❌ Error picking file: $e');
      Get.snackbar(
        'Error',
        'Failed to pick file',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
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
        Get.snackbar(
          '⚠️ Permission Required',
          'Camera permission is needed to take photos',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final file = File(image.path);
        await _uploadFile(file, documentType, 'Camera Capture');
      }
    } catch (e) {
      debugPrint('❌ Camera upload error: $e');
      Get.snackbar(
        'Error',
        'Failed to capture image: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
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
          Get.snackbar(
            '⚠️ Permission Required',
            'Photo library access is needed to select images',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          return;
        }
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final file = File(image.path);
        await _uploadFile(file, documentType, 'Gallery Selection');
      } else {
        Get.snackbar(
          'ℹ️ No Image Selected',
          'Please select an image to upload',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('❌ Gallery upload error: $e');
      Get.snackbar(
        'Error',
        'Failed to select image: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
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
            Get.snackbar(
              '⚠️ Permission Required',
              'Storage access is needed to browse files',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
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
          Get.snackbar(
            'ℹ️ No File Selected',
            'Please select a file to upload',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.blue.withOpacity(0.8),
            colorText: Colors.white,
          );
          return;
        }
      } catch (filePickerError) {
        debugPrint(
            '⚠️ File picker failed, trying gallery fallback: $filePickerError');

        // Show fallback message
        Get.snackbar(
          '📱 Using Gallery Instead',
          'File browser unavailable. Opening photo gallery...',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        await Future.delayed(const Duration(milliseconds: 500));

        // Fallback to gallery picker
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
        );

        if (image != null) {
          final file = File(image.path);
          await _uploadFile(file, documentType, image.name);
        } else {
          Get.snackbar(
            'ℹ️ No Image Selected',
            'Please select an image from gallery',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.blue.withOpacity(0.8),
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ File upload error: $e');
      Get.snackbar(
        'Error',
        'Failed to select file: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
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
        Get.snackbar(
          '⚠️ File Too Large',
          'File size must be less than 10MB. Selected file is ${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Show uploading progress
      Get.snackbar(
        '📤 Uploading...',
        'Uploading ${_getDocumentDisplayName(documentType)}...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.withOpacity(0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.cloud_upload, color: Colors.white),
        duration: const Duration(seconds: 2),
      );

      // Convert file to base64
      final bytes = await file.readAsBytes();
      final base64File = base64Encode(bytes);

      // Determine file type
      String mimeType = 'application/octet-stream';
      final extension = fileName.split('.').last.toLowerCase();
      switch (extension) {
        case 'pdf':
          mimeType = 'application/pdf';
          break;
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
      }

      // Upload to server
      final success = await _verificationService.uploadDocumentBase64(
        documentType: documentType,
        title: _getDocumentDisplayName(documentType),
        description: 'Uploaded via mobile app',
        fileData: 'data:$mimeType;base64,$base64File',
      );

      if (!success) {
        throw Exception('Server rejected the upload');
      }

      // Show success message
      Get.snackbar(
        '✅ Upload Successful',
        '${_getDocumentDisplayName(documentType)} uploaded successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      // Refresh verification status
      await loadVerificationStatus();
    } catch (e) {
      debugPrint('❌ Upload to server error: $e');
      Get.snackbar(
        'Upload Failed',
        'Failed to upload document: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
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
        Get.snackbar(
          'Error',
          'Document not found',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      debugPrint('❌ Error re-uploading document: $e');
      Get.snackbar(
        'Error',
        'Failed to re-upload document',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }
}
