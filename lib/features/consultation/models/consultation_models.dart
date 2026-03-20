class ConsultationEligibility {
  final bool canApply;
  final bool isConsultant;
  final String status;
  final String? message;
  final Map<String, dynamic>? application;
  final int? profileId;
  final String? consultantType;
  final bool? isAvailable;

  ConsultationEligibility({
    required this.canApply,
    required this.isConsultant,
    required this.status,
    this.message,
    this.application,
    this.profileId,
    this.consultantType,
    this.isAvailable,
  });

  factory ConsultationEligibility.fromJson(Map<String, dynamic> json) {
    return ConsultationEligibility(
      canApply: json['can_apply'] ?? false,
      isConsultant: json['is_consultant'] ?? false,
      status: json['status'] ?? 'unknown',
      message: json['message'],
      application: json['application'],
      profileId: json['profile_id'],
      consultantType: json['consultant_type'],
      isAvailable: json['is_available'],
    );
  }
}

class ConsultationApplicationResult {
  final bool success;
  final String message;
  final List<String>? nextSteps;
  final Map<String, dynamic>? registration;

  ConsultationApplicationResult({
    required this.success,
    required this.message,
    this.nextSteps,
    this.registration,
  });
}
