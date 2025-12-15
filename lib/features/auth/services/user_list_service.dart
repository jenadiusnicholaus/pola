import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';
import '../../../config/environment_config.dart';

class UserListService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  /// Fetch user list with role/group filtering
  /// Commissioners and Assistant Commissioners are ALWAYS included regardless of filter
  Future<UserListResponse?> fetchUserList({
    int page = 1,
    int pageSize = 10,
    List<String>? roles, // Filter by role names
    List<String>? groups, // Filter by group names
    String? search, // Search query
  }) async {
    try {
      debugPrint('📋 Fetching user list...');
      debugPrint('  - Page: $page');
      debugPrint('  - Page Size: $pageSize');
      debugPrint('  - Roles Filter: $roles');
      debugPrint('  - Groups Filter: $groups');
      debugPrint('  - Search: $search');

      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      // Add role filter if provided
      if (roles != null && roles.isNotEmpty) {
        queryParams['roles'] = roles.join(',');
      }

      // Add group filter if provided
      if (groups != null && groups.isNotEmpty) {
        queryParams['groups'] = groups.join(',');
      }

      // Add search query if provided
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiService.get(
        EnvironmentConfig.userListUrl,
        queryParameters: queryParams,
      );

      debugPrint('📥 User list response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final userListResponse = UserListResponse.fromJson(response.data);

        // Ensure Commissioners and Assistant Commissioners are always included
        final commissionerUsers =
            await _fetchCommissioners(page: page, pageSize: pageSize);

        if (commissionerUsers.isNotEmpty) {
          // Merge commissioner users with the filtered results
          // Remove duplicates based on user ID
          final allUsers = <int, UserListItem>{};

          // Add all filtered users first
          for (var user in userListResponse.results) {
            allUsers[user.id] = user;
          }

          // Add commissioners (will not override existing users with same ID)
          for (var commissioner in commissionerUsers) {
            allUsers.putIfAbsent(commissioner.id, () => commissioner);
          }

          // Update the response with merged users
          final mergedResults = allUsers.values.toList();
          debugPrint(
              '✅ Merged user list: ${userListResponse.results.length} filtered + ${commissionerUsers.length} commissioners = ${mergedResults.length} total');

          return UserListResponse(
            count: mergedResults.length,
            next: userListResponse.next,
            previous: userListResponse.previous,
            results: mergedResults,
          );
        }

        return userListResponse;
      }

      debugPrint('⚠️ Failed to fetch user list: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching user list: $e');
      return null;
    }
  }

  /// Fetch only Commissioners and Assistant Commissioners
  Future<List<UserListItem>> _fetchCommissioners({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      debugPrint('👔 Fetching Commissioners...');

      final response = await _apiService.get(
        EnvironmentConfig.userListUrl,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          // Filter for Commissioner and Assistant Commissioner groups
          'groups': 'Commissioner,Assistant Commissioner',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        List<dynamic> resultsData;
        if (data is Map && data.containsKey('results')) {
          resultsData = data['results'] as List;
        } else if (data is List) {
          resultsData = data;
        } else {
          debugPrint('⚠️ Unexpected response format for commissioners');
          return [];
        }

        final commissioners =
            resultsData.map((json) => UserListItem.fromJson(json)).toList();

        debugPrint('✅ Found ${commissioners.length} commissioners');
        return commissioners;
      }

      debugPrint('⚠️ Failed to fetch commissioners: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching commissioners: $e');
      return [];
    }
  }
}

/// User list response model
class UserListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<UserListItem> results;

  UserListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory UserListResponse.fromJson(Map<String, dynamic> json) {
    final resultsData = json['results'] as List? ?? [];
    return UserListResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: resultsData.map((item) => UserListItem.fromJson(item)).toList(),
    );
  }
}

/// User list item model
class UserListItem {
  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? profilePicture;
  final String? userRole; // Role name
  final List<String> groups; // User groups
  final bool isVerified;
  final bool isActive;
  final DateTime? dateJoined;

  UserListItem({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.profilePicture,
    this.userRole,
    required this.groups,
    required this.isVerified,
    required this.isActive,
    this.dateJoined,
  });

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName'.trim();
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    } else {
      return email.split('@').first;
    }
  }

  bool get isCommissioner {
    return groups.any((group) =>
        group.toLowerCase().contains('commissioner') ||
        group.toLowerCase().contains('assistant commissioner'));
  }

  factory UserListItem.fromJson(Map<String, dynamic> json) {
    return UserListItem(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      profilePicture: json['profile_picture'],
      userRole: json['user_role'],
      groups:
          (json['groups'] as List?)?.map((g) => g.toString()).toList() ?? [],
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? true,
      dateJoined: json['date_joined'] != null
          ? DateTime.tryParse(json['date_joined'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'profile_picture': profilePicture,
      'user_role': userRole,
      'groups': groups,
      'is_verified': isVerified,
      'is_active': isActive,
      'date_joined': dateJoined?.toIso8601String(),
    };
  }
}
