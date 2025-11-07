import 'package:flutter/foundation.dart';

class VerificationStatus {
  final int id;
  final int user;
  final String userEmail;
  final String userName;
  final String userFullName;
  final UserRole userRole;
  final String userPhone;
  final UserAddress userAddress;
  final String userDateOfBirth;
  final String userGender;
  final String status;
  final String statusDisplay;
  final String currentStep;
  final String currentStepDisplay;
  final int? verifiedBy;
  final String? verifiedByName;
  final String? verificationDate;
  final String? rejectionReason;
  final String? verificationNotes;
  final double progress;
  final List<VerificationDocument> documents;
  final List<RequiredDocument> requiredDocuments;
  final DocumentsSummary documentsSummary;
  final MissingInformation missingInformation;
  final int daysSinceRegistration;
  final String createdAt;
  final String updatedAt;

  VerificationStatus({
    required this.id,
    required this.user,
    required this.userEmail,
    required this.userName,
    required this.userFullName,
    required this.userRole,
    required this.userPhone,
    required this.userAddress,
    required this.userDateOfBirth,
    required this.userGender,
    required this.status,
    required this.statusDisplay,
    required this.currentStep,
    required this.currentStepDisplay,
    this.verifiedBy,
    this.verifiedByName,
    this.verificationDate,
    this.rejectionReason,
    this.verificationNotes,
    required this.progress,
    required this.documents,
    required this.requiredDocuments,
    required this.documentsSummary,
    required this.missingInformation,
    required this.daysSinceRegistration,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    try {
      return VerificationStatus(
        id: _safeInt(json['id']),
        user: _safeInt(json['user']),
        userEmail: json['user_email']?.toString() ?? '',
        userName: json['user_name']?.toString() ?? '',
        userFullName: json['user_full_name']?.toString() ?? '',
        userRole: UserRole.fromJson(json['user_role'] ?? {}),
        userPhone: json['user_phone']?.toString() ?? '',
        userAddress: UserAddress.fromJson(json['user_address'] ?? {}),
        userDateOfBirth: json['user_date_of_birth']?.toString() ?? '',
        userGender: json['user_gender']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
        statusDisplay: json['status_display']?.toString() ?? 'Pending',
        currentStep: json['current_step']?.toString() ?? 'documents',
        currentStepDisplay:
            json['current_step_display']?.toString() ?? 'Documents',
        verifiedBy: _safeInt(json['verified_by']),
        verifiedByName: json['verified_by_name']?.toString(),
        verificationDate: json['verification_date']?.toString(),
        rejectionReason: json['rejection_reason']?.toString(),
        verificationNotes: json['verification_notes']?.toString(),
        progress: _safeDouble(json['progress']),
        documents: _safeDocumentsList(json['documents']),
        requiredDocuments:
            _safeRequiredDocumentsList(json['required_documents']),
        documentsSummary:
            DocumentsSummary.fromJson(json['documents_summary'] ?? {}),
        missingInformation:
            MissingInformation.fromJson(json['missing_information'] ?? {}),
        daysSinceRegistration: _safeInt(json['days_since_registration']),
        createdAt: json['created_at']?.toString() ?? '',
        updatedAt: json['updated_at']?.toString() ?? '',
      );
    } catch (e) {
      debugPrint('Error parsing VerificationStatus: $e');
      return VerificationStatus(
        id: 0,
        user: 0,
        userEmail: '',
        userName: '',
        userFullName: '',
        userRole: UserRole(id: 0, name: 'user', display: 'User'),
        userPhone: '',
        userAddress:
            UserAddress(officeAddress: '', ward: '', district: '', region: ''),
        userDateOfBirth: '',
        userGender: '',
        status: 'pending',
        statusDisplay: 'Pending',
        currentStep: 'documents',
        currentStepDisplay: 'Documents',
        verifiedBy: null,
        verifiedByName: null,
        verificationDate: null,
        rejectionReason: null,
        verificationNotes: null,
        progress: 0.0,
        documents: [],
        requiredDocuments: [],
        documentsSummary: DocumentsSummary(
            totalUploaded: 0, verified: 0, rejected: 0, pending: 0),
        missingInformation: MissingInformation(
            hasMissingItems: false,
            isReadyForApproval: false,
            byStep: {},
            currentStep: 'documents',
            summary: ''),
        daysSinceRegistration: 0,
        createdAt: '',
        updatedAt: '',
      );
    }
  }

  // Helper methods for safe type conversion
  static int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static double _safeDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static List<VerificationDocument> _safeDocumentsList(dynamic value) {
    if (value is List) {
      return value
          .map((doc) {
            try {
              return VerificationDocument.fromJson(
                  doc is Map<String, dynamic> ? doc : {});
            } catch (e) {
              debugPrint('Error parsing VerificationDocument: $e');
              return null;
            }
          })
          .where((doc) => doc != null)
          .cast<VerificationDocument>()
          .toList();
    }
    return [];
  }

  static List<RequiredDocument> _safeRequiredDocumentsList(dynamic value) {
    if (value is List) {
      return value
          .map((doc) {
            try {
              return RequiredDocument.fromJson(
                  doc is Map<String, dynamic> ? doc : {});
            } catch (e) {
              debugPrint('Error parsing RequiredDocument: $e');
              return null;
            }
          })
          .where((doc) => doc != null)
          .cast<RequiredDocument>()
          .toList();
    }
    return [];
  }

  // Helper methods
  bool get isVerified => status == 'verified';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get needsVerification => !isVerified;
  bool get isSubmittedForReview =>
      status == 'submitted' || status == 'under_review';

  // Convenience getter for submitted documents
  List<VerificationDocument> get submittedDocuments => documents;

  // Check if user needs verification based on role
  static bool roleNeedsVerification(String roleName) {
    return ['advocate', 'lawyer', 'law_firm', 'paralegal'].contains(roleName);
  }
}

class UserRole {
  final int id;
  final String name;
  final String display;

