import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../features/profile/services/profile_service.dart';
import '../features/profile/models/profile_models.dart';

/// Service to manage subscription-based permissions
class PermissionService extends GetxService {
  final ProfileService _profileService = Get.find<ProfileService>();

  @override
  void onInit() {
    super.onInit();
    debugPrint('🔐 PermissionService initialized');
    // Debug subscription on init
    debugSubscriptionStatus();
  }

  /// Debug current subscription status
  void debugSubscriptionStatus() {
    final profile = _profileService.currentProfile;
    if (profile != null) {
      final sub = profile.subscription;
      debugPrint('🔐 Subscription Debug:');
      debugPrint('   Plan: ${sub.planName}');
      debugPrint('   Status: ${sub.status}');
      debugPrint('   isActive: ${sub.isActive}');
      debugPrint('   isTrial: ${sub.isTrial}');
      debugPrint('   Days Remaining: ${sub.daysRemaining}');
      debugPrint('   Permissions isActive: ${sub.permissions.isActive}');
    } else {
      debugPrint('🔐 No profile loaded yet');
    }
  }

  /// Get current subscription permissions
  SubscriptionPermissions? get permissions =>
      _profileService.currentProfile?.subscription.permissions;

  /// Get subscription info
  SubscriptionInfo? get subscription =>
      _profileService.currentProfile?.subscription;

  /// Get current user profile
  UserProfile? get currentProfile => _profileService.currentProfile;

  /// Get current user role name
  String? get userRoleName => currentProfile?.userRole.roleName;

  /// Get global user permissions (CRUD permissions)
  List<String> get globalPermissions => currentProfile?.permissions ?? [];

  /// Check if user has a specific global permission (string)
  bool hasGlobalPermission(String permission) {
    return globalPermissions.contains(permission);
  }

  /// Check if user has a specific global permission (enum)
  bool hasPermission(GlobalPermission permission) {
    return hasGlobalPermission(permission.value);
  }

  /// Check if user is a professional (advocate, lawyer, paralegal, law_firm)
  bool get isProfessional {
    // Use backend permission if available
    try {
      if (permissions != null) {
        return permissions!.isProfessional;
      }
    } catch (e) {
      debugPrint('⚠️ Error checking isProfessional from permissions: $e');
    }
    // Fallback to role check
    final role = userRoleName?.toLowerCase();
    if (role == null) return false;
    return role == 'advocate' ||
        role == 'lawyer' ||
        role == 'paralegal' ||
        role == 'law_firm';
  }

  /// Check if user is a law firm
  bool get isLawFirm {
    final role = userRoleName?.toLowerCase();
    return role == 'law_firm';
  }

  /// Check if user is a client (citizen, law_student, lecturer)
  bool get isClient {
    return !isProfessional;
  }

  // ============ Global CRUD Permissions ============

  /// Check if user can edit own profile
  bool get canEditOwnProfile => hasGlobalPermission('edit_own_profile');

  /// Check if user can view own profile
  bool get canViewOwnProfile => hasGlobalPermission('view_own_profile');

  /// Check if user can upload documents
  bool get canUploadDocuments => hasGlobalPermission('upload_documents');

  /// Check if user can view own documents
  bool get canViewOwnDocuments => hasGlobalPermission('view_own_documents');

  /// Check if user can delete own documents
  bool get canDeleteOwnDocuments => hasGlobalPermission('delete_own_documents');

  /// Check if user can add address
  bool get canAddAddress => hasGlobalPermission('add_address');

  /// Check if user can change address
  bool get canChangeAddress => hasGlobalPermission('change_address');

  /// Check if user can delete address
  bool get canDeleteAddress => hasGlobalPermission('delete_address');

  /// Check if user can add contact
  bool get canAddContact => hasGlobalPermission('add_contact');

  /// Check if user can change contact
  bool get canChangeContact => hasGlobalPermission('change_contact');

  /// Check if user can delete contact
  bool get canDeleteContact => hasGlobalPermission('delete_contact');

  /// Check if user can search professionals
  bool get canSearchProfessionals =>
      hasGlobalPermission('search_professionals');

