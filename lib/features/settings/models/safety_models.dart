class BlockedUser {
  final int id;
  final int blockedUserId;
  final String blockedEmail;
  final String blockedName;
  final String? blockedProfilePicture;
  final String reason;
  final DateTime createdAt;

  BlockedUser({
    required this.id,
    required this.blockedUserId,
    required this.blockedEmail,
    required this.blockedName,
    this.blockedProfilePicture,
    required this.reason,
    required this.createdAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: json['id'] ?? 0,
      blockedUserId: json['blocked'] ?? 0,
      blockedEmail: json['blocked_email'] ?? '',
      blockedName: json['blocked_name'] ?? '',
      blockedProfilePicture: json['blocked_profile_picture'],
      reason: json['reason'] ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

enum ReportType {
  harassment,
  spam,
  inappropriate,
  impersonation,
  fakeProfile,
  other,
}

extension ReportTypeX on ReportType {
  String get apiValue {
    switch (this) {
      case ReportType.harassment:
        return 'harassment';
      case ReportType.spam:
        return 'spam';
      case ReportType.inappropriate:
        return 'inappropriate';
      case ReportType.impersonation:
        return 'impersonation';
      case ReportType.fakeProfile:
        return 'fake_profile';
      case ReportType.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case ReportType.harassment:
        return 'Harassment';
      case ReportType.spam:
        return 'Spam';
      case ReportType.inappropriate:
        return 'Inappropriate Content';
      case ReportType.impersonation:
        return 'Impersonation';
      case ReportType.fakeProfile:
        return 'Fake Profile';
      case ReportType.other:
        return 'Other';
    }
  }
}

class UserReport {
  final int id;
  final String reportType;
  final String description;
  final String status;
  final DateTime createdAt;

  UserReport({
    required this.id,
    required this.reportType,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory UserReport.fromJson(Map<String, dynamic> json) {
    return UserReport(
      id: json['id'] ?? 0,
      reportType: json['report_type'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class DeletionRequest {
  final int id;
  final String deletionType;
  final String status;
  final DateTime? scheduledDeletionDate;
  final DateTime createdAt;

  DeletionRequest({
    required this.id,
    required this.deletionType,
    required this.status,
    this.scheduledDeletionDate,
    required this.createdAt,
  });

  factory DeletionRequest.fromJson(Map<String, dynamic> json) {
    return DeletionRequest(
      id: json['id'] ?? json['request_id'] ?? 0,
      deletionType: json['deletion_type'] ?? 'account',
      status: json['status'] ?? 'pending',
      scheduledDeletionDate: json['scheduled_deletion_date'] != null
          ? DateTime.tryParse(json['scheduled_deletion_date'])
          : null,
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

enum DataCategory {
  profile,
  documents,
  callHistory,
  messages,
  location,
  deviceInfo,
  payment,
  all,
}

extension DataCategoryX on DataCategory {
  String get apiValue {
    switch (this) {
      case DataCategory.profile:
        return 'profile';
      case DataCategory.documents:
        return 'documents';
      case DataCategory.callHistory:
        return 'call_history';
      case DataCategory.messages:
        return 'messages';
      case DataCategory.location:
        return 'location';
      case DataCategory.deviceInfo:
        return 'device_info';
      case DataCategory.payment:
        return 'payment';
      case DataCategory.all:
        return 'all';
    }
  }

  String get label {
    switch (this) {
      case DataCategory.profile:
        return 'Profile Data';
      case DataCategory.documents:
        return 'Documents';
      case DataCategory.callHistory:
        return 'Call History';
      case DataCategory.messages:
        return 'Messages';
      case DataCategory.location:
        return 'Location Data';
      case DataCategory.deviceInfo:
        return 'Device Info';
      case DataCategory.payment:
        return 'Payment History';
      case DataCategory.all:
        return 'All Data';
    }
  }
}
