// Base API Response Model
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;
  final String? timestamp;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
    this.timestamp,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      statusCode: json['statusCode'] ?? json['status_code'],
      timestamp: json['timestamp'],
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'statusCode': statusCode,
      'timestamp': timestamp,
      'errors': errors,
    };
  }

  // Helper methods
  bool get isSuccess => success == true;
  bool get hasError => !isSuccess;
  bool get hasData => data != null;
}

// Pagination Model
class PaginatedResponse<T> {
  final List<T> data;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    final dataList = json['data'] as List? ?? [];

    return PaginatedResponse<T>(
      data: dataList.map((item) => fromJsonT(item)).toList(),
      currentPage: json['current_page'] ?? json['page'] ?? 1,
      totalPages: json['total_pages'] ?? json['last_page'] ?? 1,
      totalItems: json['total_items'] ?? json['total'] ?? 0,
      itemsPerPage: json['items_per_page'] ?? json['per_page'] ?? 10,
      hasNextPage: json['has_next_page'] ?? json['next_page_url'] != null,
      hasPreviousPage:
          json['has_previous_page'] ?? json['prev_page_url'] != null,
    );
  }
}

// Authentication Models
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final UserModel user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      tokenType: json['token_type'] ?? 'Bearer',
      expiresIn: json['expires_in'] ?? 3600,
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'user': user.toJson(),
    };
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profilePicture;
  final DateTime? emailVerifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserPreferences? preferences;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profilePicture,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
    this.preferences,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      profilePicture: json['profile_picture'],
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'])
          : null,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
      preferences: json['preferences'] != null
          ? UserPreferences.fromJson(json['preferences'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_picture': profilePicture,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'preferences': preferences?.toJson(),
    };
  }
}

class UserPreferences {
  final String language;
  final bool darkMode;
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool pushNotifications;

  UserPreferences({
    required this.language,
    required this.darkMode,
    required this.notificationsEnabled,
    required this.emailNotifications,
    required this.pushNotifications,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      language: json['language'] ?? 'en',
      darkMode: json['dark_mode'] ?? false,
      notificationsEnabled: json['notifications_enabled'] ?? true,
      emailNotifications: json['email_notifications'] ?? true,
      pushNotifications: json['push_notifications'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'dark_mode': darkMode,
      'notifications_enabled': notificationsEnabled,
      'email_notifications': emailNotifications,
      'push_notifications': pushNotifications,
    };
  }
}

// Legal Service Models
class DocumentScanResult {
  final String id;
  final String documentType;
  final String extractedText;
  final Map<String, dynamic> metadata;
  final List<String> keyFindings;
  final double confidenceScore;
  final DateTime processedAt;
  final String status;

  DocumentScanResult({
    required this.id,
    required this.documentType,
    required this.extractedText,
    required this.metadata,
    required this.keyFindings,
    required this.confidenceScore,
    required this.processedAt,
    required this.status,
  });