  /// Check if user can view professional profiles
  bool get canViewProfessionalProfiles =>
      hasGlobalPermission('view_professional_profiles');

  /// Check if user can update practice info
  bool get canUpdatePracticeInfo => hasGlobalPermission('update_practice_info');

  /// Check if user can view verification
  bool get canViewVerification => hasGlobalPermission('view_verification');

  /// Check if user can add verification
  bool get canAddVerification => hasGlobalPermission('add_verification');

  // ============ Legal Library Permissions ============

  /// Check if user can access legal library
  bool get canAccessLegalLibrary => permissions?.canAccessLegalLibrary ?? false;

  // ============ Question Permissions ============

  /// Check if user can ask questions
  bool get canAskQuestions => permissions?.canAskQuestions ?? false;

  /// Get remaining questions quota
  int get questionsRemaining => permissions?.questionsRemaining ?? 0;

  /// Get total questions limit
  int get questionsLimit => permissions?.questionsLimit ?? 0;

  /// Check if user has questions remaining
  bool get hasQuestionsRemaining => questionsRemaining > 0;

  /// Check if user can ask a question (has permission AND quota)
  bool get canAskQuestion => canAskQuestions && hasQuestionsRemaining;

  // ============ Document Generation Permissions ============

  /// Check if user can generate documents
  bool get canGenerateDocuments => permissions?.canGenerateDocuments ?? false;

  /// Get remaining free documents quota
  int get documentsRemaining => permissions?.documentsRemaining ?? 0;

  /// Get total free documents limit
  int get freeDocumentsLimit => permissions?.freeDocumentsLimit ?? 0;

  /// Check if user has free documents remaining
  bool get hasDocumentsRemaining => documentsRemaining > 0;

  /// Check if user can generate a document (has permission AND quota)
  bool get canGenerateDocument => canGenerateDocuments && hasDocumentsRemaining;

  // ============ Communication Permissions ============

  /// Check if user can receive legal updates
  bool get canReceiveLegalUpdates =>
      permissions?.canReceiveLegalUpdates ?? false;

  // ============ Forum Permissions ============

  /// Check if user can access forum
  bool get canAccessForum => permissions?.canAccessForum ?? false;

  /// Check if user can comment on forum posts
  bool get canCommentForum => permissions?.canCommentForum ?? false;

  /// Check if user can reply to forum posts
  bool get canReplyForum => permissions?.canReplyForum ?? false;

  /// Check if user can access student hub
  bool get canAccessStudentHub {
    // Use backend permission directly
    return permissions?.canAccessStudentHub ?? false;
  }

  // ============ Legal Education Permissions ============

  /// Get legal education read limit
  int get legalEducationLimit => permissions?.legalEducationLimit ?? 0;

  /// Get current legal education reads count
  int get legalEducationReads => permissions?.legalEducationReads ?? 0;

  /// Get remaining legal education reads
  double get legalEducationRemaining =>
      permissions?.legalEducationRemaining ?? 0;

  /// Check if user has legal education reads remaining
  bool get hasLegalEducationRemaining => legalEducationRemaining > 0;

  /// Check if user can read legal education content
  bool get canReadLegalEducation {
    // If limit is 0, unlimited access (premium)
    if (legalEducationLimit == 0 && isSubscriptionActive && !isTrialSubscription) {
      return true;
    }
    // Otherwise check remaining reads
    return hasLegalEducationRemaining;
  }

  // ============ Template & Consultation Permissions ============

  /// Check if user can download templates
  bool get canDownloadTemplates => permissions?.canDownloadTemplates ?? false;

  /// Check if user can talk to lawyer (action permission)
  bool get canTalkToLawyerAction => permissions?.canTalkToLawyer ?? false;

  /// Check if user can ask question (action permission)
  bool get canAskQuestionAction => permissions?.canAskQuestion ?? false;

  /// Check if user can book consultation
  bool get canBookConsultation => permissions?.canBookConsultation ?? false;

  /// Check if user can view own consultations
  bool get canViewOwnConsultations =>
      permissions?.canViewOwnConsultations ?? false;

  // ============ Role-Specific Permissions ============

