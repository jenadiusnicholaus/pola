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

  /// Subscribe to a plan
  Future<SubscriptionResult> subscribe({
    required int planId,
    required String phoneNumber,
    required String paymentMethod,
  }) async {
    try {
      debugPrint('💳 Subscribing to plan $planId...');
      debugPrint('   Phone: $phoneNumber');
      debugPrint('   Payment method: $paymentMethod');

      final response = await _apiService.post(
        EnvironmentConfig.subscriptionSubscribeUrl,
        data: {
          'plan_id': planId,
          'phone_number': phoneNumber,
          'payment_method': paymentMethod,
        },
      );

      debugPrint('💳 Subscribe Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = SubscriptionResult.fromJson(response.data);
        debugPrint('✅ Subscription initiated: ${result.transactionId}');
        return result;
      }

      throw Exception('Subscription failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error subscribing: $e');
      return SubscriptionResult(
        success: false,
        message: 'Failed to initiate subscription: $e',
      );
    }
  }

  /// Check payment status
  Future<PaymentStatus> checkPaymentStatus(String transactionId) async {
    try {
      debugPrint('🔍 Checking payment status for: $transactionId');

      final response = await _apiService.get(
        EnvironmentConfig.subscriptionPaymentStatusUrl,
        queryParameters: {'transaction_id': transactionId},
      );

      debugPrint('🔍 Payment Status Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final status = PaymentStatus.fromJson(response.data);
        debugPrint('   Status: ${status.status}');
        return status;
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
