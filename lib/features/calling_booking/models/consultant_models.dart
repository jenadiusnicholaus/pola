class Consultant {
  final int id;
  final UserDetails userDetails;
  final String consultantType; // 'advocate', 'lawyer', 'paralegal'
  final String specialization;
  final int yearsOfExperience;
  final bool offersMobileConsultations;
  final bool offersPhysicalConsultations;
  final String? city;
  final bool isAvailable;
  final int totalConsultations;
  final String totalEarnings;
  final double averageRating;
  final int totalReviews;
  final ConsultantPricing pricing;

  Consultant({
    required this.id,
    required this.userDetails,
    required this.consultantType,
    required this.specialization,
    required this.yearsOfExperience,
    required this.offersMobileConsultations,
    required this.offersPhysicalConsultations,
    this.city,
    required this.isAvailable,
    required this.totalConsultations,
    required this.totalEarnings,
    required this.averageRating,
    required this.totalReviews,
    required this.pricing,
  });

  factory Consultant.fromJson(Map<String, dynamic> json) {
    return Consultant(
      id: json['id'] ?? 0,
      userDetails: UserDetails.fromJson(json['user_details'] ?? {}),
      consultantType: json['consultant_type'] ?? '',
      specialization: json['specialization'] ?? '',
      yearsOfExperience: json['years_of_experience'] ?? 0,
      offersMobileConsultations: json['offers_mobile_consultations'] ?? false,
      offersPhysicalConsultations:
          json['offers_physical_consultations'] ?? false,
      city: json['city'],
      isAvailable: json['is_available'] ?? true,
      totalConsultations: json['total_consultations'] ?? 0,
      totalEarnings: json['total_earnings']?.toString() ?? '0',
      averageRating:
          double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0.0,
      totalReviews: json['total_reviews'] ?? 0,
      pricing: ConsultantPricing.fromJson(json['pricing'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_details': userDetails.toJson(),
      'consultant_type': consultantType,
      'specialization': specialization,
      'years_of_experience': yearsOfExperience,
      'offers_mobile_consultations': offersMobileConsultations,
      'offers_physical_consultations': offersPhysicalConsultations,
      'city': city,
      'is_available': isAvailable,
      'total_consultations': totalConsultations,
      'total_earnings': totalEarnings,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'pricing': pricing.toJson(),
    };
  }
}

class UserDetails {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? phoneNumber;

  UserDetails({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.phoneNumber,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'phone_number': phoneNumber,
    };
  }
}

class ConsultantPricing {
  final PricingDetails? mobile;
  final PricingDetails? physical;

  ConsultantPricing({
    this.mobile,
    this.physical,
  });

  factory ConsultantPricing.fromJson(Map<String, dynamic> json) {
    return ConsultantPricing(
      mobile: json['mobile'] != null
          ? PricingDetails.fromJson(json['mobile'])
          : null,
      physical: json['physical'] != null
          ? PricingDetails.fromJson(json['physical'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mobile': mobile?.toJson(),
      'physical': physical?.toJson(),
    };
  }
}

class PricingDetails {
  final String price;
  final String consultantShare;
  final String platformShare;

  PricingDetails({
    required this.price,
    required this.consultantShare,
    required this.platformShare,
  });

  factory PricingDetails.fromJson(Map<String, dynamic> json) {
    return PricingDetails(
      price: json['price']?.toString() ?? '0',
      consultantShare: json['consultant_share']?.toString() ?? '0',
      platformShare: json['platform_share']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'consultant_share': consultantShare,
      'platform_share': platformShare,
    };
  }
}

class CallCredit {
  final int id;
  final int remainingMinutes;
  final DateTime expiresAt;
  final String bundleName;

  CallCredit({
    required this.id,
    required this.remainingMinutes,
    required this.expiresAt,
    required this.bundleName,
  });

  factory CallCredit.fromJson(Map<String, dynamic> json) {
    return CallCredit(
      id: json['id'] ?? 0,
      remainingMinutes: json['remaining_minutes'] ?? 0,
      expiresAt: DateTime.parse(json['expires_at']),
      bundleName: json['bundle_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'remaining_minutes': remainingMinutes,
      'expires_at': expiresAt.toIso8601String(),
      'bundle_name': bundleName,
    };
  }
}

class CreditBundle {
  final int id;
  final String name;
  final String nameSw;
  final int minutes;
  final double price;
  final String priceFormatted;
  final int validityDays;
  final String description;

  CreditBundle({
    required this.id,
    required this.name,
    required this.nameSw,
    required this.minutes,
    required this.price,
    required this.priceFormatted,
    required this.validityDays,
    required this.description,
  });

  factory CreditBundle.fromJson(Map<String, dynamic> json) {
    return CreditBundle(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      nameSw: json['name_sw'] ?? '',
      minutes: json['minutes'] ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      priceFormatted: json['price_formatted'] ?? '',
      validityDays: json['validity_days'] ?? 0,
      description: json['description'] ?? '',
    );
  }
}

class CreditCheckResponse {
  final bool hasCredits;
  final int availableMinutes;
  final int activeCreditsCount;
  final Consultant? consultant;
  final List<CallCredit> creditsBreakdown;
  final List<CreditBundle> availableBundles;
  final String message;

  CreditCheckResponse({
    required this.hasCredits,
    required this.availableMinutes,
    required this.activeCreditsCount,
    this.consultant,
    required this.creditsBreakdown,
    required this.availableBundles,
    required this.message,
  });

  factory CreditCheckResponse.fromJson(Map<String, dynamic> json) {
    return CreditCheckResponse(
      hasCredits: json['has_credits'] ?? false,
      availableMinutes: json['available_minutes'] ?? 0,
      activeCreditsCount: json['active_credits_count'] ?? 0,
      consultant: json['consultant'] != null
          ? Consultant.fromJson(json['consultant'])
          : null,
      creditsBreakdown: (json['credits_breakdown'] as List?)
              ?.map((item) => CallCredit.fromJson(item))
              .toList() ??
          [],
      availableBundles: (json['available_bundles'] as List?)
              ?.map((item) => CreditBundle.fromJson(item))
              .toList() ??
          [],
      message: json['message'] ?? '',
    );
  }
}

class CallSession {
  final int id;
  final String callerName;
  final String consultantName;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final int creditsDeducted;
  final int creditsRemaining;
  final String status; // 'completed', 'failed'

  CallSession({
    required this.id,
    required this.callerName,
    required this.consultantName,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    required this.creditsDeducted,
    required this.creditsRemaining,
    required this.status,
  });

  String get durationDisplay {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  factory CallSession.fromJson(Map<String, dynamic> json) {
    return CallSession(
      id: json['id'] ?? 0,
      callerName: json['caller_name'] ?? '',
      consultantName: json['consultant_name'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime:
          json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      durationSeconds: json['duration_seconds'] ?? 0,
      creditsDeducted: json['credits_deducted'] ?? 0,
      creditsRemaining: json['credits_remaining'] ?? 0,
      status: json['status'] ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caller_name': callerName,
      'consultant_name': consultantName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'credits_deducted': creditsDeducted,
      'credits_remaining': creditsRemaining,
      'status': status,
    };
  }
}

class RecordCallResponse {
  final bool success;
  final String message;
  final int callId;
  final int durationSeconds;
  final int durationMinutes;
  final int creditsDeducted;
  final int creditsRemaining;

  RecordCallResponse({
    required this.success,
    required this.message,
    required this.callId,
    required this.durationSeconds,
    required this.durationMinutes,
    required this.creditsDeducted,
    required this.creditsRemaining,
  });

  factory RecordCallResponse.fromJson(Map<String, dynamic> json) {
    return RecordCallResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      callId: json['call_id'] ?? 0,
      durationSeconds: json['duration_seconds'] ?? 0,
      durationMinutes: json['duration_minutes'] ?? 0,
      creditsDeducted: json['credits_deducted'] ?? 0,
      creditsRemaining: json['credits_remaining'] ?? 0,
    );
  }
}