  UserRole({
    required this.id,
    required this.name,
    required this.display,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      display: json['display'] ?? '',
    );
  }
}

class UserAddress {
  final String? officeAddress;
  final String? ward;
  final String? district;
  final String? region;

  UserAddress({
    this.officeAddress,
    this.ward,
    this.district,
    this.region,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      officeAddress: json['office_address'],
      ward: json['ward'],
      district: json['district'],
      region: json['region'],
    );
  }

  String get fullAddress {
    final parts = [officeAddress, ward, district, region]
        .where((part) => part != null && part.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}

class VerificationDocument {
  final int id;
  final int user;
  final String userEmail;
  final String userName;
  final String userFullName;
  final String documentType;
  final String documentTypeDisplay;
  final String file;
  final String fileUrl;
  final String fileType;
  final String fileExtension;
  final int fileSize;
  final bool isImage;
  final bool isPdf;
  final String previewUrl;
  final String title;
  final String description;
  final String verificationStatus;
  final String verificationStatusDisplay;
  final int? verifiedBy;
  final String? verifiedByName;
  final String? verificationDate;
  final String? verificationNotes;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  VerificationDocument({
    required this.id,
    required this.user,
    required this.userEmail,
    required this.userName,
    required this.userFullName,
    required this.documentType,
    required this.documentTypeDisplay,
    required this.file,
    required this.fileUrl,
    required this.fileType,
    required this.fileExtension,
    required this.fileSize,
    required this.isImage,
    required this.isPdf,
    required this.previewUrl,
    required this.title,
    required this.description,
    required this.verificationStatus,
    required this.verificationStatusDisplay,
    this.verifiedBy,
    this.verifiedByName,
    this.verificationDate,
    this.verificationNotes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VerificationDocument.fromJson(Map<String, dynamic> json) {
    return VerificationDocument(
      id: json['id'] ?? 0,
      user: json['user'] ?? 0,
      userEmail: json['user_email'] ?? '',
      userName: json['user_name'] ?? '',
      userFullName: json['user_full_name'] ?? '',
      documentType: json['document_type'] ?? '',
      documentTypeDisplay: json['document_type_display'] ?? '',
      file: json['file'] ?? '',
      fileUrl: json['file_url'] ?? '',
      fileType: json['file_type'] ?? '',
      fileExtension: json['file_extension'] ?? '',
      fileSize: json['file_size'] ?? 0,
      isImage: json['is_image'] ?? false,
      isPdf: json['is_pdf'] ?? false,
      previewUrl: json['preview_url'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      verificationStatus: json['verification_status'] ?? 'pending',
      verificationStatusDisplay:
          json['verification_status_display'] ?? 'Pending',
      verifiedBy: json['verified_by'],
      verifiedByName: json['verified_by_name'],
      verificationDate: json['verification_date'],
      verificationNotes: json['verification_notes'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  bool get isVerified => verificationStatus == 'verified';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';

  // Convenience getters for widget compatibility
  String get status => verificationStatus;
  String get statusDisplay => verificationStatusDisplay;
  String get fileName => file.split('/').last;
  int get fileSizeBytes => fileSize;
  String get uploadedAt => createdAt;
  String? get rejectionReason => verificationNotes;
}

class RequiredDocument {
  final String type;
  final String label;
  final bool required;
  final bool uploaded;
  final String status;
  final int? documentId;

  RequiredDocument({
    required this.type,
    required this.label,
    required this.required,
    required this.uploaded,
    required this.status,
    this.documentId,
  });

  factory RequiredDocument.fromJson(Map<String, dynamic> json) {
    return RequiredDocument(
      type: json['type'] ?? '',
      label: json['label'] ?? '',
      required: json['required'] ?? false,
      uploaded: json['uploaded'] ?? false,
      status: json['status'] ?? 'pending',
      documentId: json['document_id'],
    );
  }

  bool get isVerified => status == 'verified';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get needsUpload => required && !uploaded;

  // Convenience getters for widget compatibility
  String get documentType => type;
  String get documentTypeDisplay => label;
  bool get isSubmitted => uploaded;
  String? get description => null; // Can be added if needed
  int get maxSizeMB => 10; // Default max size, can be made configurable
}

class DocumentsSummary {
  final int totalUploaded;
  final int verified;
  final int pending;
  final int rejected;
  final String? latestUpload;

  DocumentsSummary({
    required this.totalUploaded,
    required this.verified,
    required this.pending,
    required this.rejected,
    this.latestUpload,
  });

  factory DocumentsSummary.fromJson(Map<String, dynamic> json) {
    return DocumentsSummary(
      totalUploaded: json['total_uploaded'] ?? 0,
      verified: json['verified'] ?? 0,
      pending: json['pending'] ?? 0,
      rejected: json['rejected'] ?? 0,
      latestUpload: json['latest_upload'],
    );
  }
}

class MissingInformation {
  final bool hasMissingItems;
  final bool isReadyForApproval;
  final Map<String, VerificationStep> byStep;
  final String currentStep;
  final String summary;

  MissingInformation({
    required this.hasMissingItems,
    required this.isReadyForApproval,
    required this.byStep,
    required this.currentStep,
    required this.summary,
  });

  factory MissingInformation.fromJson(Map<String, dynamic> json) {
    final Map<String, VerificationStep> steps = {};
    try {
      if (json['by_step'] is Map) {
        (json['by_step'] as Map).forEach((key, value) {
          try {
            if (value is Map<String, dynamic>) {
              steps[key.toString()] = VerificationStep.fromJson(value);
            }
          } catch (e) {
            debugPrint('Error parsing step $key: $e');
          }
        });
      }
    } catch (e) {
      debugPrint('Error parsing by_step: $e');
    }

    try {
      return MissingInformation(
        hasMissingItems: VerificationStep._safeBool(json['has_missing_items']),
        isReadyForApproval:
            VerificationStep._safeBool(json['is_ready_for_approval']),
        byStep: steps,
        currentStep: json['current_step']?.toString() ?? 'documents',
        summary: json['summary']?.toString() ?? '',
      );
    } catch (e) {
      debugPrint('Error creating MissingInformation: $e');
      return MissingInformation(
        hasMissingItems: false,
        isReadyForApproval: false,
        byStep: {},
        currentStep: 'documents',
        summary: '',
      );
    }
  }

  List<VerificationStep> get incompleteSteps {
    return byStep.values.where((step) => step.status != 'complete').toList();
  }

  List<String> get allIssues {
    return byStep.values.expand((step) => step.issues).toList();
  }

  // For widget compatibility - treat as empty list if no missing items
  bool get isEmpty => !hasMissingItems;

  // Convert to list of missing information items for widget compatibility
  Iterable<MissingInformationItem> where(
      bool Function(MissingInformationItem) test) {
    final items = <MissingInformationItem>[];

    for (final step in byStep.values) {
      for (final issue in step.issues) {
        items.add(MissingInformationItem(
          fieldName: step.title,
          fieldDisplayName: step.title,
          description: issue,
          isProvided: false,
        ));
      }
    }

    return items.where(test);
  }
}

class VerificationStep {
  final String status;
  final bool isCurrent;
  final List<String> issues;
  final List<String> requiredFields;
  final List<VerifiedField> verifiedFields;
  final String title;

  VerificationStep({
    required this.status,
    required this.isCurrent,
    required this.issues,
    required this.requiredFields,
    required this.verifiedFields,
    required this.title,
  });

  factory VerificationStep.fromJson(Map<String, dynamic> json) {
    try {
      return VerificationStep(
        status: json['status']?.toString() ?? 'pending',
        isCurrent: json['is_current'] ?? false,
        issues: _safeStringList(json['issues']),
        requiredFields: _safeStringList(json['required_fields']),
        verifiedFields: _safeVerifiedFieldsList(json['verified_fields']),
        title: json['title']?.toString() ?? json['name']?.toString() ?? 'Step',
      );
    } catch (e) {
      debugPrint('Error parsing VerificationStep: $e');
      return VerificationStep(
        status: 'pending',
        isCurrent: false,
        issues: [],
        requiredFields: [],
        verifiedFields: [],
        title: 'Step',
      );
    }
  }

  static bool _safeBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value != 0;
    return false;
  }

  static List<String> _safeStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').toList();
    }
    return [];
  }

  static List<VerifiedField> _safeVerifiedFieldsList(dynamic value) {
    if (value is List) {
      return value
          .map((field) {
            try {
              return VerifiedField.fromJson(
                  field is Map<String, dynamic> ? field : {});
            } catch (e) {
              debugPrint('Error parsing VerifiedField: $e');
              return null;
            }
          })
          .where((field) => field != null)
          .cast<VerifiedField>()
          .toList();
    }
    return [];
  }

  bool get isComplete => status == 'complete';
  bool get isPending => status == 'pending';
  bool get hasIssues => issues.isNotEmpty;
}

class VerifiedField {
  final String field;
  final String label;
  final dynamic value;
  final String status;

  VerifiedField({
    required this.field,
    required this.label,
    required this.value,
    required this.status,
  });

  factory VerifiedField.fromJson(Map<String, dynamic> json) {
    try {
      return VerifiedField(
        field: json['field']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        value: json['value'],
        status: json['status']?.toString() ?? 'pending',
      );
    } catch (e) {
      debugPrint('Error parsing VerifiedField: $e');
      return VerifiedField(
        field: '',
        label: '',
        value: null,
        status: 'pending',
      );
    }
  }

  bool get isVerified => status == 'verified';
}

class MissingInformationItem {
  final String fieldName;
  final String fieldDisplayName;
  final String? description;
  final bool isProvided;

  MissingInformationItem({
    required this.fieldName,
    required this.fieldDisplayName,
    this.description,
    required this.isProvided,
  });
}

class DocumentUploadResult {
  final bool success;
  final String message;
  final VerificationDocument? document;

  DocumentUploadResult({
    required this.success,
    required this.message,
    this.document,
  });

  factory DocumentUploadResult.fromJson(Map<String, dynamic> json) {
    return DocumentUploadResult(
      success: json['success'] ?? true,
      message: json['message'] ?? 'Document uploaded successfully',
      document: json['document'] != null
          ? VerificationDocument.fromJson(json['document'])
          : null,
    );
  }
}
