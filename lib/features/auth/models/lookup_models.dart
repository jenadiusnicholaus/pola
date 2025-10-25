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
      id: json['id'] as int,
      roleName: json['role_name'] as String,
      getRoleDisplay: json['get_role_display'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role_name': roleName,
      'get_role_display': getRoleDisplay,
      'description': description,
    };
  }
}

class Region {
  final int id;
  final String name;

  Region({
    required this.id,
    required this.name,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class District {
  final int id;
  final String name;
  final int regionId;
  final String? regionName;

  District({
    required this.id,
    required this.name,
    required this.regionId,
    this.regionName,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] as int,
      name: json['name'] as String,
      regionId: json['region'] as int, // API uses 'region' not 'region_id'
      regionName: json['region_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'region': regionId,
      'region_name': regionName,
    };
  }
}

class Specialization {
  final int id;
  final String nameEn;
  final String? nameSw;
  final String? description;

  Specialization({
    required this.id,
    required this.nameEn,
    this.nameSw,
    this.description,
  });

  // Use English name as the default display name
  String get name => nameEn;

  factory Specialization.fromJson(Map<String, dynamic> json) {
    return Specialization(
      id: json['id'] as int,
      nameEn: json['name_en'] as String,
      nameSw: json['name_sw'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_sw': nameSw,
      'description': description,
    };
  }
}

class Workplace {
  final int id;
  final String? code;
  final String nameEn;
  final String? nameSw;

  Workplace({
    required this.id,
    this.code,
    required this.nameEn,
    this.nameSw,
  });

  // Use nameEn as the display name
  String get name => nameEn;

  factory Workplace.fromJson(Map<String, dynamic> json) {
    return Workplace(
      id: json['id'] as int,
      code: json['code'] as String?,
      nameEn: json['name_en'] as String,
      nameSw: json['name_sw'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name_en': nameEn,
      'name_sw': nameSw,
    };
  }
}

class Chapter {
  final int id;
  final String name;
  final String? code;
  final int? region;
  final String? regionName;
  final bool? isActive;
  final String? description;

  Chapter({
    required this.id,
    required this.name,
    this.code,
    this.region,
    this.regionName,
    this.isActive,
    this.description,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
      region: json['region'] as int?,
      regionName: json['region_name'] as String?,
      isActive: json['is_active'] as bool?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'region': region,
      'region_name': regionName,
      'is_active': isActive,
      'description': description,
    };
  }
}

class Advocate {
  final int id;
  final String fullName;
  final String email;
  final String rollNumber;
  final String? regionalChapterName;

  Advocate({
    required this.id,
    required this.fullName,
    required this.email,
    required this.rollNumber,
    this.regionalChapterName,
  });

  factory Advocate.fromJson(Map<String, dynamic> json) {
    return Advocate(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      rollNumber: json['roll_number'] as String,
      regionalChapterName: json['regional_chapter_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'roll_number': rollNumber,
      'regional_chapter_name': regionalChapterName,
    };
  }
}