  /// Check if user can view "Talk to Lawyer" page
  /// Uses backend permission directly
  bool get canViewTalkToLawyer {
    try {
      // Professionals cannot view (they are the service providers)
      if (isProfessional) return false;

      // Use backend permission
      return permissions?.canViewTalkToLawyer ?? false;
    } catch (e) {
      debugPrint('⚠️ Error checking canViewTalkToLawyer: $e');
      return false;
    }
  }

  /// Check if user can view "Nearby Lawyers" service in the menu
  /// Uses backend permission directly
  bool get canViewNearbyLawyers {
    try {
      // Professionals cannot view (they are the service providers)
      if (isProfessional) return false;

      // Use backend permission
      return permissions?.canViewNearbyLawyers ?? false;
    } catch (e) {
      debugPrint('⚠️ Error checking canViewNearbyLawyers: $e');
      return false;
    }
  }

  /// Check if user can actually ACCESS nearby lawyers feature (requires subscription)
  bool get canAccessNearbyLawyers {
    if (isProfessional) return false;
    return permissions?.canViewNearbyLawyers ?? false;
  }

  // ============ Purchase Permissions ============

  /// Check if user can purchase consultations
  bool get canPurchaseConsultations =>
      permissions?.canPurchaseConsultations ?? false;

  /// Check if user can purchase documents
  bool get canPurchaseDocuments => permissions?.canPurchaseDocuments ?? false;

  /// Check if user can purchase learning materials
  bool get canPurchaseLearningMaterials =>
      permissions?.canPurchaseLearningMaterials ?? false;

  // ============ Subscription Status ============

  /// Check if subscription is active
  bool get isSubscriptionActive {
    final sub = subscription;
    if (sub == null) {
      if (kDebugMode) debugPrint('🔐 No subscription found');
      return false;
    }

    // Primary check: subscription.isActive from backend
    final subscriptionActive = sub.isActive;
    
    // Secondary check: status field
    final statusActive = sub.status.toLowerCase() == 'active' || 
                         sub.status.toLowerCase() == 'completed';
    
    // Consider active if either isActive flag is true OR status is active
    final result = subscriptionActive || statusActive;

    if (kDebugMode) {
      debugPrint('🔐 Subscription check:');
      debugPrint('   Plan: ${sub.planName}');
      debugPrint('   Status: ${sub.status}');
      debugPrint('   isActive flag: $subscriptionActive');
      debugPrint('   Status active: $statusActive');
      debugPrint('   Days Remaining: ${sub.daysRemaining}');
      debugPrint('   Result: ${result ? "✅ ACTIVE" : "❌ INACTIVE"}');
    }

    return result;
  }

  /// Check if subscription is trial
  bool get isTrialSubscription =>
      subscription?.isTrial ?? permissions?.isTrial ?? false;

  /// Get days remaining in subscription
  int get daysRemaining =>
      permissions?.daysRemaining ?? subscription?.daysRemaining ?? 0;

  /// Check if subscription is expiring soon (less than 7 days)
  bool get isExpiringSoon => daysRemaining > 0 && daysRemaining <= 7;

  /// Get subscription status
  String get subscriptionStatus => subscription?.status ?? 'inactive';

  /// Get plan name
  String get planName => subscription?.planName ?? 'Free';

  /// Get plan name in Swahili
  String get planNameSw => subscription?.planNameSw ?? 'Bure';

  /// Get plan type
  String get planType => subscription?.planType ?? 'free';

  // ============ Permission Check Methods ============

  /// Check any permission by feature name
  bool canAccess(PermissionFeature feature) {
    switch (feature) {
      case PermissionFeature.legalLibrary:
        return canAccessLegalLibrary;
      case PermissionFeature.askQuestions:
        return canAskQuestion;
      case PermissionFeature.generateDocuments:
        return canGenerateDocument;
      case PermissionFeature.legalUpdates:
        return canReceiveLegalUpdates;
      case PermissionFeature.forum:
        return canAccessForum;
      case PermissionFeature.forumComment:
        return canCommentForum;
      case PermissionFeature.forumReply:
        return canReplyForum;
      case PermissionFeature.studentHub:
        return canAccessStudentHub;
      case PermissionFeature.purchaseConsultations:
        return canPurchaseConsultations;
      case PermissionFeature.purchaseDocuments:
        return canPurchaseDocuments;
      case PermissionFeature.purchaseLearningMaterials:
        return canPurchaseLearningMaterials;
      case PermissionFeature.talkToLawyer:
        return canViewTalkToLawyer && canTalkToLawyerAction;
      case PermissionFeature.nearbyLawyers:
        return canViewNearbyLawyers;
      case PermissionFeature.downloadTemplates:
        return canDownloadTemplates;
      case PermissionFeature.bookConsultation:
        return canBookConsultation;
      case PermissionFeature.legalEducation:
        return canReadLegalEducation;
    }
  }

