import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  // Initialize environment
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
  }

  // App Environment
  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';

  // Base URLs
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';
  static String get apiVersion => dotenv.env['API_VERSION'] ?? 'v1';

  // Complete API URL
  static String get completeApiUrl => '$baseUrl/api/$apiVersion';

  // API Keys
  static String get apiKey => dotenv.env['API_KEY'] ?? '';

  // Timeouts
  static int get connectionTimeout =>
      int.tryParse(dotenv.env['CONNECTION_TIMEOUT'] ?? '30000') ?? 30000;
  static int get receiveTimeout =>
      int.tryParse(dotenv.env['RECEIVE_TIMEOUT'] ?? '30000') ?? 30000;
  static int get sendTimeout =>
      int.tryParse(dotenv.env['SEND_TIMEOUT'] ?? '30000') ?? 30000;

  // Logging
  static bool get enableLogging =>
      dotenv.env['ENABLE_LOGGING']?.toLowerCase() == 'true';

  // Authentication endpoints
  static String get loginEndpoint =>
      dotenv.env['LOGIN_ENDPOINT'] ?? '/auth/login';
  static String get registerEndpoint =>
      dotenv.env['REGISTER_ENDPOINT'] ?? '/auth/register';
  static String get refreshTokenEndpoint =>
      dotenv.env['REFRESH_TOKEN_ENDPOINT'] ?? '/auth/refresh';
  static String get logoutEndpoint =>
      dotenv.env['LOGOUT_ENDPOINT'] ?? '/auth/logout';
  static String get profileEndpoint =>
      dotenv.env['PROFILE_ENDPOINT'] ?? '/api/v1/authentication/profile/';

  // Complete authentication URLs
  static String get loginUrl => '$baseUrl$loginEndpoint';
  static String get registerUrl => '$baseUrl$registerEndpoint';
  static String get refreshTokenUrl => '$baseUrl$refreshTokenEndpoint';
  static String get logoutUrl => '$baseUrl$logoutEndpoint';
  static String get profileUrl => '$baseUrl$profileEndpoint';

  // Legal Education endpoints
  static String get legalEducationTopicsEndpoint =>
      dotenv.env['LEGAL_EDUCATION_TOPICS_ENDPOINT'] ??
      '/api/v1/hubs/legal-education/topics/';
  static String get legalEducationSubtopicsEndpoint =>
      dotenv.env['LEGAL_EDUCATION_SUBTOPICS_ENDPOINT'] ??
      '/api/v1/hubs/legal-education/subtopics/';

  // Complete Legal Education URLs
  static String get legalEducationTopicsUrl =>
      '$baseUrl$legalEducationTopicsEndpoint';
  static String get legalEducationSubtopicsUrl =>
      '$baseUrl$legalEducationSubtopicsEndpoint';

  // Lookup endpoints
  static String get lookupsBaseUrl =>
      dotenv.env['LOOKUPS_BASE_URL'] ?? '/api/v1/lookups';
  static String get rolesEndpoint => dotenv.env['ROLES_ENDPOINT'] ?? '/roles';
  static String get regionsEndpoint =>
      dotenv.env['REGIONS_ENDPOINT'] ?? '/regions';
  static String get districtsEndpoint =>
      dotenv.env['DISTRICTS_ENDPOINT'] ?? '/districts';
  static String get specializationsEndpoint =>
      dotenv.env['SPECIALIZATIONS_ENDPOINT'] ?? '/specializations';
  static String get workplacesEndpoint =>
      dotenv.env['WORKPLACES_ENDPOINT'] ?? '/workplaces';
  static String get chaptersEndpoint =>
      dotenv.env['CHAPTERS_ENDPOINT'] ?? '/chapters';
  static String get advocatesEndpoint =>
      dotenv.env['ADVOCATES_ENDPOINT'] ?? '/advocates';

  // Complete lookup URLs
  static String get rolesUrl => '$baseUrl$lookupsBaseUrl$rolesEndpoint';
  static String get regionsUrl => '$baseUrl$lookupsBaseUrl$regionsEndpoint';
  static String get districtsUrl => '$baseUrl$lookupsBaseUrl$districtsEndpoint';
  static String get specializationsUrl =>
      '$baseUrl$lookupsBaseUrl$specializationsEndpoint';
  static String get workplacesUrl =>
      '$baseUrl$lookupsBaseUrl$workplacesEndpoint';
  static String get chaptersUrl => '$baseUrl$lookupsBaseUrl$chaptersEndpoint';
  static String get advocatesUrl => '$baseUrl$lookupsBaseUrl$advocatesEndpoint';

  // Hub Content endpoints
  static String get hubContentEndpoint =>
      dotenv.env['HUB_CONTENT_ENDPOINT'] ?? '/api/hubs/content/';
  static String get hubContentBookmarkedEndpoint =>
      dotenv.env['HUB_CONTENT_BOOKMARKED_ENDPOINT'] ??
      '/api/hubs/content/bookmarked/';
  static String get hubContentTrendingEndpoint =>
      dotenv.env['HUB_CONTENT_TRENDING_ENDPOINT'] ??
      '/api/v1/hubs/content/trending/';
  static String get hubContentRecentEndpoint =>
      dotenv.env['HUB_CONTENT_RECENT_ENDPOINT'] ??
      '/api/v1/hubs/content/recent/';
  static String get hubContentLikeEndpoint =>
      dotenv.env['HUB_CONTENT_LIKE_ENDPOINT'] ?? '/api/hubs/content/{id}/like/';
  static String get hubContentBookmarkEndpoint =>
      dotenv.env['HUB_CONTENT_BOOKMARK_ENDPOINT'] ??
      '/api/hubs/content/{id}/bookmark/';
  static String get hubContentRateEndpoint =>
      dotenv.env['HUB_CONTENT_RATE_ENDPOINT'] ?? '/api/hubs/content/{id}/rate/';
  static String get hubContentViewEndpoint =>
      dotenv.env['HUB_CONTENT_VIEW_ENDPOINT'] ?? '/api/hubs/content/{id}/view/';

  // Hub Comments endpoints
  static String get hubCommentsEndpoint =>
      dotenv.env['HUB_COMMENTS_ENDPOINT'] ?? '/api/v1/hubs/comments/';
  static String get hubCommentLikeEndpoint =>
      dotenv.env['HUB_COMMENT_LIKE_ENDPOINT'] ??
      '/api/v1/hubs/comments/{id}/like/';

  // Complete Hub Content URLs
  static String get hubContentUrl => '$baseUrl$hubContentEndpoint';
  static String get hubContentBookmarkedUrl =>
      '$baseUrl$hubContentBookmarkedEndpoint';
  static String get hubContentTrendingUrl =>
      '$baseUrl$hubContentTrendingEndpoint';
  static String get hubContentRecentUrl => '$baseUrl$hubContentRecentEndpoint';
  static String hubContentLikeUrl(int contentId) =>
      '$baseUrl${hubContentLikeEndpoint.replaceAll('{id}', contentId.toString())}';
  static String hubContentBookmarkUrl(int contentId) =>
      '$baseUrl${hubContentBookmarkEndpoint.replaceAll('{id}', contentId.toString())}';
  static String hubContentRateUrl(int contentId) =>
      '$baseUrl${hubContentRateEndpoint.replaceAll('{id}', contentId.toString())}';
  static String hubContentViewUrl(int contentId) =>
      '$baseUrl${hubContentViewEndpoint.replaceAll('{id}', contentId.toString())}';

  // Complete Hub Comments URLs
  static String get hubCommentsUrl => '$baseUrl$hubCommentsEndpoint';
  static String hubCommentLikeUrl(int commentId) =>
      '$baseUrl${hubCommentLikeEndpoint.replaceAll('{id}', commentId.toString())}';

  // User Verification endpoints
  static String get verificationStatusEndpoint =>
      dotenv.env['VERIFICATION_STATUS_ENDPOINT'] ??
      '/api/v1/authentication/verifications/my_status/';
  static String get verificationUploadDocumentEndpoint =>
      dotenv.env['VERIFICATION_UPLOAD_DOCUMENT_ENDPOINT'] ??
      '/api/v1/authentication/verifications/upload_document/';
  static String get verificationDocumentsEndpoint =>
      dotenv.env['VERIFICATION_DOCUMENTS_ENDPOINT'] ??
      '/api/v1/authentication/documents/';
  static String get verificationUpdateInfoEndpoint =>
      dotenv.env['VERIFICATION_UPDATE_INFO_ENDPOINT'] ??
      '/api/v1/authentication/verifications/update_info/';
  static String get verificationSubmitReviewEndpoint =>
      dotenv.env['VERIFICATION_SUBMIT_REVIEW_ENDPOINT'] ??
      '/api/v1/authentication/verifications/submit_for_review/';
  static String get verificationDeleteDocumentEndpoint =>
      dotenv.env['VERIFICATION_DELETE_DOCUMENT_ENDPOINT'] ??
      '/api/v1/authentication/verifications/documents/{id}/';
  static String get verificationRequiredDocumentsEndpoint =>
      dotenv.env['VERIFICATION_REQUIRED_DOCUMENTS_ENDPOINT'] ??
      '/api/v1/authentication/verifications/required_documents/';

  // Complete User Verification URLs
  static String get verificationStatusUrl =>
      '$baseUrl$verificationStatusEndpoint';
  static String get verificationUploadDocumentUrl =>
      '$baseUrl$verificationUploadDocumentEndpoint';
  static String get verificationDocumentsUrl =>
      '$baseUrl$verificationDocumentsEndpoint';
  static String get verificationUpdateInfoUrl =>
      '$baseUrl$verificationUpdateInfoEndpoint';
  static String get verificationSubmitReviewUrl =>
      '$baseUrl$verificationSubmitReviewEndpoint';
  static String verificationDeleteDocumentUrl(int documentId) =>
      '$baseUrl${verificationDeleteDocumentEndpoint.replaceAll('{id}', documentId.toString())}';
  static String get verificationRequiredDocumentsUrl =>
      '$baseUrl$verificationRequiredDocumentsEndpoint';

  // Legal Education Admin endpoints
  static String get legalEducationAdminTopicsEndpoint =>
      dotenv.env['LEGAL_EDUCATION_ADMIN_TOPICS_ENDPOINT'] ??
      '/api/v1/admin/hubs/topics/';
  static String get legalEducationAdminTopicsQuickCreateEndpoint =>
      dotenv.env['LEGAL_EDUCATION_ADMIN_TOPICS_QUICK_CREATE_ENDPOINT'] ??
      '/api/v1/admin/hubs/topics/quick_create/';

  // Complete Legal Education Admin URLs
  static String get legalEducationAdminTopicsUrl =>
      '$baseUrl$legalEducationAdminTopicsEndpoint';
  static String get legalEducationAdminTopicsQuickCreateUrl =>
      '$baseUrl$legalEducationAdminTopicsQuickCreateEndpoint';
}
