import 'package:get/get.dart';
import '../../../config/environment_config.dart';
import '../../../services/api_service.dart';
import '../models/statute_models.dart';

class StatutesService {
  final ApiService _api = Get.find<ApiService>();

  String get _categoriesUrl =>
      '${EnvironmentConfig.baseUrl}/api/v1/statutes/categories/';
  String get _lawsUrl => '${EnvironmentConfig.baseUrl}/api/v1/statutes/laws/';

  Future<({List<StatuteCategory> items, bool hasMore, int count})>
      fetchCategories({int page = 1, int pageSize = 20, String? search}) async {
    final response = await _api.get(
      _categoriesUrl,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return _parseCategories(response.data);
  }

  Future<({List<StatuteLaw> items, bool hasMore, int count})> fetchLaws({
    int page = 1,
    int pageSize = 20,
    int? categoryId,
    String? search,
  }) async {
    final response = await _api.get(
      _lawsUrl,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (categoryId != null) 'category': categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return _parseLaws(response.data);
  }

  ({List<StatuteCategory> items, bool hasMore, int count}) _parseCategories(
      dynamic data) {
    if (data is Map) {
      final results = (data['results'] as List? ?? [])
          .whereType<Map>()
          .map((e) => StatuteCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return (
        items: results,
        hasMore: data['next'] != null,
        count: data['count'] as int? ?? results.length,
      );
    }
    if (data is List) {
      final results = data
          .whereType<Map>()
          .map((e) => StatuteCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return (items: results, hasMore: false, count: results.length);
    }
    return (items: <StatuteCategory>[], hasMore: false, count: 0);
  }

  ({List<StatuteLaw> items, bool hasMore, int count}) _parseLaws(dynamic data) {
    if (data is Map) {
      final results = (data['results'] as List? ?? [])
          .whereType<Map>()
          .map((e) => StatuteLaw.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return (
        items: results,
        hasMore: data['next'] != null,
        count: data['count'] as int? ?? results.length,
      );
    }
    if (data is List) {
      final results = data
          .whereType<Map>()
          .map((e) => StatuteLaw.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return (items: results, hasMore: false, count: results.length);
    }
    return (items: <StatuteLaw>[], hasMore: false, count: 0);
  }
}
