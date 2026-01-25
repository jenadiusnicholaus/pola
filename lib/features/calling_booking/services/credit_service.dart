import 'package:dio/dio.dart';
import '../../../config/dio_config.dart';
import '../models/consultant_models.dart';
import 'package:flutter/foundation.dart';

class CreditService {
  final Dio _dio = DioConfig.instance;

  /// Get available credit bundles using check-credits API
  /// This API returns bundles even when user has no credits (402 status)
  Future<List<CreditBundle>> getAvailableBundles() async {
    try {
      debugPrint('📦 Fetching credit bundles via check-credits...');

      // Use correct check-credits endpoint
      final response = await _dio.post(
        '/api/v1/subscriptions/call-history/check-credits/',
        data: {'consultant_id': 1}, // Use a placeholder consultant ID
        options: Options(
          validateStatus: (status) => status != null && status < 500, // Accept 402
        ),
      );

      debugPrint('📦 Bundles Response: ${response.statusCode}');

      // Both 200 and 402 contain available_bundles
      if (response.statusCode == 200 || response.statusCode == 402) {
        final data = response.data as Map<String, dynamic>;
        
        // Get bundles from available_bundles in check-credits response
        final bundlesList = data['available_bundles'] as List? ?? [];
        
        final bundles = bundlesList
            .map((item) => CreditBundle.fromJson(item))
            .toList();

        debugPrint('✅ Loaded ${bundles.length} credit bundles');
        return bundles;
      }

      throw Exception('Failed to load bundles');
    } catch (e) {
      debugPrint('❌ Error fetching bundles: $e');
      rethrow;
    }
  }

  /// Get current user's credit balance
  Future<Map<String, dynamic>> getUserCredits() async {
    try {
      debugPrint('💰 Fetching user credits...');

      // Use correct my-credits endpoint
      final response = await _dio.get(
        '/api/v1/subscriptions/call-history/my-credits/',
      );

      debugPrint('💰 Credits Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        final totalMinutes = data['total_minutes'] ?? 0;
        debugPrint('✅ User has $totalMinutes minutes');

        return {
          'totalMinutes': totalMinutes,
          'expiringMinutes': data['expiring_soon'] ?? 0,
          'credits': (data['active_credits'] as List?)
                  ?.map((item) => CreditEntry.fromJson(item))
                  .toList() ??
              [],
        };
      }

      throw Exception('Failed to load credits');
    } catch (e) {
      debugPrint('❌ Error fetching credits: $e');
      rethrow;
    }
  }

  /// Purchase credit bundle using unified payment API
  Future<Map<String, dynamic>> purchaseBundle({
    required int bundleId,
    required String phoneNumber,
    required String provider,
  }) async {
    try {
      debugPrint('💳 Initiating credit purchase...');
      debugPrint('   Bundle ID: $bundleId');
      debugPrint('   Phone: $phoneNumber');
      debugPrint('   Provider: $provider');

      final response = await _dio.post(
        '/api/v1/subscriptions/unified-payments/initiate/',
        data: {
          'payment_category': 'call_credit',
          'item_id': bundleId,
          'phone_number': phoneNumber,
          'payment_method': 'mobile_money',
          'provider': provider,
        },
      );

      debugPrint('💳 Payment Response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ Payment initiated successfully');
        debugPrint('   Transaction ID: ${data['transaction']?['id']}');

        return {
          'success': true,
          'transactionId': data['transaction']?['id'],
          'message': data['message'] ?? 'Payment initiated',
          'nextSteps': (data['next_steps'] as List?)?.cast<String>() ?? [],
          'transaction': data['transaction'],
        };
      }

      throw Exception('Payment failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error initiating payment: $e');
      return {
        'success': false,
        'message': 'Failed to initiate payment: $e',
      };
    }
  }

  /// Check payment status
  Future<Map<String, dynamic>> checkPaymentStatus(String transactionId) async {
    try {
      debugPrint('🔍 Checking payment status for: $transactionId');

      final response = await _dio.get(
        '/api/v1/subscriptions/unified-payments/$transactionId/status/',
      );

      debugPrint('🔍 Payment Status Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final payment = data['payment'] as Map<String, dynamic>;

        final status = payment['status'] ?? 'pending';
        debugPrint('📊 Payment Status: $status');

        return {
          'status': status,
          'payment': payment,
          'credits_added': payment['credits_added'],
          'minutes_added': payment['minutes_added'],
        };
      }

      throw Exception('Failed to check status');
    } catch (e) {
      debugPrint('❌ Error checking payment status: $e');
      rethrow;
    }
  }

  /// Get credit transaction history
  Future<List<Map<String, dynamic>>> getCreditHistory() async {
    try {
      debugPrint('📜 Fetching credit history...');

      final response = await _dio.get(
        '/api/v1/subscriptions/credit-transactions/',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final transactions =
            (data['transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        debugPrint('✅ Loaded ${transactions.length} transactions');
        return transactions;
      }

      throw Exception('Failed to load history');
    } catch (e) {
      debugPrint('❌ Error fetching history: $e');
      rethrow;
    }
  }
}

/// Credit entry model
class CreditEntry {
  final int id;
  final int minutesRemaining;
  final DateTime expiryDate;
  final String source;
  final int daysUntilExpiry;

  CreditEntry({
    required this.id,
    required this.minutesRemaining,
    required this.expiryDate,
    required this.source,
    required this.daysUntilExpiry,
  });

  factory CreditEntry.fromJson(Map<String, dynamic> json) {
    return CreditEntry(
      id: json['id'] ?? 0,
      minutesRemaining: json['minutes_remaining'] ?? 0,
      expiryDate: DateTime.parse(json['expiry_date']),
      source: json['source'] ?? '',
      daysUntilExpiry: json['days_until_expiry'] ?? 0,
    );
  }

  bool get isExpiringSoon => daysUntilExpiry <= 7;
}