  /// Get user-friendly message for permission denial
  String getPermissionDeniedMessage(PermissionFeature feature) {
    if (!isSubscriptionActive) {
      return 'You need an active subscription to access this feature. Please subscribe to continue.';
    }

    if (isTrialSubscription) {
      // Trial-specific messages
      switch (feature) {
        case PermissionFeature.talkToLawyer:
          return 'Talk to Lawyer is not available during your free trial. Upgrade to a paid plan to connect with legal professionals.';
        case PermissionFeature.bookConsultation:
          return 'Booking consultations is not available during your free trial. Upgrade to schedule appointments with lawyers.';
        case PermissionFeature.downloadTemplates:
          return 'Template downloads are not available during your free trial. Upgrade to download legal document templates.';
        case PermissionFeature.legalEducation:
          if (!hasLegalEducationRemaining) {
            return 'You have reached your free trial limit of $legalEducationLimit legal education reads. Upgrade for unlimited access.';
          }
          break;
        case PermissionFeature.forumComment:
        case PermissionFeature.forumReply:
          return 'Commenting on forum posts is limited during your free trial. Upgrade to participate in discussions.';
        default:
          break;
      }
    }

    switch (feature) {
      case PermissionFeature.legalLibrary:
        return 'Your current plan does not include access to the Legal Library. Upgrade your subscription to access thousands of legal resources.';
      case PermissionFeature.askQuestions:
        if (!canAskQuestions) {
          return 'Your current plan does not include asking questions. Upgrade to get expert legal answers.';
        }
        if (!hasQuestionsRemaining) {
          return 'You have used all your questions for this period. Upgrade your plan or wait for renewal.';
        }
        return 'You cannot ask questions at this time.';
      case PermissionFeature.generateDocuments:
        if (!canGenerateDocuments) {
          return 'Your current plan does not include document generation. Upgrade to create legal documents.';
        }
        if (!hasDocumentsRemaining) {
          return 'You have used all your free documents for this period. You can purchase additional documents.';
        }
        return 'You cannot generate documents at this time.';
      case PermissionFeature.legalUpdates:
        return 'Your current plan does not include legal updates. Upgrade to stay informed about legal changes.';
      case PermissionFeature.forum:
        return 'Your current plan does not include forum access. Upgrade to join discussions with legal professionals.';
      case PermissionFeature.forumComment:
        return 'Your current plan does not allow commenting on forum posts. Upgrade to participate in discussions.';
      case PermissionFeature.forumReply:
        return 'Your current plan does not allow replying to forum posts. Upgrade to participate in discussions.';
      case PermissionFeature.studentHub:
        if (isProfessional) {
          return 'Student Hub is not available for legal professionals. This feature is designed for students and lecturers.';
        }
        return 'Your current plan does not include Student Hub access. Upgrade to a paid plan to access student resources.';
      case PermissionFeature.talkToLawyer:
        if (isProfessional) {
          return 'As a legal professional, you are the service provider. This page is for clients seeking legal assistance.';
        }
        return 'Your current plan does not include Talk to Lawyer. Upgrade to connect with legal professionals.';
      case PermissionFeature.nearbyLawyers:
        if (isProfessional) {
          return 'As a legal professional, you are listed in the directory. This feature is for clients seeking lawyers.';
        }
        return 'Your current plan does not include viewing nearby lawyers. Upgrade to find legal professionals in your area.';
      case PermissionFeature.purchaseConsultations:
        return 'Your current plan does not allow purchasing consultations. Upgrade to book consultations with lawyers.';
      case PermissionFeature.purchaseDocuments:
        return 'Your current plan does not allow purchasing documents. Upgrade to access premium legal documents.';
      case PermissionFeature.purchaseLearningMaterials:
        return 'Your current plan does not allow purchasing learning materials. Upgrade to access educational content.';
      case PermissionFeature.downloadTemplates:
        return 'Your current plan does not include template downloads. Upgrade to download legal document templates.';
      case PermissionFeature.bookConsultation:
        return 'Your current plan does not include booking consultations. Upgrade to schedule appointments with lawyers.';
      case PermissionFeature.legalEducation:
        if (!hasLegalEducationRemaining) {
          return 'You have used all your legal education reads for this period. Upgrade for unlimited access.';
        }
        return 'Your current plan does not include legal education content.';
    }
  }

