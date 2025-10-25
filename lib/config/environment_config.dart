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

  // Complete authentication URLs
  static String get loginUrl => '$baseUrl$loginEndpoint';
  static String get registerUrl => '$baseUrl$registerEndpoint';
  static String get refreshTokenUrl => '$baseUrl$refreshTokenEndpoint';
  static String get logoutUrl => '$baseUrl$logoutEndpoint';
  static String get profileUrl => '$baseUrl/api/v1/authentication/profile/';

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
}
