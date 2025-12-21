class NearbyLawyer {
  final int id;
  final int userId;
  final UserDetails userDetails;
  final String consultantType;
  final String? specialization;
  final int? yearsOfExperience;
  final bool offersMobileConsultations;
  final bool offersPhysicalConsultations;
  final String? city;
  final bool isAvailable;
  final int totalConsultations;
  final String totalEarnings;
  final double? averageRating;
  final int totalReviews;
  final PricingInfo pricing;
  final bool isOnline;
  final double distanceKm;
  final LocationInfo location;
  final ProfessionalDetails professionalDetails;
  final FirmInfo? firmInfo;
  final String? createdAt;
  final String? updatedAt;

  NearbyLawyer({
    required this.id,
    required this.userId,
    required this.userDetails,
    required this.consultantType,
    this.specialization,
    this.yearsOfExperience,
    required this.offersMobileConsultations,
    required this.offersPhysicalConsultations,
    this.city,
    required this.isAvailable,
    required this.totalConsultations,
    required this.totalEarnings,
    this.averageRating,
    required this.totalReviews,
    required this.pricing,
    required this.isOnline,
    required this.distanceKm,
    required this.location,
    required this.professionalDetails,
    this.firmInfo,
    this.createdAt,
    this.updatedAt,
  });

  factory NearbyLawyer.fromJson(Map<String, dynamic> json) {
    return NearbyLawyer(
      id: json['id'],
      userId: json['user'],
      userDetails: UserDetails.fromJson(json['user_details']),
      consultantType: json['consultant_type'],
      specialization: json['specialization'],
      yearsOfExperience: json['years_of_experience'],
      offersMobileConsultations: json['offers_mobile_consultations'] ?? false,
      offersPhysicalConsultations:
          json['offers_physical_consultations'] ?? false,
      city: json['city'],
      isAvailable: json['is_available'] ?? false,
      totalConsultations: json['total_consultations'] ?? 0,
      totalEarnings: json['total_earnings'] ?? '0.00',
      averageRating: json['average_rating'] != null
          ? (json['average_rating'] as num).toDouble()
          : null,
      totalReviews: json['total_reviews'] ?? 0,
      pricing: PricingInfo.fromJson(json['pricing']),
      isOnline: json['is_online'] ?? false,
      distanceKm: (json['distance_km'] as num).toDouble(),
      location: LocationInfo.fromJson(json['location']),
      professionalDetails:
          ProfessionalDetails.fromJson(json['professional_details']),
      firmInfo: json['firm_info'] != null
          ? FirmInfo.fromJson(json['firm_info'])
          : null,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  // Convenience getters
  String? get name => userDetails.fullName;
  String? get email => userDetails.email;
  String? get phone => userDetails.phoneNumber;
  String? get profilePicture => userDetails.profilePicture;

  String getUserTypeLabel() {
    switch (consultantType) {
      case 'advocate':
        return 'Advocate';
      case 'lawyer':
        return 'Lawyer';
      case 'paralegal':
        return 'Paralegal';
      case 'law_firm':
        return 'Law Firm';
      default:
        return consultantType;
    }
  }

  String getUserTypeIcon() {
    switch (consultantType) {
      case 'advocate':
        return '⚖️';
      case 'lawyer':
        return '👨‍💼';
      case 'paralegal':
        return '📋';
      case 'law_firm':
        return '🏢';
      default:
        return '👤';
    }
  }
}

class UserDetails {
  final int id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? phoneNumber;
  final String? profilePicture;

  UserDetails({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.fullName,
    this.phoneNumber,
    this.profilePicture,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      profilePicture: json['profile_picture'],
    );
  }
}

class PricingInfo {
  final MobilePricing mobile;

  PricingInfo({required this.mobile});

  factory PricingInfo.fromJson(Map<String, dynamic> json) {
    return PricingInfo(
      mobile: MobilePricing.fromJson(json['mobile']),
    );
  }
}

class MobilePricing {
  final double price;
  final double consultantShare;
  final double platformShare;

  MobilePricing({
    required this.price,
    required this.consultantShare,
    required this.platformShare,
  });

  factory MobilePricing.fromJson(Map<String, dynamic> json) {
    return MobilePricing(
      price: (json['price'] as num).toDouble(),
      consultantShare: (json['consultant_share'] as num).toDouble(),
      platformShare: (json['platform_share'] as num).toDouble(),
    );
  }
}

class LocationInfo {
  final double latitude;
  final double longitude;
  final String? officeAddress;
  final String? ward;
  final String? district;
  final String? region;

  LocationInfo({
    required this.latitude,
    required this.longitude,
    this.officeAddress,
    this.ward,
    this.district,
    this.region,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      officeAddress: json['office_address'],
      ward: json['ward'],
      district: json['district'],
      region: json['region'],
    );
  }

  String getFullAddress() {
    final parts = <String>[];
    if (officeAddress != null) parts.add(officeAddress!);
    if (ward != null) parts.add(ward!);
    if (district != null) parts.add(district!);
    if (region != null) parts.add(region!);
    return parts.join(', ');
  }
}

class ProfessionalDetails {
  final String? practiceStatus;
  final String? barMembershipNumber;
  final String? rollNumber;
  final String? regionalChapter;
  final String? placeOfWork;

  ProfessionalDetails({
    this.practiceStatus,
    this.barMembershipNumber,
    this.rollNumber,
    this.regionalChapter,
    this.placeOfWork,
  });

  factory ProfessionalDetails.fromJson(Map<String, dynamic> json) {
    return ProfessionalDetails(
      practiceStatus: json['practice_status'],
      barMembershipNumber: json['bar_membership_number'],
      rollNumber: json['roll_number'],
      regionalChapter: json['regional_chapter'],
      placeOfWork: json['place_of_work'],
    );
  }
}

class FirmInfo {
  final String? firmName;
  final String? managingPartner;
  final int? numberOfLawyers;
  final int? yearEstablished;

  FirmInfo({
    this.firmName,
    this.managingPartner,
    this.numberOfLawyers,
    this.yearEstablished,
  });

  factory FirmInfo.fromJson(Map<String, dynamic> json) {
    return FirmInfo(
      firmName: json['firm_name'],
      managingPartner: json['managing_partner'],
      numberOfLawyers: json['number_of_lawyers'],
      yearEstablished: json['year_established'],
    );
  }
}

class NearbyLawyersResponse {
  final int count;
  final double radiusKm;
  final UserLocation yourLocation;
  final List<NearbyLawyer> results;

  NearbyLawyersResponse({
    required this.count,
    required this.radiusKm,
    required this.yourLocation,
    required this.results,
  });

  factory NearbyLawyersResponse.fromJson(Map<String, dynamic> json) {
    return NearbyLawyersResponse(
      count: json['count'],
      radiusKm: (json['radius_km'] as num).toDouble(),
      yourLocation: UserLocation.fromJson(json['your_location']),
      results: (json['results'] as List)
          .map((l) => NearbyLawyer.fromJson(l))
          .toList(),
    );
  }
}

class UserLocation {
  final double latitude;
  final double longitude;

  UserLocation({
    required this.latitude,
    required this.longitude,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}