  /// Get upgrade action message
  String getUpgradeMessage(PermissionFeature feature) {
    return 'Upgrade your subscription to unlock this feature and more!';
  }

  /// Check if user should see upgrade prompt
  bool shouldShowUpgradePrompt(PermissionFeature feature) {
    // Always show upgrade if feature is not accessible
    if (!canAccess(feature)) {
      return true;
    }

    // Show prompt if quota-based and running low
    if (feature == PermissionFeature.askQuestions &&
        questionsRemaining > 0 &&
        questionsRemaining <= 2) {
      return true;
    }

    if (feature == PermissionFeature.generateDocuments &&
        documentsRemaining > 0 &&
        documentsRemaining <= 1) {
      return true;
    }

    // Show prompt for legal education if running low (less than 2 remaining)
    if (feature == PermissionFeature.legalEducation &&
        legalEducationLimit > 0 &&
        legalEducationRemaining > 0 &&
        legalEducationRemaining <= 2) {
      return true;
    }

    return false;
  }

  // ============ UI Helper Methods ============

  /// Get quota display text for questions
  String get questionsQuotaText {
    if (!canAskQuestions) return 'Not available';
    return '$questionsRemaining/$questionsLimit remaining';
  }

  /// Get quota display text for documents
  String get documentsQuotaText {
    if (!canGenerateDocuments) return 'Not available';
    return '$documentsRemaining/$freeDocumentsLimit remaining';
  }

  /// Get quota display text for legal education
  String get legalEducationQuotaText {
    // Premium users have unlimited access
    if (legalEducationLimit == 0 && isSubscriptionActive && !isTrialSubscription) {
      return 'Unlimited';
    }
    if (legalEducationLimit == 0) return 'Not available';
    return '${legalEducationRemaining.toInt()}/$legalEducationLimit remaining';
  }

  /// Get subscription status badge text
  String get statusBadgeText {
    if (!isSubscriptionActive) return 'Inactive';
    if (isTrialSubscription) return 'Trial';
    if (isExpiringSoon) return 'Expiring Soon';
    return 'Active';
  }

  /// Get days remaining text
  String get daysRemainingText {
    if (daysRemaining <= 0) return 'Expired';
    if (daysRemaining == 1) return '1 day remaining';
    return '$daysRemaining days remaining';
  }

  // ============ Debug Methods ============

  /// Refresh subscription status from profile API
  Future<void> refreshPermissions() async {
    debugPrint('🔐 Refreshing permissions from API...');

    try {
      // Force refresh profile from API to get latest permissions
      await _profileService.fetchProfile(forceRefresh: true);

      // Debug the updated subscription status
      debugSubscriptionStatus();

      debugPrint('✅ Permissions refreshed successfully');
    } catch (e) {
      debugPrint('❌ Error refreshing permissions: $e');
    }
  }

