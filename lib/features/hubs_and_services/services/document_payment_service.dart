import 'package:dio/dio.dart';
import '../../../config/dio_config.dart';
import 'package:flutter/foundation.dart';

class DocumentPaymentService {
  final Dio _dio = DioConfig.instance;

  /// Purchase a document or material
  Future<Map<String, dynamic>> purchaseDocument({
    required int documentId,
    required String phoneNumber,
    required String provider,
    String paymentCategory = 'document', // 'document' or 'material'
  }) async {
    try {
      debugPrint('💰 Initiating document purchase...');
      debugPrint('   Document ID: $documentId');
      debugPrint('   Phone: $phoneNumber');
      debugPrint('   Provider: $provider');

      final response = await _dio.post(
        '/api/v1/subscriptions/unified-payments/initiate/',
        data: {
          'payment_category': paymentCategory,
          'item_id': documentId,
          'phone_number': phoneNumber,
          'payment_method': 'mobile_money',
          'provider': provider,
        },
      );

      debugPrint('💳 Payment Response: ${response.statusCode}');
      debugPrint('💳 Payment Response Data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ Payment initiated successfully');
        
        // Handle both response formats:
        // Format 1: { "transaction": { "id": "..." } }
        // Format 2: { "transactionId": "..." } (AzamPay direct response)
        final transactionId = data['transaction']?['id'] ?? 
                              data['transactionId'] ?? 
                              data['transaction_id'];
        
        debugPrint('   Transaction ID: $transactionId');

        return {
          'success': true,
          'transactionId': transactionId,
          'message': data['message'] ?? 'Payment initiated',
          'nextSteps': (data['next_steps'] as List?)?.cast<String>() ?? [],
          'transaction': data['transaction'] ?? data,
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

        final status =
            (payment['status'] as String?)?.toLowerCase() ?? 'pending';
        debugPrint('📊 Payment Status: $status');

        return {
          'status': status,
          'payment': payment,
          'document_accessible': payment['document_accessible'] ?? false,
          'download_url': payment['download_url'],
        };
      }

      throw Exception('Failed to check status');
    } catch (e) {
      debugPrint('❌ Error checking payment status: $e');
      rethrow;
    }
  }

  /// Get purchased documents
  Future<List<Map<String, dynamic>>> getPurchasedDocuments() async {
    try {
      debugPrint('📚 Fetching purchased documents...');

      final response = await _dio.get(
        '/api/v1/documents/my-documents/?is_purchased=true',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final documents = (data['documents'] as List?)
                ?.map((doc) => doc as Map<String, dynamic>)
                .toList() ??
            [];

        debugPrint('✅ Found ${documents.length} purchased documents');
        return documents;
      }

      return [];
    } catch (e) {
      debugPrint('❌ Error fetching purchased documents: $e');
      return [];
    }
  }

  /// Check if a specific document is purchased
  Future<bool> isDocumentPurchased(int documentId) async {
    try {
      final response = await _dio.get(
        '/api/v1/documents/$documentId/purchase-status/',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['is_purchased'] == true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking purchase status: $e');
      return false;
    }
  }

  /// Download purchased document
  Future<String?> downloadDocument(int documentId) async {
    try {
      debugPrint('⬇️ Downloading document $documentId...');

      final response = await _dio.get(
        '/api/v1/documents/$documentId/download/',
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Document downloaded successfully');
        // Return the download URL or handle file saving
        return '/api/v1/documents/$documentId/download/';
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error downloading document: $e');
      return null;
    }
  }
}
