class StatuteCategory {
  final int id;
  final String name;
  final String nameSw;
  final String slug;
  final String description;
  final String descriptionSw;
  final int statutesCount;
  final bool isActive;

  StatuteCategory({
    required this.id,
    required this.name,
    required this.nameSw,
    required this.slug,
    required this.description,
    required this.descriptionSw,
    required this.statutesCount,
    required this.isActive,
  });

  factory StatuteCategory.fromJson(Map<String, dynamic> json) {
    return StatuteCategory(
      id: json['id'] as int,
      name: (json['name'] ?? '').toString(),
      nameSw: (json['name_sw'] ?? json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      descriptionSw: (json['description_sw'] ?? json['description'] ?? '').toString(),
      statutesCount: json['statutes_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  String localizedName({required bool swahili}) => swahili ? nameSw : name;
  String localizedDescription({required bool swahili}) =>
      swahili ? descriptionSw : description;
}

class StatuteLaw {
  final int id;
  final String title;
  final String titleSw;
  final String description;
  final String descriptionSw;
  final String fileUrl;
  final double fileSizeMb;
  final List<StatuteCategory> categories;
  final bool isActive;

  StatuteLaw({
    required this.id,
    required this.title,
    required this.titleSw,
    required this.description,
    required this.descriptionSw,
    required this.fileUrl,
    required this.fileSizeMb,
    required this.categories,
    required this.isActive,
  });

  factory StatuteLaw.fromJson(Map<String, dynamic> json) {
    final cats = <StatuteCategory>[];
    final rawCats = json['categories'];
    if (rawCats is List) {
      for (final c in rawCats) {
        if (c is Map<String, dynamic>) {
          cats.add(StatuteCategory.fromJson({
            ...c,
            'description': '',
            'description_sw': '',
            'statutes_count': 0,
            'is_active': true,
          }));
        }
      }
    }
    return StatuteLaw(
      id: json['id'] as int,
      title: (json['title'] ?? '').toString(),
      titleSw: (json['title_sw'] ?? json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      descriptionSw:
          (json['description_sw'] ?? json['description'] ?? '').toString(),
      fileUrl: (json['file_url'] ?? json['file'] ?? '').toString(),
      fileSizeMb: (json['file_size_mb'] is num)
          ? (json['file_size_mb'] as num).toDouble()
          : 0,
      categories: cats,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  String localizedTitle({required bool swahili}) => swahili ? titleSw : title;
  String localizedDescription({required bool swahili}) =>
      swahili ? descriptionSw : description;
}
