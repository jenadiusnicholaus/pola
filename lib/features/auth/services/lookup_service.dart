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
  final RxList<LawFirm> _lawFirms = <LawFirm>[].obs;

  // Loading states
  final RxBool _isLoadingRoles = false.obs;
  final RxBool _isLoadingRegions = false.obs;
  final RxBool _isLoadingDistricts = false.obs;
  final RxBool _isLoadingSpecializations = false.obs;
  final RxBool _isLoadingWorkplaces = false.obs;
  final RxBool _isLoadingChapters = false.obs;
  final RxBool _isLoadingAdvocates = false.obs;
  final RxBool _isLoadingLawFirms = false.obs;

  // Getters
  List<UserRole> get userRoles => _userRoles;
  List<Region> get regions => _regions;
  List<District> get districts => _districts;
  List<Specialization> get specializations => _specializations;
  List<Workplace> get workplaces => _workplaces;
  List<Chapter> get chapters => _chapters;
  List<Advocate> get advocates => _advocates;
  List<LawFirm> get lawFirms => _lawFirms;

  bool get isLoadingRoles => _isLoadingRoles.value;
  bool get isLoadingRegions => _isLoadingRegions.value;
  bool get isLoadingDistricts => _isLoadingDistricts.value;
  bool get isLoadingSpecializations => _isLoadingSpecializations.value;
  bool get isLoadingWorkplaces => _isLoadingWorkplaces.value;
  bool get isLoadingChapters => _isLoadingChapters.value;
  bool get isLoadingAdvocates => _isLoadingAdvocates.value;
  bool get isLoadingLawFirms => _isLoadingLawFirms.value;

  // Role order priority - arranged by expected user significance
  // Swahili first: Mwananchi, Wakili, Mwanasheria, Msaidizi wa Kisheria, Ofisi ya Mawakili, Mwanafunzi wa Sheria, Mhadhiri
  static const List<String> _roleOrder = [
    'citizen',      // Mwananchi | Citizen
    'advocate',     // Wakili | Advocate
    'lawyer',       // Mwanasheria | Lawyer
    'paralegal',    // Msaidizi wa Kisheria | Paralegal
    'law_firm',     // Ofisi ya Mawakili | Law Firm
    'law_student',  // Mwanafunzi wa Sheria | Law Student
    'lecturer',     // Mhadhiri | Lecturer
  ];

  /// Sort roles by significance order
  List<UserRole> _sortRolesBySignificance(List<UserRole> roles) {
    roles.sort((a, b) {
      final indexA = _roleOrder.indexOf(a.roleName);
      final indexB = _roleOrder.indexOf(b.roleName);
      // If role not in order list, put at end
      final orderA = indexA == -1 ? _roleOrder.length : indexA;
      final orderB = indexB == -1 ? _roleOrder.length : indexB;
      return orderA.compareTo(orderB);
    });
    return roles;
  }

  // Fetch user roles
  Future<List<UserRole>> fetchUserRoles() async {
    if (_userRoles.isNotEmpty) return _userRoles;

    try {
      _isLoadingRoles.value = true;
      final response = await _apiService.get(EnvironmentConfig.rolesUrl);

      print('API Response: ${response.data}');
      print('Response type: ${response.data.runtimeType}');

      if (response.data != null) {
        List<dynamic>? data;

        // NEW FORMAT: Response with 'roles' key containing paginated data
        // Example: {"ui": {...}, "roles": {"count": 7, "results": [...]}}
        if (response.data is Map && response.data['roles'] != null) {
          final rolesData = response.data['roles'];
          if (rolesData is Map && rolesData['results'] != null) {
            data = rolesData['results'] as List<dynamic>;
            print('Successfully parsed roles from nested roles.results format');
          }
        }
        // OLD FORMAT: Direct paginated response with 'results' array
        // Example: {"count": 7, "results": [...]}
        else if (response.data is Map && response.data['results'] != null) {
          data = response.data['results'] as List<dynamic>;
          print('Successfully parsed roles from direct paginated response');
        }
        // OLD FORMAT: Direct list (for backwards compatibility)
        // Example: [{...}, {...}]
        else if (response.data is List) {
          data = response.data as List<dynamic>;
          print('Successfully parsed roles from direct list response');
        }

        if (data != null) {
          final parsedRoles = data.map((json) => UserRole.fromJson(json)).toList();
          // Sort roles by significance order
          _userRoles.value = _sortRolesBySignificance(parsedRoles);
          print('Successfully loaded ${_userRoles.length} user roles (sorted by significance)');
        } else {
          // API might be returning an error or different format
          print('Expected paginated response or List but got: ${response.data}');
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
        url += '?region=$regionId';
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

        // Always update cache - merge with existing districts to keep all loaded
        for (final district in districts) {
          final existingIndex = _districts.indexWhere((d) => d.id == district.id);
          if (existingIndex == -1) {
            _districts.add(district);
          }
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

  // Fetch law firms
  Future<List<LawFirm>> fetchLawFirms() async {
    if (_lawFirms.isNotEmpty) return _lawFirms;

    try {
      _isLoadingLawFirms.value = true;
      final response = await _apiService.get(EnvironmentConfig.lawFirmsUrl);

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
          throw Exception('Invalid API response format for law firms');
        }
        _lawFirms.value = data.map((json) => LawFirm.fromJson(json)).toList();
      }

      return _lawFirms;
    } catch (e) {
      print('Error fetching law firms: $e');
      throw Exception('Failed to fetch law firms from API: $e');
    } finally {
      _isLoadingLawFirms.value = false;
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
    _lawFirms.clear();
  }
}