  /// Log permission status for debugging
  void debugPermissions() {
    debugSubscriptionStatus();

    debugPrint('🔐 Permission Debug Info:');
    debugPrint('   Subscription: $planName ($subscriptionStatus)');
    debugPrint('   Active: $isSubscriptionActive');
    debugPrint('   Trial: $isTrialSubscription');
    debugPrint('   Days Remaining: $daysRemaining');
    debugPrint('');
    debugPrint(
        '   👤 Role: $userRoleName (Professional: $isProfessional, Client: $isClient)');
    debugPrint('');
    debugPrint('   📚 Legal Library: $canAccessLegalLibrary');
    debugPrint('   ❓ Ask Questions: $canAskQuestions ($questionsQuotaText)');
    debugPrint(
        '   📄 Generate Documents: $canGenerateDocuments ($documentsQuotaText)');
    debugPrint('   📰 Legal Updates: $canReceiveLegalUpdates');
    debugPrint('   💬 Forum Access: $canAccessForum');
    debugPrint('   💬 Forum Comment: $canCommentForum');
    debugPrint('   💬 Forum Reply: $canReplyForum');
    debugPrint('   🎓 Student Hub: $canAccessStudentHub');
    debugPrint('   👨‍⚖️ View Talk to Lawyer: $canViewTalkToLawyer');
    debugPrint('   👨‍⚖️ Can Talk to Lawyer: $canTalkToLawyerAction');
    debugPrint('   📍 View Nearby Lawyers: $canViewNearbyLawyers');
    debugPrint('   📥 Download Templates: $canDownloadTemplates');
    debugPrint('   📅 Book Consultation: $canBookConsultation');
    debugPrint('   📖 Legal Education: $canReadLegalEducation ($legalEducationReads/$legalEducationLimit used)');
    debugPrint('   📞 Purchase Consultations: $canPurchaseConsultations');
    debugPrint('   📋 Purchase Documents: $canPurchaseDocuments');
    debugPrint(
        '   📖 Purchase Learning Materials: $canPurchaseLearningMaterials');
    debugPrint('');
    debugPrint('   🔑 Global Permissions (${globalPermissions.length} total):');
    debugPrint('      Edit Profile: $canEditOwnProfile');
    debugPrint('      Upload Documents: $canUploadDocuments');
    debugPrint('      View Own Documents: $canViewOwnDocuments');
    debugPrint('      Delete Own Documents: $canDeleteOwnDocuments');
    debugPrint('      Search Professionals: $canSearchProfessionals');
    debugPrint(
        '      View Professional Profiles: $canViewProfessionalProfiles');
    debugPrint('      Update Practice Info: $canUpdatePracticeInfo');
    debugPrint(
        '      Manage Address: $canAddAddress/$canChangeAddress/$canDeleteAddress');
    debugPrint(
        '      Manage Contact: $canAddContact/$canChangeContact/$canDeleteContact');
    if (kDebugMode && globalPermissions.length <= 15) {
      debugPrint('      All: ${globalPermissions.join(", ")}');
    }
  }
}

/// Enum for all permission features in the app (subscription-based)
enum PermissionFeature {
  legalLibrary,
  askQuestions,
  generateDocuments,
  legalUpdates,
  forum,
  forumComment,
  forumReply,
  studentHub,
  purchaseConsultations,
  purchaseDocuments,
  purchaseLearningMaterials,
  talkToLawyer,
  nearbyLawyers,
  downloadTemplates,
  bookConsultation,
  legalEducation,
}

/// Enum for global user permissions (CRUD operations)
enum GlobalPermission {
  deleteAddress('delete_address'),
  addAddress('add_address'),
  addContact('add_contact'),
  viewOwnDocuments('view_own_documents'),
  updatePracticeInfo('update_practice_info'),
  changeContact('change_contact'),
  viewVerification('view_verification'),
  deleteOwnDocuments('delete_own_documents'),
  uploadDocuments('upload_documents'),
  changePolaUser('change_polauser'),
  viewProfessionalProfiles('view_professional_profiles'),
  deleteDocument('delete_document'),
  editOwnProfile('edit_own_profile'),
  searchProfessionals('search_professionals'),
  addVerification('add_verification'),
  changeAddress('change_address'),
  viewOwnProfile('view_own_profile'),
  viewContact('view_contact'),
  viewDocument('view_document'),
  changeDocument('change_document'),
  addDocument('add_document'),
  deleteContact('delete_contact'),
  viewPolaUser('view_polauser'),
  viewAddress('view_address');

  final String value;
  const GlobalPermission(this.value);
}
