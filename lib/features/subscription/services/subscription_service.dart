import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../services/api_service.dart';
import '../../../config/environment_config.dart';
import '../../../features/profile/models/profile_models.dart';
import '../models/subscription_models.dart';

class SubscriptionService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  /// Get available subscription plans
  Future<List<SubscriptionPlan>> getPlans() async {
    try {
      debugPrint('📋 Fetching subscription plans...');
      final response = await _apiService.get(
        EnvironmentConfig.subscriptionPlansUrl,
      );

      debugPrint('📋 Plans Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> plansData;

        // Handle both paginated and direct list responses
        if (data is Map && data.containsKey('results')) {
          plansData = data['results'];
        } else if (data is List) {
          plansData = data;
        } else {
          throw Exception('Unexpected response format');
        }

        final plans =
            plansData.map((json) => SubscriptionPlan.fromJson(json)).toList();

        debugPrint('✅ Loaded ${plans.length} subscription plans');
        return plans;
      }

      throw Exception('Failed to load plans: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error fetching subscription plans: $e');
      rethrow;
    }
  }

  /// Subscribe to a plan using unified payment API
  Future<SubscriptionResult> subscribe({
    required int planId,
    required String phoneNumber,
    required String paymentMethod,
  }) async {
    try {
      debugPrint('💳 Subscribing to plan $planId...');
      debugPrint('   Phone: $phoneNumber');
      debugPrint('   Provider: $paymentMethod');

      // Use a longer timeout for payment requests (5 minutes)
      // Payment APIs may take longer due to external provider communication
      final response = await _apiService.post(
        '/api/v1/subscriptions/unified-payments/initiate/',
        data: {
          'payment_category': 'subscription',
          'item_id': planId,
          'phone_number': phoneNumber,
          'payment_method': 'mobile_money',
          'provider': paymentMethod,
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 5),
        ),
      );

      debugPrint('💳 Payment Response: ${response.statusCode}');
      debugPrint('💳 Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        // Handle different response formats from backend
        // Backend may return transactionId directly or nested in transaction object
        String? transactionId = data['transactionId']?.toString() ??
            data['transaction_id']?.toString() ??
            data['transaction']?['id']?.toString();

        debugPrint('💳 Parsed transactionId: $transactionId');

        return SubscriptionResult(
          success: data['success'] ?? true,
          message: data['message'] ?? 'Payment initiated',
          transactionId: transactionId,
        );
      }

      throw Exception('Payment failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error initiating payment: $e');
      return SubscriptionResult(
        success: false,
        message: 'Failed to initiate payment: $e',
      );
    }
  }

  /// Check payment status using unified payment API
  Future<PaymentStatus> checkPaymentStatus(String transactionId) async {
    try {
      debugPrint('🔍 Checking payment status for: $transactionId');

      final response = await _apiService.get(
        '/api/v1/subscriptions/unified-payments/$transactionId/status/',
      );

      debugPrint('🔍 Payment Status Response: ${response.statusCode}');
      debugPrint('🔍 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data == null) {
          return PaymentStatus(
            status: 'error',
            message: 'No data received from server',
          );
        }

        // Backend may return payment data at top level or nested under 'payment'
        final payment =
            data['payment'] is Map<String, dynamic> ? data['payment'] : data;

        if (payment == null || payment is! Map<String, dynamic>) {
          return PaymentStatus(
            status: 'error',
            message: 'Invalid payment data received',
          );
        }

        final rawStatus = (payment['status'] as String?)?.toLowerCase() ??
            (data['status'] as String?)?.toLowerCase() ??
            'unknown';
        final isFulfilled =
            payment['is_fulfilled'] == true || data['is_fulfilled'] == true;
        final status =
            (rawStatus == 'completed' || rawStatus == 'success' || isFulfilled)
                ? 'completed'
                : (rawStatus == 'failed' || rawStatus == 'cancelled')
                    ? 'failed'
                    : rawStatus;
        final message = payment['message'] ?? data['message'] ?? '';
        final transactionId = payment['id']?.toString() ??
            payment['transaction_id']?.toString() ??
            data['transaction_id']?.toString();

        return PaymentStatus(
          status: status,
          message: message,
          transactionId: transactionId,
        );
      }

      throw Exception('Failed to check payment status: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error checking payment status: $e');
      return PaymentStatus(
        status: 'error',
        message: 'Failed to check payment status: $e',
      );
    }
  }

  /// Check if user can apply for consultation based on subscription
  bool canApplyForConsultation(SubscriptionInfo subscription) {
    // User must have an active subscription
    if (!subscription.isActive) {
      debugPrint('❌ Subscription not active');
      return false;
    }

    // User must have consultation purchase permission
    if (!subscription.permissions.canPurchaseConsultations) {
      debugPrint('❌ No consultation permission');
      return false;
    }

    // Free trial users cannot apply for consultation
    if (subscription.isTrial) {
      debugPrint('❌ Free trial users cannot apply for consultation');
      return false;
    }

    debugPrint('✅ User can apply for consultation');
    return true;
  }

  /// Check if user needs to upgrade
  bool needsUpgrade(SubscriptionInfo subscription) {
    return !canApplyForConsultation(subscription);
  }
}
