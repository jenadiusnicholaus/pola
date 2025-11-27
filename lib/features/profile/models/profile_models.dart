// Base user profile model that all role-specific profiles extend
class UserProfile {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final UserRole userRole;
  final String gender;
  final bool isActive;
  final bool isVerified;
  final ContactInfo contact;
  final AddressInfo address;
  final VerificationStatus verificationStatus;
  final List<String> permissions;
  final SubscriptionInfo subscription;
  final String dateJoined;
  final String? lastLogin;
  final String? idNumber;
  final String? profilePicture;

  UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.userRole,
    required this.gender,
    required this.isActive,
    required this.isVerified,
    required this.contact,
    required this.address,
    required this.verificationStatus,
    required this.permissions,
    required this.subscription,
    required this.dateJoined,
    this.lastLogin,
    this.idNumber,
    this.profilePicture,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      dateOfBirth: json['date_of_birth'] ?? '',
      userRole: UserRole.fromJson(json['user_role'] ?? {}),
      gender: json['gender'] ?? '',
      isActive: json['is_active'] ?? false,
      isVerified: json['is_verified'] ?? false,
      contact: ContactInfo.fromJson(json['contact'] ?? {}),
      address: AddressInfo.fromJson(json['address'] ?? {}),
      verificationStatus:
          VerificationStatus.fromJson(json['verification_status'] ?? {}),
      permissions: List<String>.from(json['permissions'] ?? []),
      subscription: SubscriptionInfo.fromJson(json['subscription'] ?? {}),
      dateJoined: json['date_joined'] ?? '',
      lastLogin: json['last_login'],
      idNumber: json['id_number'],
      profilePicture: json['profile_picture_url'] ?? json['profile_picture'],
    );
  }

  String get fullName {
    // For law firms and other roles without names, use email or role
    if (firstName.trim().isEmpty && lastName.trim().isEmpty) {
      return email.split('@').first; // Use email username part
    }
    return '$firstName $lastName'.trim();
  }

  String get displayRole => userRole.getRoleDisplay;
}

// User role information
class UserRole {
  final int id;
  final String roleName;
  final String getRoleDisplay;
  final String? description;

  UserRole({
    required this.id,
    required this.roleName,
    required this.getRoleDisplay,
    this.description,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['id'] ?? 0,
      roleName: json['role_name'] ?? '',
      getRoleDisplay: json['get_role_display'] ?? '',
      description: json['description'],
    );
  }
}

// Contact information
class ContactInfo {
  final String phoneNumber;
  final bool phoneIsVerified;
  final String? website;

  ContactInfo({
    required this.phoneNumber,
    required this.phoneIsVerified,
    this.website,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      phoneNumber: json['phone_number'] ?? '',
      phoneIsVerified: json['phone_is_verified'] ?? false,
      website: json['website'],
    );
  }
}

// Address information
class AddressInfo {
  final int? region;
  final String? regionName;
  final int? district;
  final String? districtName;
  final String? ward;
  final String? officeAddress;

  AddressInfo({
    this.region,
    this.regionName,
    this.district,
    this.districtName,
    this.ward,
    this.officeAddress,
  });

  factory AddressInfo.fromJson(Map<String, dynamic> json) {
    return AddressInfo(
      region: json['region'],
      regionName: json['region_name'],
      district: json['district'],
      districtName: json['district_name'],
      ward: json['ward'],
      officeAddress: json['office_address'],
    );
  }
}

// Verification status
class VerificationStatus {
  final String status;
  final String currentStep;
  final double progress;
  final String? notes;
  final String? verificationDate;

  VerificationStatus({
    required this.status,
    required this.currentStep,
    required this.progress,
    this.notes,
    this.verificationDate,
  });

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    return VerificationStatus(
      status: json['status'] ?? '',
      currentStep: json['current_step'] ?? '',
      progress: (json['progress'] ?? 0.0).toDouble(),
      notes: json['notes'],
      verificationDate: json['verification_date'],
    );
  }
}

// Subscription information
class SubscriptionInfo {
  final int id;
  final String planName;
  final String planNameSw;
  final String planType;
  final String status;
  final bool isActive;
  final bool isTrial;
  final String startDate;
  final String endDate;
  final int daysRemaining;
  final bool autoRenew;
  final SubscriptionPermissions permissions;

