import 'package:get/get.dart';
import '../../../services/api_service.dart';
import '../../../config/environment_config.dart';
import '../models/lookup_models.dart';

class LookupService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  // Cache for lookups to avoid repeated API calls
  final RxList<UserRole> _userRoles = <UserRole>[].obs;
  final RxList<Region> _regions = <Region>[].obs;
  final RxList<District> _districts = <District>[].obs;
  final RxList<Specialization> _specializations = <Specialization>[].obs;
  final RxList<Workplace> _workplaces = <Workplace>[].obs;
  final RxList<Chapter> _chapters = <Chapter>[].obs;
  final RxList<Advocate> _advocates = <Advocate>[].obs;

  // Loading states
  final RxBool _isLoadingRoles = false.obs;
  final RxBool _isLoadingRegions = false.obs;
  final RxBool _isLoadingDistricts = false.obs;
  final RxBool _isLoadingSpecializations = false.obs;
  final RxBool _isLoadingWorkplaces = false.obs;
  final RxBool _isLoadingChapters = false.obs;
  final RxBool _isLoadingAdvocates = false.obs;

  // Getters
  List<UserRole> get userRoles => _userRoles;
  List<Region> get regions => _regions;
  List<District> get districts => _districts;
  List<Specialization> get specializations => _specializations;
  List<Workplace> get workplaces => _workplaces;
  List<Chapter> get chapters => _chapters;
  List<Advocate> get advocates => _advocates;

  bool get isLoadingRoles => _isLoadingRoles.value;
  bool get isLoadingRegions => _isLoadingRegions.value;
  bool get isLoadingDistricts => _isLoadingDistricts.value;
  bool get isLoadingSpecializations => _isLoadingSpecializations.value;
  bool get isLoadingWorkplaces => _isLoadingWorkplaces.value;
  bool get isLoadingChapters => _isLoadingChapters.value;
  bool get isLoadingAdvocates => _isLoadingAdvocates.value;

  // Fetch user roles
  Future<List<UserRole>> fetchUserRoles() async {
    if (_userRoles.isNotEmpty) return _userRoles;

    try {
      _isLoadingRoles.value = true;
      final response = await _apiService.get(EnvironmentConfig.rolesUrl);

      print('API Response: ${response.data}');
      print('Response type: ${response.data.runtimeType}');

      if (response.data != null) {
        // Check if the response is a paginated response with 'results' array
        if (response.data is Map && response.data['results'] != null) {
          final List<dynamic> data = response.data['results'] as List<dynamic>;
          _userRoles.value =
              data.map((json) => UserRole.fromJson(json)).toList();
          print(
              'Successfully parsed ${_userRoles.length} user roles from paginated response');
        }
        // Check if the response is directly a list (for backwards compatibility)
        else if (response.data is List) {
          final List<dynamic> data = response.data as List<dynamic>;
          _userRoles.value =
              data.map((json) => UserRole.fromJson(json)).toList();
          print(
              'Successfully parsed ${_userRoles.length} user roles from direct list response');
        } else {
          // API might be returning an error or different format
          print(
              'Expected paginated response or List but got: ${response.data}');
          throw Exception('Invalid API response format for user roles');
        }
      }

      return _userRoles;
    } catch (e) {
      print('Error fetching user roles: $e');
      throw Exception('Failed to fetch user roles from API: $e');
    } finally {
      _isLoadingRoles.value = false;
    }
  }

  // Fetch regions
  Future<List<Region>> fetchRegions() async {
    if (_regions.isNotEmpty) return _regions;

    try {
      _isLoadingRegions.value = true;
      final response = await _apiService.get(EnvironmentConfig.regionsUrl);

      if (response.data != null) {
        List<dynamic> data;
        // Check if the response is a paginated response with 'results' array
        if (response.data is Map && response.data['results'] != null) {
          data = response.data['results'] as List<dynamic>;
        }
        // Check if the response is directly a list (for backwards compatibility)
        else if (response.data is List) {
          data = response.data as List<dynamic>;
        } else {
          throw Exception('Invalid API response format for regions');
        }
        _regions.value = data.map((json) => Region.fromJson(json)).toList();
      }

      return _regions;
    } catch (e) {
      print('Error fetching regions: $e');
      throw Exception('Failed to fetch regions from API: $e');
    } finally {
      _isLoadingRegions.value = false;
    }
  }

  // Fetch districts
  Future<List<District>> fetchDistricts({int? regionId}) async {
    try {
      _isLoadingDistricts.value = true;
      String url = EnvironmentConfig.districtsUrl;
      if (regionId != null) {
        url += '?region_id=$regionId';
      }

      final response = await _apiService.get(url);

      if (response.data != null) {
        List<dynamic> data;
        // Check if the response is a paginated response with 'results' array
        if (response.data is Map && response.data['results'] != null) {
          data = response.data['results'] as List<dynamic>;
        }
        // Check if the response is directly a list (for backwards compatibility)
        else if (response.data is List) {
          data = response.data as List<dynamic>;
        } else {
          throw Exception('Invalid API response format for districts');
        }

        final districts = data.map((json) => District.fromJson(json)).toList();

        if (regionId == null) {
          _districts.value = districts;
        }

        return districts;
      }

      return [];
    } catch (e) {
      print('Error fetching districts: $e');
      throw Exception('Failed to fetch districts from API: $e');
    } finally {
      _isLoadingDistricts.value = false;
    }
  }

  // Fetch specializations
  Future<List<Specialization>> fetchSpecializations() async {
    if (_specializations.isNotEmpty) return _specializations;

    try {
      _isLoadingSpecializations.value = true;
      final response =
          await _apiService.get(EnvironmentConfig.specializationsUrl);

      if (response.data != null) {
        List<dynamic> data;
        // Check if the response is a paginated response with 'results' array
        if (response.data is Map && response.data['results'] != null) {
          data = response.data['results'] as List<dynamic>;
        }
        // Check if the response is directly a list (for backwards compatibility)
        else if (response.data is List) {
          data = response.data as List<dynamic>;
        } else {
          throw Exception('Invalid API response format for specializations');
        }
        _specializations.value =
            data.map((json) => Specialization.fromJson(json)).toList();
      }

      return _specializations;
    } catch (e) {
      print('Error fetching specializations: $e');
      throw Exception('Failed to fetch specializations from API: $e');
    } finally {
      _isLoadingSpecializations.value = false;
    }
  }

  // Fetch workplaces
  Future<List<Workplace>> fetchWorkplaces() async {
    if (_workplaces.isNotEmpty) return _workplaces;

    try {
      _isLoadingWorkplaces.value = true;
      final response = await _apiService.get(EnvironmentConfig.workplacesUrl);

      if (response.data != null) {
        List<dynamic> data;
        // Check if the response is a paginated response with 'results' array
        if (response.data is Map && response.data['results'] != null) {
          data = response.data['results'] as List<dynamic>;
        }
        // Check if the response is directly a list (for backwards compatibility)
        else if (response.data is List) {
          data = response.data as List<dynamic>;
        } else {
          throw Exception('Invalid API response format for workplaces');
        }
        _workplaces.value =
            data.map((json) => Workplace.fromJson(json)).toList();
      }

      return _workplaces;
    } catch (e) {
      print('Error fetching workplaces: $e');
      throw Exception('Failed to fetch workplaces from API: $e');
    } finally {
      _isLoadingWorkplaces.value = false;
    }
  }

  // Fetch chapters
  Future<List<Chapter>> fetchChapters() async {
    if (_chapters.isNotEmpty) return _chapters;

    try {
      _isLoadingChapters.value = true;
      final response = await _apiService.get(EnvironmentConfig.chaptersUrl);

      if (response.data != null) {
        List<dynamic> data;
        // Check if the response is a paginated response with 'results' array
        if (response.data is Map && response.data['results'] != null) {
          data = response.data['results'] as List<dynamic>;
        }
        // Check if the response is directly a list (for backwards compatibility)
        else if (response.data is List) {
          data = response.data as List<dynamic>;
        } else {
          throw Exception('Invalid API response format for chapters');
        }
        _chapters.value = data.map((json) => Chapter.fromJson(json)).toList();
      }

      return _chapters;
    } catch (e) {
      print('Error fetching chapters: $e');
      throw Exception('Failed to fetch chapters from API: $e');
    } finally {
      _isLoadingChapters.value = false;
    }
  }

  // Get districts for a specific region
  List<District> getDistrictsForRegion(int regionId) {
    return _districts
        .where((district) => district.regionId == regionId)
        .toList();
  }

  // Fetch advocates
  Future<List<Advocate>> fetchAdvocates() async {
    if (_advocates.isNotEmpty) return _advocates;

    try {
      _isLoadingAdvocates.value = true;
      final response = await _apiService.get(EnvironmentConfig.advocatesUrl);

      if (response.data != null) {
        List<dynamic> data;
        // Check if the response is a paginated response with 'results' array
        if (response.data is Map && response.data['results'] != null) {
          data = response.data['results'] as List<dynamic>;
        }
        // Check if the response is directly a list (for backwards compatibility)
        else if (response.data is List) {
          data = response.data as List<dynamic>;
        } else {
          throw Exception('Invalid API response format for advocates');
        }
        _advocates.value = data.map((json) => Advocate.fromJson(json)).toList();
      }

      return _advocates;
    } catch (e) {
      print('Error fetching advocates: $e');
      throw Exception('Failed to fetch advocates from API: $e');
    } finally {
      _isLoadingAdvocates.value = false;
    }
  }

  // Clear cache (useful for refresh)
  void clearCache() {
    _userRoles.clear();
    _regions.clear();
    _districts.clear();
    _specializations.clear();
    _workplaces.clear();
    _chapters.clear();
    _advocates.clear();
  }
}
