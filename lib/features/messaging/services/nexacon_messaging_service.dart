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

  // Message streams
  final messageStream = <Map<String, dynamic>>[].obs;
  final typingStream = <Map<String, dynamic>>[].obs;
  final readReceiptStream = <Map<String, dynamic>>[].obs;
  final deliveryReceiptStream = <Map<String, dynamic>>[].obs;
  final presenceStream = <Map<String, dynamic>>[].obs;

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
      messageStream.add(message);
    });

    _messagingManager?.typingStream.listen((typing) {
      typingStream.add(typing);
    });

    _messagingManager?.readReceiptStream.listen((receipt) {
      readReceiptStream.add(receipt);
    });

    _messagingManager?.deliveryReceiptStream.listen((receipt) {
      deliveryReceiptStream.add(receipt);
    });

    _messagingManager?.presenceStream.listen((presence) {
      presenceStream.add(presence);
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
    final phone = userData?['phone_number'] as String?;
    print('📱 Phone: $phone');

    if (phone == null || phone.isEmpty) {
      print('❌ User phone number not found');
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
        // Fetch new credentials first, then pass to SDK
        print('🔐 No stored NX credentials, fetching from API...');

        // Create a temporary client to fetch credentials
        final tempClient = NexaconClient(
          apiKey: NexaconConfig.apiKey,
          secretKey: NexaconConfig.secretKey,
        );

        final nxResponse =
            await tempClient.auth.getNxToken(username: formattedPhone);
        final nxtoken = nxResponse['token'];
        final nxid = nxResponse['jid'];
        String wsUrl = nxResponse['nxws'];

        print('🔑 Fetched token: ${nxtoken.substring(0, 20)}...');
        print('🆔 Fetched JID: $nxid');
        print('🌐 Fetched WS URL: $wsUrl');

        if (wsUrl.startsWith('https://')) {
          wsUrl = wsUrl.replaceFirst('https://', 'wss://');
        }

        // Store credentials for future use
        await _tokenStorage.storeNxTokenData(
          token: nxtoken,
          jid: nxid,
          wsUrl: nxResponse['nxws'],
        );
        print('✅ NX credentials stored for future use');

        // Initialize SDK with the fetched credentials
        await _sdk!.initialize(
          username: formattedPhone,
          nxtoken: nxtoken,
          nxid: nxid,
          wsUrl: wsUrl,
        );
      }

      print('✅ Messaging SDK initialized successfully');

      // Use the NX manager directly from SDK (already connected)
      final nxManager = _sdk!.xmppManager;
      print('🔌 NX Manager: ${nxManager != null ? "found" : "null"}');

      if (nxManager == null) {
        throw Exception('NX manager not available after SDK initialization');
      }

      // Create MessagingManager from nxManager for sending messages
      _messagingManager = MessagingManager(nxManager);
      print('📨 MessagingManager created');

      // Set up streams from NX manager
      nxManager.messageStream.listen((message) {
        print('📩 Message received from NX stream');
        messageStream.add(message);
      });

      nxManager.presenceStream.listen((presence) {
        print('👤 Presence received from NX stream');
        presenceStream.add(presence);
      });

      nxManager.deliveryReceiptStream.listen((receipt) {
        print('📬 Delivery receipt received from NX stream');
        deliveryReceiptStream.add(receipt);
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
    if (digits.startsWith('0')) {
      return '255${digits.substring(1)}';
    } else if (digits.startsWith('255')) {
      return digits;
    }
    return digits;
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
    if (_messagingManager == null) {
      throw Exception('MessagingManager not initialized');
    }

    _messagingManager!.sendMessage(to: to, message: message);
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
    final client = _sdk?.client;
    if (client == null) {
      throw Exception('Messaging service not initialized');
    }

    return await client.messaging.getContacts();
  }

  /// Add a contact
  Future<Map<String, dynamic>> addContact(String nxid) async {
    final client = _sdk?.client;
    if (client == null) {
      throw Exception('Messaging service not initialized');
    }

    return await client.messaging.addContact(nxid);
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

    // Handle different response formats from SDK
    if (history is List) {
      return (history as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }

    // If it's a Map, look for messages field
    final messages = history['messages'];
    if (messages is List) {
      return messages.map((e) => e as Map<String, dynamic>).toList();
    }

    return [];
  }

  /// Clear message stream
  void clearMessageStream() {
    messageStream.value = [];
  }

  @override
  void onClose() {
    _messagingManager?.dispose();
    super.onClose();
  }
}
