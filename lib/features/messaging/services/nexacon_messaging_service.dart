import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nexacon_sdk/nexacon_sdk.dart';
import 'package:get/get.dart';
import '../../../config/nexacon_config.dart';
import '../../../services/token_storage_service.dart';

/// Service wrapper for Nexacon SDK messaging functionality
/// Handles real-time messaging, contact management, and message history
class NexaconMessagingService extends GetxService {
  NexaconSDK? _sdk;
  MessagingManager? _messagingManager;
  final TokenStorageService _tokenStorage = Get.find<TokenStorageService>();

  // Broadcast stream controllers — emit one Map per event (not a full List)
  final _messageCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _typingCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _readReceiptCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _deliveryReceiptCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final _presenceCtrl = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageCtrl.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingCtrl.stream;
  Stream<Map<String, dynamic>> get readReceiptStream => _readReceiptCtrl.stream;
  Stream<Map<String, dynamic>> get deliveryReceiptStream =>
      _deliveryReceiptCtrl.stream;
  Stream<Map<String, dynamic>> get presenceStream => _presenceCtrl.stream;

  // Connection state
  final isConnected = false.obs;

  /// Initialize the messaging service with Nexacon SDK
  Future<void> initialize(NexaconSDK? sdk) async {
    if (sdk != null) {
      _sdk = sdk;
    } else {
      // Create SDK instance if not provided
      _sdk = NexaconSDK(
        apiKey: NexaconConfig.apiKey,
        secretKey: NexaconConfig.secretKey,
      );
    }

    final client = _sdk?.client;
    if (client == null) {
      throw Exception('NexaconSDK not initialized. Call initialize() first.');
    }

    _messagingManager = client.createMessagingManager();

    // Listen to real-time streams
    _messagingManager?.messageStream.listen((message) {
      _messageCtrl.add(message);
    });

    _messagingManager?.typingStream.listen((typing) {
      _typingCtrl.add(typing);
    });

    _messagingManager?.readReceiptStream.listen((receipt) {
      _readReceiptCtrl.add(receipt);
    });

    _messagingManager?.deliveryReceiptStream.listen((receipt) {
      _deliveryReceiptCtrl.add(receipt);
    });

    _messagingManager?.presenceStream.listen((presence) {
      _presenceCtrl.add(presence);
    });

    isConnected.value = true;
    print('✅ NexaconMessagingService initialized');
  }