  factory DocumentScanResult.fromJson(Map<String, dynamic> json) {
    return DocumentScanResult(
      id: json['id']?.toString() ?? '',
      documentType: json['document_type'] ?? '',
      extractedText: json['extracted_text'] ?? '',
      metadata: json['metadata'] ?? {},
      keyFindings: List<String>.from(json['key_findings'] ?? []),
      confidenceScore: (json['confidence_score'] ?? 0.0).toDouble(),
      processedAt: DateTime.parse(
          json['processed_at'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_type': documentType,
      'extracted_text': extractedText,
      'metadata': metadata,
      'key_findings': keyFindings,
      'confidence_score': confidenceScore,
      'processed_at': processedAt.toIso8601String(),
      'status': status,
    };
  }
}

class LegalResearchResult {
  final String id;
  final String query;
  final List<LegalCase> cases;
  final List<LegalStatute> statutes;
  final List<LegalArticle> articles;
  final String summary;
  final DateTime searchedAt;

  LegalResearchResult({
    required this.id,
    required this.query,
    required this.cases,
    required this.statutes,
    required this.articles,
    required this.summary,
    required this.searchedAt,
  });

  factory LegalResearchResult.fromJson(Map<String, dynamic> json) {
    return LegalResearchResult(
      id: json['id']?.toString() ?? '',
      query: json['query'] ?? '',
      cases: (json['cases'] as List? ?? [])
          .map((caseJson) => LegalCase.fromJson(caseJson))
          .toList(),
      statutes: (json['statutes'] as List? ?? [])
          .map((statute) => LegalStatute.fromJson(statute))
          .toList(),
      articles: (json['articles'] as List? ?? [])
          .map((article) => LegalArticle.fromJson(article))
          .toList(),
      summary: json['summary'] ?? '',
      searchedAt: DateTime.parse(
          json['searched_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'query': query,
      'cases': cases.map((legalCase) => legalCase.toJson()).toList(),
      'statutes': statutes.map((statute) => statute.toJson()).toList(),
      'articles': articles.map((article) => article.toJson()).toList(),
      'summary': summary,
      'searched_at': searchedAt.toIso8601String(),
    };
  }
}

class LegalCase {
  final String id;
  final String title;
  final String citation;
  final String court;
  final DateTime decidedDate;
  final String summary;
  final String relevanceScore;
  final String url;

  LegalCase({
    required this.id,
    required this.title,
    required this.citation,
    required this.court,
    required this.decidedDate,
    required this.summary,
    required this.relevanceScore,
    required this.url,
  });

  factory LegalCase.fromJson(Map<String, dynamic> json) {
    return LegalCase(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      citation: json['citation'] ?? '',
      court: json['court'] ?? '',
      decidedDate: DateTime.parse(
          json['decided_date'] ?? DateTime.now().toIso8601String()),
      summary: json['summary'] ?? '',
      relevanceScore: json['relevance_score']?.toString() ?? '0',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'citation': citation,
      'court': court,
      'decided_date': decidedDate.toIso8601String(),
      'summary': summary,
      'relevance_score': relevanceScore,
      'url': url,
    };
  }
}

class LegalStatute {
  final String id;
  final String title;
  final String section;
  final String jurisdiction;
  final String content;
  final String url;

  LegalStatute({
    required this.id,
    required this.title,
    required this.section,
    required this.jurisdiction,
    required this.content,
    required this.url,
  });

  factory LegalStatute.fromJson(Map<String, dynamic> json) {
    return LegalStatute(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      section: json['section'] ?? '',
      jurisdiction: json['jurisdiction'] ?? '',
      content: json['content'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'section': section,
      'jurisdiction': jurisdiction,
      'content': content,
      'url': url,
    };
  }
}

class LegalArticle {
  final String id;
  final String title;
  final String author;
  final String journal;
  final DateTime publishedDate;
  final String summary;
  final String url;

  LegalArticle({
    required this.id,
    required this.title,
    required this.author,
    required this.journal,
    required this.publishedDate,
    required this.summary,
    required this.url,
  });

  factory LegalArticle.fromJson(Map<String, dynamic> json) {
    return LegalArticle(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      journal: json['journal'] ?? '',
      publishedDate: DateTime.parse(
          json['published_date'] ?? DateTime.now().toIso8601String()),
      summary: json['summary'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'journal': journal,
      'published_date': publishedDate.toIso8601String(),
      'summary': summary,
      'url': url,
    };
  }
}

class LegalTemplate {
  final String id;
  final String name;
  final String category;
  final String description;
  final String content;
  final List<String> fields;
  final bool isPremium;
  final double? price;
  final DateTime createdAt;

  LegalTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.content,
    required this.fields,
    required this.isPremium,
    this.price,
    required this.createdAt,
  });

  factory LegalTemplate.fromJson(Map<String, dynamic> json) {
    return LegalTemplate(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      content: json['content'] ?? '',
      fields: List<String>.from(json['fields'] ?? []),
      isPremium: json['is_premium'] ?? false,
      price: json['price']?.toDouble(),
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'content': content,
      'fields': fields,
      'is_premium': isPremium,
      'price': price,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Consultation {
  final String id;
  final String lawyerId;
  final String lawyerName;
  final String lawyerSpecialty;
  final DateTime scheduledAt;
  final String consultationType;
  final String status;
  final String? description;
  final double? fee;
  final DateTime createdAt;

  Consultation({
    required this.id,
    required this.lawyerId,
    required this.lawyerName,
    required this.lawyerSpecialty,
    required this.scheduledAt,
    required this.consultationType,
    required this.status,
    this.description,
    this.fee,
    required this.createdAt,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      id: json['id']?.toString() ?? '',
      lawyerId: json['lawyer_id']?.toString() ?? '',
      lawyerName: json['lawyer_name'] ?? '',
      lawyerSpecialty: json['lawyer_specialty'] ?? '',
      scheduledAt: DateTime.parse(
          json['scheduled_at'] ?? DateTime.now().toIso8601String()),
      consultationType: json['consultation_type'] ?? '',
      status: json['status'] ?? 'pending',
      description: json['description'],
      fee: json['fee']?.toDouble(),
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lawyer_id': lawyerId,
      'lawyer_name': lawyerName,
      'lawyer_specialty': lawyerSpecialty,
      'scheduled_at': scheduledAt.toIso8601String(),
      'consultation_type': consultationType,
      'status': status,
      'description': description,
      'fee': fee,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Payment Models
class PaymentResult {
  final String id;
  final double amount;
  final String currency;
  final String status;
  final String paymentMethod;
  final String? transactionId;
  final String? description;
  final DateTime createdAt;

  PaymentResult({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    this.transactionId,
    this.description,
    required this.createdAt,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'pending',
      paymentMethod: json['payment_method'] ?? '',
      transactionId: json['transaction_id'],
      description: json['description'],
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'status': status,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Notification Models
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'general',
      data: json['data'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