  SubscriptionInfo({
    required this.id,
    required this.planName,
    required this.planNameSw,
    required this.planType,
    required this.status,
    required this.isActive,
    required this.isTrial,
    required this.startDate,
    required this.endDate,
    required this.daysRemaining,
    required this.autoRenew,
    required this.permissions,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      id: json['id'] ?? 0,
      planName: json['plan_name'] ?? '',
      planNameSw: json['plan_name_sw'] ?? '',
      planType: json['plan_type'] ?? '',
      status: json['status'] ?? '',
      isActive: json['is_active'] ?? false,
      isTrial: json['is_trial'] ?? false,
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      daysRemaining: json['days_remaining'] ?? 0,
      autoRenew: json['auto_renew'] ?? false,
      permissions: SubscriptionPermissions.fromJson(json['permissions'] ?? {}),
    );
  }
}

// Subscription permissions
class SubscriptionPermissions {
  final bool isActive;
  final bool canAccessLegalLibrary;
  final bool canAskQuestions;
  final int questionsLimit;
  final int questionsRemaining;
  final bool canGenerateDocuments;
  final int freeDocumentsLimit;
  final int documentsRemaining;
  final bool canReceiveLegalUpdates;
  final bool canAccessForum;
  final bool canAccessStudentHub;
  final bool canPurchaseConsultations;
  final bool canPurchaseDocuments;
  final bool canPurchaseLearningMaterials;

  SubscriptionPermissions({
    required this.isActive,
    required this.canAccessLegalLibrary,
    required this.canAskQuestions,
    required this.questionsLimit,
    required this.questionsRemaining,
    required this.canGenerateDocuments,
    required this.freeDocumentsLimit,
    required this.documentsRemaining,
    required this.canReceiveLegalUpdates,
    required this.canAccessForum,
    required this.canAccessStudentHub,
    required this.canPurchaseConsultations,
    required this.canPurchaseDocuments,
    required this.canPurchaseLearningMaterials,
  });

  factory SubscriptionPermissions.fromJson(Map<String, dynamic> json) {
    return SubscriptionPermissions(
      isActive: json['is_active'] ?? false,
      canAccessLegalLibrary: json['can_access_legal_library'] ?? false,
      canAskQuestions: json['can_ask_questions'] ?? false,
      questionsLimit: json['questions_limit'] ?? 0,
      questionsRemaining: json['questions_remaining'] ?? 0,
      canGenerateDocuments: json['can_generate_documents'] ?? false,
      freeDocumentsLimit: json['free_documents_limit'] ?? 0,
      documentsRemaining: json['documents_remaining'] ?? 0,
      canReceiveLegalUpdates: json['can_receive_legal_updates'] ?? false,
      canAccessForum: json['can_access_forum'] ?? false,
      canAccessStudentHub: json['can_access_student_hub'] ?? false,
      canPurchaseConsultations: json['can_purchase_consultations'] ?? false,
      canPurchaseDocuments: json['can_purchase_documents'] ?? false,
      canPurchaseLearningMaterials:
          json['can_purchase_learning_materials'] ?? false,
    );
  }
}

// Professional-related models
class Specialization {
  final int id;
  final String nameEn;
  final String nameSw;
  final String? description;

  Specialization({
    required this.id,
    required this.nameEn,
    required this.nameSw,
    this.description,
  });

  factory Specialization.fromJson(Map<String, dynamic> json) {
    return Specialization(
      id: json['id'] ?? 0,
      nameEn: json['name_en'] ?? '',
      nameSw: json['name_sw'] ?? '',
      description: json['description'],
    );
  }
}

class PlaceOfWork {
  final int id;
  final String code;
  final String nameEn;
  final String nameSw;

  PlaceOfWork({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameSw,
  });

  factory PlaceOfWork.fromJson(Map<String, dynamic> json) {
    return PlaceOfWork(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      nameEn: json['name_en'] ?? '',
      nameSw: json['name_sw'] ?? '',
    );
  }
}

class RegionalChapter {
  final int id;
  final String name;
  final String code;

