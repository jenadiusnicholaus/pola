class DocumentTemplate {
  final int id;
  final String name;
  final String nameSw;
  final String description;
  final String descriptionSw;
  final String category;
  final bool isFree;
  final String price;
  final String icon;
  final int usageCount;

  DocumentTemplate({
    required this.id,
    required this.name,
    required this.nameSw,
    required this.description,
    required this.descriptionSw,
    required this.category,
    required this.isFree,
    required this.price,
    required this.icon,
    required this.usageCount,
  });

  factory DocumentTemplate.fromJson(Map<String, dynamic> json) {
    return DocumentTemplate(
      id: json['id'] as int,
      name: json['name'] as String,
      nameSw: json['name_sw'] as String,
      description: json['description'] as String,
      descriptionSw: json['description_sw'] as String? ?? '',
      category: json['category'] as String,
      isFree: json['is_free'] as bool? ?? true,
      price: json['price'] as String? ?? '0.00',
      icon: json['icon'] as String? ?? '',
      usageCount: json['usage_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_sw': nameSw,
      'description': description,
      'description_sw': descriptionSw,
      'category': category,
      'is_free': isFree,
      'price': price,
      'icon': icon,
      'usage_count': usageCount,
    };
  }

  String getCategoryIcon() {
    if (icon.isNotEmpty) return icon;
    switch (category.toLowerCase()) {
      case 'employment':
        return '💼';
      case 'resignation':
        return '📝';
      case 'legal_notice':
        return '📋';
      case 'questionnaire':
        return '📊';
      default:
        return '📄';
    }
  }

  String getCategoryLabel() {
    return category.replaceAll('_', ' ').toUpperCase();
  }
}
