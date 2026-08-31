import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../models/nearby_lawyer_model.dart';
import '../../../services/api_service.dart';

class NearbyLawyersService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  static const String _nearbyEndpoint =
      '/api/v1/authentication/nearby-legal-professionals/';

  /// Fetch nearby legal professionals
  Future<NearbyLawyersResponse?> fetchNearbyLawyers({
    double radius = 20,
    String types = 'advocate,lawyer,paralegal,law_firm',
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      debugPrint('📍 Fetching nearby lawyers...');
      debugPrint('  - Radius: ${radius}km');
      debugPrint('  - Types: $types');
      debugPrint('  - Page: $page');
      debugPrint('  - PageSize: $pageSize');

      final response = await _apiService.get(
        _nearbyEndpoint,
        queryParameters: {
          'radius': radius,
          'types': types,
          'page': page,
          'page_size': pageSize,
          'debug': '1',
        },
      );

      if (response.statusCode == 200) {
        final nearbyResponse = NearbyLawyersResponse.fromJson(response.data);
        debugPrint('✅ Found ${nearbyResponse.count} nearby lawyers');

        // Log debug diagnostics if present
        if (response.data['debug'] != null) {
          final debug = response.data['debug'];
          debugPrint('🔍 DEBUG: matched_by_role=${debug['matched_by_role']}');
          debugPrint(
              '🔍 DEBUG: role_names_in_db=${debug['all_role_names_in_db']}');
          for (final skipped in (debug['skipped'] as List? ?? [])) {
            debugPrint(
                '🔍 DEBUG: SKIPPED ${skipped['email']} — ${skipped['skipped_reason']}'
                '${skipped['distance_km'] != null ? ' (${skipped['distance_km']}km vs ${skipped['radius_km']}km)' : ''}'
                '${skipped['their_location'] != null ? ' loc=${skipped['their_location']}' : ''}');
          }
        }

        return nearbyResponse;
      } else {
        debugPrint('❌ Failed to fetch nearby lawyers: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching nearby lawyers: $e');
      return null;
    }
  }

  /// Fetch advocates only
  Future<NearbyLawyersResponse?> fetchNearbyAdvocates({
    double radius = 20,
    int page = 1,
    int pageSize = 20,
  }) {
    return fetchNearbyLawyers(
      radius: radius,
      types: 'advocate',
      page: page,
      pageSize: pageSize,
    );
  }

  /// Fetch lawyers only
  Future<NearbyLawyersResponse?> fetchNearbyLawyersOnly({
    double radius = 20,
    int page = 1,
    int pageSize = 20,
  }) {
    return fetchNearbyLawyers(
      radius: radius,
      types: 'lawyer',
      page: page,
      pageSize: pageSize,
    );
  }

  /// Fetch law firms only
  Future<NearbyLawyersResponse?> fetchNearbyLawFirms({
    double radius = 20,
    int page = 1,
    int pageSize = 20,
  }) {
    return fetchNearbyLawyers(
      radius: radius,
      types: 'law_firm',
      page: page,
      pageSize: pageSize,
    );
  }
}