  RegionalChapter({
    required this.id,
    required this.name,
    required this.code,
  });

  factory RegionalChapter.fromJson(Map<String, dynamic> json) {
    return RegionalChapter(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }
}

class OperatingRegion {
  final int id;
  final String name;

  OperatingRegion({
    required this.id,
    required this.name,
  });

  factory OperatingRegion.fromJson(Map<String, dynamic> json) {
    return OperatingRegion(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class AcademicRole {
  final int id;
  final String code;
  final String nameEn;
  final String nameSw;

  AcademicRole({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameSw,
  });

  factory AcademicRole.fromJson(Map<String, dynamic> json) {
    return AcademicRole(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      nameEn: json['name_en'] ?? '',
      nameSw: json['name_sw'] ?? '',
    );
  }
}

// Role-specific profile models
class AdvocateProfile extends UserProfile {
  final String? rollNumber;
  final RegionalChapter? regionalChapter;
  final int? yearOfAdmissionToBar;
  final int? yearsOfExperience;
  final String? practiceStatus;
  final PlaceOfWork? placeOfWork;
  final List<Specialization>? specializations;
  final List<OperatingRegion>? operatingRegions;
  final List<OperatingRegion>? operatingDistricts;

  AdvocateProfile({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.dateOfBirth,
    required super.userRole,
    required super.gender,
    required super.isActive,
    required super.isVerified,
    required super.contact,
    required super.address,
    required super.verificationStatus,
    required super.permissions,
    required super.subscription,
    required super.dateJoined,
    super.lastLogin,
    super.idNumber,
    super.profilePicture,
    this.rollNumber,
    this.regionalChapter,
    this.yearOfAdmissionToBar,
    this.yearsOfExperience,
    this.practiceStatus,
    this.placeOfWork,
    this.specializations,
    this.operatingRegions,
    this.operatingDistricts,
  });

  factory AdvocateProfile.fromJson(Map<String, dynamic> json) {
    return AdvocateProfile(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      dateOfBirth: json['date_of_birth'] ?? '',
      userRole: UserRole.fromJson(json['user_role'] ?? {}),
      gender: json['gender'] ?? '',
      isActive: json['is_active'] ?? false,
      isVerified: json['is_verified'] ?? false,
      contact: ContactInfo.fromJson(json['contact'] ?? {}),
      address: AddressInfo.fromJson(json['address'] ?? {}),
      verificationStatus:
          VerificationStatus.fromJson(json['verification_status'] ?? {}),
      permissions: List<String>.from(json['permissions'] ?? []),
      subscription: SubscriptionInfo.fromJson(json['subscription'] ?? {}),
      dateJoined: json['date_joined'] ?? '',
      lastLogin: json['last_login'],
      idNumber: json['id_number'],
      profilePicture: json['profile_picture_url'] ?? json['profile_picture'],
      rollNumber: json['roll_number'],
      regionalChapter: json['regional_chapter'] != null
          ? RegionalChapter.fromJson(json['regional_chapter'])
          : null,
      yearOfAdmissionToBar: json['year_of_admission_to_bar'],
      yearsOfExperience: json['years_of_experience'],
      practiceStatus: json['practice_status'],
      placeOfWork: json['place_of_work'] != null
          ? PlaceOfWork.fromJson(json['place_of_work'])
          : null,
      specializations: json['specializations'] != null
          ? (json['specializations'] as List)
              .map((s) => Specialization.fromJson(s))
              .toList()
          : null,
      operatingRegions: json['operating_regions'] != null
          ? (json['operating_regions'] as List)
              .map((r) => OperatingRegion.fromJson(r))
              .toList()
          : null,
      operatingDistricts: json['operating_districts'] != null
          ? (json['operating_districts'] as List)
              .map((d) => OperatingRegion.fromJson(d))
              .toList()
          : null,
    );
  }
}

class LawyerProfile extends UserProfile {
  final int? yearsOfExperience;
  final PlaceOfWork? placeOfWork;
  final List<Specialization>? specializations;
  final List<OperatingRegion>? operatingRegions;
  final List<OperatingRegion>? operatingDistricts;

  LawyerProfile({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.dateOfBirth,
    required super.userRole,
    required super.gender,
    required super.isActive,
    required super.isVerified,
    required super.contact,
    required super.address,
    required super.verificationStatus,
    required super.permissions,
    required super.subscription,
    required super.dateJoined,
    super.lastLogin,
    super.idNumber,
    super.profilePicture,
    this.yearsOfExperience,
    this.placeOfWork,
    this.specializations,
    this.operatingRegions,
    this.operatingDistricts,
  });

  factory LawyerProfile.fromJson(Map<String, dynamic> json) {
    return LawyerProfile(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      dateOfBirth: json['date_of_birth'] ?? '',
      userRole: UserRole.fromJson(json['user_role'] ?? {}),
      gender: json['gender'] ?? '',
      isActive: json['is_active'] ?? false,
      isVerified: json['is_verified'] ?? false,
      contact: ContactInfo.fromJson(json['contact'] ?? {}),
      address: AddressInfo.fromJson(json['address'] ?? {}),
      verificationStatus:
          VerificationStatus.fromJson(json['verification_status'] ?? {}),
      permissions: List<String>.from(json['permissions'] ?? []),
      subscription: SubscriptionInfo.fromJson(json['subscription'] ?? {}),
      dateJoined: json['date_joined'] ?? '',
      lastLogin: json['last_login'],
      idNumber: json['id_number'],
      profilePicture: json['profile_picture_url'] ?? json['profile_picture'],
      yearsOfExperience: json['years_of_experience'],
      placeOfWork: json['place_of_work'] != null
          ? PlaceOfWork.fromJson(json['place_of_work'])
          : null,
      specializations: json['specializations'] != null
          ? (json['specializations'] as List)
              .map((s) => Specialization.fromJson(s))
              .toList()
          : null,
      operatingRegions: json['operating_regions'] != null
          ? (json['operating_regions'] as List)
              .map((r) => OperatingRegion.fromJson(r))
              .toList()
          : null,
      operatingDistricts: json['operating_districts'] != null
          ? (json['operating_districts'] as List)
              .map((d) => OperatingRegion.fromJson(d))
              .toList()
          : null,
    );
  }
}

class ParalegalProfile extends UserProfile {
  final int? yearsOfExperience;
  final PlaceOfWork? placeOfWork;
  final List<OperatingRegion>? operatingRegions;
  final List<OperatingRegion>? operatingDistricts;

  ParalegalProfile({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.dateOfBirth,
    required super.userRole,
    required super.gender,
    required super.isActive,
    required super.isVerified,
    required super.contact,
    required super.address,
    required super.verificationStatus,
    required super.permissions,
    required super.subscription,
    required super.dateJoined,
    super.lastLogin,
    super.idNumber,
    super.profilePicture,
    this.yearsOfExperience,
    this.placeOfWork,
    this.operatingRegions,
    this.operatingDistricts,
  });

  factory ParalegalProfile.fromJson(Map<String, dynamic> json) {
    return ParalegalProfile(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      dateOfBirth: json['date_of_birth'] ?? '',
      userRole: UserRole.fromJson(json['user_role'] ?? {}),
      gender: json['gender'] ?? '',
      isActive: json['is_active'] ?? false,
      isVerified: json['is_verified'] ?? false,
      contact: ContactInfo.fromJson(json['contact'] ?? {}),
      address: AddressInfo.fromJson(json['address'] ?? {}),
      verificationStatus:
          VerificationStatus.fromJson(json['verification_status'] ?? {}),
      permissions: List<String>.from(json['permissions'] ?? []),
      subscription: SubscriptionInfo.fromJson(json['subscription'] ?? {}),
      dateJoined: json['date_joined'] ?? '',
      lastLogin: json['last_login'],
      idNumber: json['id_number'],
      profilePicture: json['profile_picture_url'] ?? json['profile_picture'],
      yearsOfExperience: json['years_of_experience'],
      placeOfWork: json['place_of_work'] != null
          ? PlaceOfWork.fromJson(json['place_of_work'])
          : null,
      operatingRegions: json['operating_regions'] != null
          ? (json['operating_regions'] as List)
              .map((r) => OperatingRegion.fromJson(r))
              .toList()
          : null,
      operatingDistricts: json['operating_districts'] != null
          ? (json['operating_districts'] as List)
              .map((d) => OperatingRegion.fromJson(d))
              .toList()
          : null,
    );
  }
}

class LawStudentProfile extends UserProfile {
  final String? universityName;
  final AcademicRole? academicRole;
  final int? yearOfStudy;

  LawStudentProfile({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.dateOfBirth,
    required super.userRole,
    required super.gender,
    required super.isActive,
    required super.isVerified,
    required super.contact,
    required super.address,
    required super.verificationStatus,
    required super.permissions,
    required super.subscription,
    required super.dateJoined,
    super.lastLogin,
    super.idNumber,
    super.profilePicture,
    this.universityName,
    this.academicRole,
    this.yearOfStudy,
  });

  factory LawStudentProfile.fromJson(Map<String, dynamic> json) {
    return LawStudentProfile(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      dateOfBirth: json['date_of_birth'] ?? '',
      userRole: UserRole.fromJson(json['user_role'] ?? {}),
      gender: json['gender'] ?? '',
      isActive: json['is_active'] ?? false,
      isVerified: json['is_verified'] ?? false,
      contact: ContactInfo.fromJson(json['contact'] ?? {}),
      address: AddressInfo.fromJson(json['address'] ?? {}),
      verificationStatus:
          VerificationStatus.fromJson(json['verification_status'] ?? {}),
      permissions: List<String>.from(json['permissions'] ?? []),
      subscription: SubscriptionInfo.fromJson(json['subscription'] ?? {}),
      dateJoined: json['date_joined'] ?? '',
      lastLogin: json['last_login'],
      idNumber: json['id_number'],
      profilePicture: json['profile_picture_url'] ?? json['profile_picture'],
      universityName: json['university_name'],
      academicRole: json['academic_role'] != null
          ? AcademicRole.fromJson(json['academic_role'])
          : null,
      yearOfStudy: json['year_of_study'],
    );
  }
}

class CitizenProfile extends UserProfile {
  CitizenProfile({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.dateOfBirth,
    required super.userRole,
    required super.gender,
    required super.isActive,
    required super.isVerified,
    required super.contact,
    required super.address,
    required super.verificationStatus,
    required super.permissions,
    required super.subscription,
    required super.dateJoined,
    super.lastLogin,
    super.idNumber,
    super.profilePicture,
  });

  factory CitizenProfile.fromJson(Map<String, dynamic> json) {
    return CitizenProfile(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      dateOfBirth: json['date_of_birth'] ?? '',
      userRole: UserRole.fromJson(json['user_role'] ?? {}),
      gender: json['gender'] ?? '',
      isActive: json['is_active'] ?? false,
      isVerified: json['is_verified'] ?? false,
      contact: ContactInfo.fromJson(json['contact'] ?? {}),
      address: AddressInfo.fromJson(json['address'] ?? {}),
      verificationStatus:
          VerificationStatus.fromJson(json['verification_status'] ?? {}),
      permissions: List<String>.from(json['permissions'] ?? []),
      subscription: SubscriptionInfo.fromJson(json['subscription'] ?? {}),
      dateJoined: json['date_joined'] ?? '',
      lastLogin: json['last_login'],
      idNumber: json['id_number'],
      profilePicture: json['profile_picture_url'] ?? json['profile_picture'],
    );
  }
}

// Factory class to create appropriate profile based on role
class ProfileFactory {
  static UserProfile createProfile(Map<String, dynamic> json) {
    final userRole = json['user_role'];
    if (userRole == null) {
      return UserProfile.fromJson(json);
    }

    final roleName = userRole['role_name'] as String?;

    switch (roleName) {
      case 'advocate':
        return AdvocateProfile.fromJson(json);
      case 'lawyer':
        return LawyerProfile.fromJson(json);
      case 'paralegal':
        return ParalegalProfile.fromJson(json);
      case 'law_student':
        return LawStudentProfile.fromJson(json);
      case 'citizen':
        return CitizenProfile.fromJson(json);
      default:
        return UserProfile.fromJson(json);
    }
  }
}
