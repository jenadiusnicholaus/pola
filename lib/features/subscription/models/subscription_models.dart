import 'package:flutter/material.dart';

class SubscriptionPlan {
  final int id;
  final String name;
  final String nameSwahili;
  final String description;
  final String descriptionSwahili;
  final String planType; // 'free_trial', 'monthly', 'annual'
  final double price;
  final String currency;
  final int durationDays;
  final List<String> features;
  final List<String> featuresSwahili;
  final bool isPopular;
  final String? discount; // e.g., "Save 20%"

  // Permissions included in plan
  final bool canAccessLegalLibrary;
  final bool canAskQuestions;
  final int questionsLimit;
  final bool canGenerateDocuments;
  final bool canAccessForum;
  final bool canPurchaseConsultations;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.nameSwahili,
    required this.description,
    required this.descriptionSwahili,
    required this.planType,
    required this.price,
    required this.currency,
    required this.durationDays,
    required this.features,
    required this.featuresSwahili,
    this.isPopular = false,
    this.discount,
    required this.canAccessLegalLibrary,
    required this.canAskQuestions,
    required this.questionsLimit,
    required this.canGenerateDocuments,
    required this.canAccessForum,
    required this.canPurchaseConsultations,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    // Handle price which can be either string or number
    double parsedPrice = 0.0;
    if (json['price'] != null) {
      if (json['price'] is String) {
        parsedPrice = double.tryParse(json['price']) ?? 0.0;
      } else if (json['price'] is num) {
        parsedPrice = (json['price'] as num).toDouble();
      }
    }

    // Extract features from benefits_en or features
    List<String> featuresList = [];
    if (json['benefits_en'] != null && json['benefits_en'] is List) {
      featuresList = List<String>.from(json['benefits_en']);
    } else if (json['features'] != null && json['features'] is List) {
      featuresList = List<String>.from(json['features']);
    }

    // Extract Swahili features from benefits_sw or features_sw
    List<String> featuresSwahiliList = [];
    if (json['benefits_sw'] != null && json['benefits_sw'] is List) {
      featuresSwahiliList = List<String>.from(json['benefits_sw']);
    } else if (json['features_sw'] != null && json['features_sw'] is List) {
      featuresSwahiliList = List<String>.from(json['features_sw']);
    } else if (json['features_swahili'] != null &&
        json['features_swahili'] is List) {
      featuresSwahiliList = List<String>.from(json['features_swahili']);
    }

    return SubscriptionPlan(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      nameSwahili: json['name_sw'] ?? json['name_swahili'] ?? '',
      description: json['description'] ?? '',
      descriptionSwahili:
          json['description_sw'] ?? json['description_swahili'] ?? '',
      planType: json['plan_type'] ?? '',
      price: parsedPrice,
      currency: json['currency'] ?? 'TZS',
      durationDays: json['duration_days'] ?? 0,
      features: featuresList,
      featuresSwahili: featuresSwahiliList,
      isPopular: json['is_popular'] ?? false,
      discount: json['discount'],
      canAccessLegalLibrary: json['full_legal_library_access'] ??
          json['can_access_legal_library'] ??
          false,
      canAskQuestions: json['can_ask_questions'] ?? false,
      questionsLimit:
          json['monthly_questions_limit'] ?? json['questions_limit'] ?? 0,
      canGenerateDocuments: json['can_generate_documents'] ?? false,
      canAccessForum: json['forum_access'] ?? json['can_access_forum'] ?? false,
      canPurchaseConsultations: json['can_purchase_consultations'] ?? false,
    );
  }

  String get displayPrice {
    if (price == 0) return 'Free';
    return '$currency ${price.toStringAsFixed(0)}';
  }

  String get durationDisplay {
    if (planType == 'annual') return '/year';
    if (planType == 'monthly') return '/month';
    return '/$durationDays days';
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final String provider; // 'tigo_pesa', 'airtel_money', 'm_pesa', 'halopesa'
  final IconData icon;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.provider,
    required this.icon,
  });

  static final List<PaymentMethod> availableMethods = [
    PaymentMethod(
      id: 'tigo',
      name: 'Tigo Pesa',
      provider: 'Tigo',
      icon: Icons.phone_android,
    ),
    PaymentMethod(
      id: 'airtel',
      name: 'Airtel Money',
      provider: 'Airtel',
      icon: Icons.phone_iphone,
    ),
    PaymentMethod(
      id: 'mpesa',
      name: 'M-Pesa',
      provider: 'Mpesa',
      icon: Icons.phone,
    ),
    PaymentMethod(
      id: 'halo',
      name: 'Halopesa',
      provider: 'Halopesa',
      icon: Icons.payment,
    ),
    PaymentMethod(
      id: 'azam',
      name: 'Azam Pesa',
      provider: 'Azampesa',
      icon: Icons.account_balance_wallet,
    ),
  ];
}

class SubscriptionResult {
  final bool success;
  final String message;
  final String? transactionId;
  final Map<String, dynamic>? subscriptionData;

  SubscriptionResult({
    required this.success,
    required this.message,
    this.transactionId,
    this.subscriptionData,
  });

  factory SubscriptionResult.fromJson(Map<String, dynamic> json) {
    return SubscriptionResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      transactionId: json['transaction_id'],
      subscriptionData: json['subscription'],
    );
  }
}

class PaymentStatus {
  final String status; // 'pending', 'success', 'failed'
  final String message;
  final Map<String, dynamic>? subscriptionData;
  final String? transactionId;

  PaymentStatus({
    required this.status,
    required this.message,
    this.subscriptionData,
    this.transactionId,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
      status: json['status'] ?? 'pending',
      message: json['message'] ?? '',
      subscriptionData: json['subscription'],
      transactionId: json['transaction_id'],
    );
  }
}
