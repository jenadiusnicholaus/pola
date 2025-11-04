class Topic {
  final int id;
  final String name;
  final String nameSw;
  final String slug;
  final String description;
  final String descriptionSw;
  final String? icon;
  final int displayOrder;
  final bool isActive;
  final int subtopicsCount;
  final int materialsCount;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final List<Subtopic>? subtopics;

  Topic({
    required this.id,
    required this.name,
    required this.nameSw,
    required this.slug,
    required this.description,
    required this.descriptionSw,
    this.icon,
    required this.displayOrder,
    required this.isActive,
    required this.subtopicsCount,
    required this.materialsCount,
    required this.createdAt,
    required this.lastUpdated,
    this.subtopics,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'],
      name: json['name'] ?? '',
      nameSw: json['name_sw'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      descriptionSw: json['description_sw'] ?? '',
      icon: json['icon'],
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      subtopicsCount: json['subtopics_count'] ?? 0,
      materialsCount: json['materials_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      lastUpdated: DateTime.parse(json['last_updated']),
      subtopics: json['subtopics'] != null
          ? (json['subtopics'] as List)
              .map((subtopic) => Subtopic.fromJson(subtopic))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_sw': nameSw,
      'slug': slug,
      'description': description,
      'description_sw': descriptionSw,
      'icon': icon,
      'display_order': displayOrder,
      'is_active': isActive,
      'subtopics_count': subtopicsCount,
      'materials_count': materialsCount,
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
      'subtopics': subtopics?.map((s) => s.toJson()).toList(),
    };
  }
}

class Subtopic {
  final int id;
  final int topic;
  final String topicName;
  final String topicNameSw;
  final String name;
  final String nameSw;
  final String slug;
  final String description;
  final String descriptionSw;
  final int displayOrder;
  final bool isActive;
  final int materialsCount;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final List<LearningMaterial>? materials;

  Subtopic({
    required this.id,
    required this.topic,
    required this.topicName,
    required this.topicNameSw,
    required this.name,
    required this.nameSw,
    required this.slug,
    required this.description,
    required this.descriptionSw,
    required this.displayOrder,
    required this.isActive,
    required this.materialsCount,
    required this.createdAt,
    required this.lastUpdated,
    this.materials,
  });

  factory Subtopic.fromJson(Map<String, dynamic> json) {
    return Subtopic(
      id: json['id'],
      topic: json['topic'] ?? 0,
      topicName: json['topic_name'] ?? '',
      topicNameSw: json['topic_name_sw'] ?? '',
      name: json['name'] ?? '',
      nameSw: json['name_sw'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      descriptionSw: json['description_sw'] ?? '',
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      materialsCount: json['materials_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      lastUpdated: DateTime.parse(json['last_updated']),
      materials: json['materials'] != null
          ? (json['materials'] as List)
              .map((material) => LearningMaterial.fromJson(material))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic': topic,
      'topic_name': topicName,
      'topic_name_sw': topicNameSw,
      'name': name,
      'name_sw': nameSw,
      'slug': slug,
      'description': description,
      'description_sw': descriptionSw,
      'display_order': displayOrder,
      'is_active': isActive,
      'materials_count': materialsCount,
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
      'materials': materials?.map((m) => m.toJson()).toList(),
    };
  }
}

// Removed old Material class - replaced with LearningMaterial below

class TopicsResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Topic> results;

  TopicsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory TopicsResponse.fromJson(Map<String, dynamic> json) {
    return TopicsResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List?)
              ?.map((topic) => Topic.fromJson(topic))
              .toList() ??
          [],
    );
  }
}

class SubtopicsResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Subtopic> results;

  SubtopicsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory SubtopicsResponse.fromJson(Map<String, dynamic> json) {
    return SubtopicsResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List?)
              ?.map((subtopic) => Subtopic.fromJson(subtopic))
              .toList() ??
          [],
    );
  }
}

// LearningMaterial model for direct topic-to-materials approach
class LearningMaterial {
  final int id;
  final String hubType;
  final String contentType;
  final UploaderInfo uploaderInfo;
  final String title;
  final String description;
  final String fileUrl;
  final String language;
  final String price;
  final bool isDownloadable;
  final bool isLectureMaterial;
  final bool isVerified;
  final int downloadsCount;
  final DateTime createdAt;
  final DateTime lastUpdated;