  /// Initialize SDK connection for messaging
  /// This establishes the NX connection required for real-time chat
  Future<void> initializeConnection() async {
    print('🚀 initializeConnection() called');

    if (_sdk == null) {
      print('📦 Creating new SDK instance');
      _sdk = NexaconSDK(
        apiKey: NexaconConfig.apiKey,
        secretKey: NexaconConfig.secretKey,
      );
    } else {
      print('📦 SDK instance already exists');
    }

    // Get user's phone number for NX ID
    final userData = _tokenStorage.userData;
    print('👤 User data: ${userData != null ? "found" : "null"}');
    print('👤 User data keys: ${userData?.keys.toList()}');
    print('👤 Full user data: $userData');

    // Try multiple possible phone number fields
    String? phone = userData?['phone_number'] as String?;
    if (phone == null || phone.isEmpty) {
      phone = userData?['phone'] as String?;
    }
    if (phone == null || phone.isEmpty) {
      phone = userData?['mobile'] as String?;
    }
    if (phone == null || phone.isEmpty) {
      phone = userData?['contact_number'] as String?;
    }
    if (phone == null || phone.isEmpty) {
      phone = userData?['phoneNumber'] as String?;
    }
    if (phone == null || phone.isEmpty) {
      phone = userData?['username'] as String?;
    }
    // Check nested contact object
    if (phone == null || phone.isEmpty) {
      final contact = userData?['contact'] as Map<String, dynamic>?;
      phone = contact?['phone_number'] as String?;
    }

    print('📱 Phone: $phone');

    if (phone == null || phone.isEmpty) {
      print('❌ User phone number not found in any field');
      throw Exception(
          'User phone number not found. Cannot initialize messaging.');
    }

    // Format phone number with country code
    final formattedPhone = _formatPhoneNumberWithCountryCode(phone);
    print('📡 Initializing messaging connection with phone: $formattedPhone');

    try {
      // Check if we have stored NX token data
      final hasNxData = await _tokenStorage.hasNxTokenData();
      print('🔐 Has stored NX data: $hasNxData');

      if (hasNxData) {
        // Use stored credentials to avoid API call
        final nxtoken = await _tokenStorage.getNxToken();
        final nxid = await _tokenStorage.getNxJid();
        String? wsUrl = await _tokenStorage.getNxWsUrl();

        print('🔑 Stored token: ${nxtoken?.substring(0, 20)}...');
        print('🆔 Stored JID: $nxid');
        print('🌐 Stored WS URL: $wsUrl');

        if (wsUrl != null && wsUrl.startsWith('https://')) {
          wsUrl = wsUrl.replaceFirst('https://', 'wss://');
        }

        print('✅ Using stored NX credentials');
        await _sdk!.initialize(
          username: formattedPhone,
          nxtoken: nxtoken,
          nxid: nxid,
          wsUrl: wsUrl,
        );
      } else {
        // Let SDK fetch credentials and store them after initialization
        print('🔐 No stored NX credentials, letting SDK fetch from API...');

        // Initialize SDK without credentials - it will fetch them and return them
        final credentials = await _sdk!.initialize(username: formattedPhone);

        // Store the credentials returned by SDK
        await _tokenStorage.storeNxTokenData(
          token: credentials['token'],
          jid: credentials['jid'],
          wsUrl: credentials['nxws'],
        );
        print('✅ NX credentials stored for future use');
      }

      print('✅ Messaging SDK initialized successfully');
      print('📦 SDK client: ${_sdk?.client != null ? "exists" : "null"}');

      // Use the NX manager directly from SDK (already connected)
      final nxManager = _sdk!.xmppManager;
      print('🔌 NX Manager: ${nxManager != null ? "found" : "null"}');

      if (nxManager == null) {
        throw Exception('NX manager not available after SDK initialization');
      }

      // Create MessagingManager from nxManager for sending messages
      _messagingManager = MessagingManager(nxManager);
      print('📨 MessagingManager created');
      print(
          '📨 SDK client after init: ${_sdk?.client != null ? "exists" : "null"}');

      // Set up streams from NX manager
      nxManager.messageStream.listen((message) {
        print('📩 Message received from NX stream');
        _messageCtrl.add(message);
      });

      nxManager.presenceStream.listen((presence) {
        print('👤 Presence received from NX stream');
        _presenceCtrl.add(presence);
      });

      nxManager.deliveryReceiptStream.listen((receipt) {
        print('📬 Delivery receipt received from NX stream');
        _deliveryReceiptCtrl.add(receipt);
      });

      isConnected.value = true;
      print('✅ Messaging streams connected to NX manager');
      print('✅ isConnected: ${isConnected.value}');
    } catch (e) {
      print('❌ Failed to initialize messaging connection: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  String _formatPhoneNumberWithCountryCode(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    String formatted;

    if (digits.startsWith('0')) {
      formatted = '+255${digits.substring(1)}';
    } else if (digits.startsWith('255')) {
      formatted = '+$digits';
    } else if (digits.length == 9) {
      // Local 9-digit number without country code or leading 0
      formatted = '+255$digits';
    } else {
      formatted = digits; // assume already international
    }

    return '$formatted@nxservice.quantumvision-tech.com';
  }

  /// Send a direct message to a user
  Future<Map<String, dynamic>> sendMessage({
    required String to,
    required String message,
    String messageType = 'chat',
  }) async {
    final client = _sdk?.client;
    if (client == null) {
      throw Exception('Messaging service not initialized');
    }

    return await client.messaging.send(
      to: to,
      message: message,
      messageType: messageType,
    );
  }

  /// Send a message using MessagingManager (real-time)
  void sendRealTimeMessage({
    required String to,
    required String message,
  }) {
    print('📤 sendRealTimeMessage called');
    print('📤 To: $to');
    print('📤 Message: $message');
    print(
        '📤 MessagingManager: ${_messagingManager != null ? "initialized" : "null"}');
    print('📤 isConnected: ${isConnected.value}');

    if (_messagingManager == null) {
      print('❌ MessagingManager not initialized');
      throw Exception('MessagingManager not initialized');
    }

    print('📤 Sending message via MessagingManager...');
    _messagingManager!.sendMessage(to: to, message: message);
    print('✅ Message sent');
  }

  /// Send typing indicator
  void sendTypingIndicator(String to, {required bool isTyping}) {
    _messagingManager?.sendTypingIndicator(to, isTyping: isTyping);
  }

  /// Send read receipt
  void sendReadReceipt(String to, String messageId) {
    _messagingManager?.sendReadReceipt(to, messageId);
  }

  /// Get contact list
  Future<List<Map<String, dynamic>>> getContacts() async {
    print('📨 getContacts called');
    print('📨 _sdk: ${_sdk != null ? "exists" : "null"}');
    print('📨 _sdk.client: ${_sdk?.client != null ? "exists" : "null"}');

    final client = _sdk?.client;
    if (client == null) {
      print('❌ SDK client is null - cannot get contacts');
      throw Exception('Messaging service not initialized');
    }

    print('📨 Calling client.messaging.getContacts...');
    try {
      final contacts = await client.messaging.getContacts();
      print('✅ getContacts returned ${contacts.length} contacts');
      for (var c in contacts) {
        print('   - Contact: $c');
      }
      return contacts;
    } catch (e) {
      print('❌ getContacts failed: $e');
      rethrow;
    }
  }

  /// Add a contact
  Future<Map<String, dynamic>> addContact(String nxid) async {
    print('📨 addContact called with nxid: $nxid');
    print('📨 _sdk: ${_sdk != null ? "exists" : "null"}');
    print('📨 _sdk.client: ${_sdk?.client != null ? "exists" : "null"}');

    final client = _sdk?.client;
    if (client == null) {
      print('❌ SDK client is null - cannot add contact');
      throw Exception('Messaging service not initialized - client is null');
    }

    print('📨 Calling client.messaging.addContact...');
    try {
      final result = await client.messaging.addContact(nxid);
      print('✅ addContact result: $result');
      return result;
    } catch (e) {
      print('❌ addContact failed: $e');
      rethrow;
    }
  }

  /// Remove a contact
  Future<Map<String, dynamic>> removeContact(String nxid) async {
    final client = _sdk?.client;
    if (client == null) {
      throw Exception('Messaging service not initialized');
    }

    return await client.messaging.removeContact(nxid);
  }

  /// Get message history
  Future<Map<String, dynamic>> getMessageHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? sender,
    String? messageType,
    int page = 1,
    int pageSize = 20,
  }) async {
    final client = _sdk?.client;
    if (client == null) {
      throw Exception('Messaging service not initialized');
    }

    return await client.messaging.getMessageHistory(
      startDate: startDate,
      endDate: endDate,
      sender: sender,
      messageType: messageType,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Get message history for a specific conversation
  Future<List<Map<String, dynamic>>> getConversationHistory(
    String contactNxid, {
    int pageSize = 50,
  }) async {
    final history = await getMessageHistory(
      sender: contactNxid,
      messageType: 'chat',
      pageSize: pageSize,
    );

    debugPrint(
        '📨 getConversationHistory response type: ${history.runtimeType}');
    debugPrint('📨 getConversationHistory response: $history');

    // Handle different response formats from SDK
    if (history is List) {
      return (history as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }

    // If it's an int (count), return empty list (no messages)
    if (history is int) {
      debugPrint('📨 Response is int (count): $history - returning empty list');
      return [];
    }

    // If it's a Map, look for messages field
    final messages = history['messages'];
    if (messages is List) {
      return messages.map((e) => e as Map<String, dynamic>).toList();
    }

    debugPrint('📨 Unknown response format, returning empty list');
    return [];
  }

  @override
  void onClose() {
    _messagingManager?.dispose();
    _messageCtrl.close();
    _typingCtrl.close();
    _readReceiptCtrl.close();
    _deliveryReceiptCtrl.close();
    _presenceCtrl.close();
    super.onClose();
  }
}