  LearningMaterial({
    required this.id,
    required this.hubType,
    required this.contentType,
    required this.uploaderInfo,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.language,
    required this.price,
    required this.isDownloadable,
    required this.isLectureMaterial,
    required this.isVerified,
    required this.downloadsCount,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory LearningMaterial.fromJson(Map<String, dynamic> json) {
    // Create uploader info from flat structure
    final uploaderInfo = UploaderInfo(
      id: json['uploader'] ?? 0,
      email: json['uploader_email'] ?? '',
      fullName: json['uploader_name'] ?? '',
      userRole: json['uploader_type'] ?? '',
      isVerified: json['is_verified'] ?? false,
      avatarUrl: json['uploader_avatar'],
    );

    // Normalize file fields: some endpoints return 'file', others 'file_url'
    final rawFile = json['file'] ?? json['file_url'] ?? '';

    return LearningMaterial(
      id: json['id'],
      hubType: json['hub_type'] ?? '',
      contentType: json['content_type'] ?? '',
      uploaderInfo: uploaderInfo,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      fileUrl: rawFile,
      language: json['language'] ?? 'en',
      price: json['price'] ?? '0.00',
      isDownloadable: json['is_downloadable'] ?? false,
      isLectureMaterial: json['is_lecture_material'] ?? false,
      isVerified: json['is_verified'] ?? false,
      downloadsCount: json['downloads_count'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      lastUpdated:
          DateTime.tryParse(json['last_updated'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hub_type': hubType,
      'content_type': contentType,
      'uploader_info': uploaderInfo.toJson(),
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'language': language,
      'price': price,
      'is_downloadable': isDownloadable,
      'is_lecture_material': isLectureMaterial,
      'is_verified': isVerified,
      'downloads_count': downloadsCount,
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

// Uploader info model
class UploaderInfo {
  final int id;
  final String email;
  final String fullName;
  final String userRole;
  final bool isVerified;
  final String? avatarUrl;

  UploaderInfo({
    required this.id,
    required this.email,
    required this.fullName,
    required this.userRole,
    required this.isVerified,
    this.avatarUrl,
  });

  factory UploaderInfo.fromJson(Map<String, dynamic> json) {
    return UploaderInfo(
      id: json['id'],
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      userRole: json['user_role'] ?? '',
      isVerified: json['is_verified'] ?? false,
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'user_role': userRole,
      'is_verified': isVerified,
      'avatar_url': avatarUrl,
    };
  }
}

// Topic Materials Response model (matches the actual API structure)
class TopicMaterialsData {
  final int topicId;
  final String topicName;
  final String topicNameSw;
  final Map<String, dynamic> appliedFilters;
  final Map<String, dynamic> filterOptions;
  final int materialsCount;
  final int totalMaterialsCount;
  final int directMaterialsCount;
  final int subtopicMaterialsCount;
  final List<LearningMaterial> materials;

  TopicMaterialsData({
    required this.topicId,
    required this.topicName,
    required this.topicNameSw,
    required this.appliedFilters,
    required this.filterOptions,
    required this.materialsCount,
    required this.totalMaterialsCount,
    required this.directMaterialsCount,
    required this.subtopicMaterialsCount,
    required this.materials,
  });

  factory TopicMaterialsData.fromJson(Map<String, dynamic> json) {
    return TopicMaterialsData(
      topicId: json['topic_id'] ?? 0,
      topicName: json['topic_name'] ?? '',
      topicNameSw: json['topic_name_sw'] ?? '',
      appliedFilters: json['applied_filters'] ?? {},
      filterOptions: json['filter_options'] ?? {},
      materialsCount: json['materials_count'] ?? 0,
      totalMaterialsCount: json['total_materials_count'] ?? 0,
      directMaterialsCount: json['direct_materials_count'] ?? 0,
      subtopicMaterialsCount: json['subtopic_materials_count'] ?? 0,
      materials: (json['materials'] as List?)
              ?.map((material) => LearningMaterial.fromJson(material))
              .toList() ??
          [],
    );
  }
}

class MaterialsResponse {
  final int count;
  final String? next;
  final String? previous;
  final TopicMaterialsData results;

  MaterialsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory MaterialsResponse.fromJson(Map<String, dynamic> json) {
    return MaterialsResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: TopicMaterialsData.fromJson(json['results']),
    );
  }
}
