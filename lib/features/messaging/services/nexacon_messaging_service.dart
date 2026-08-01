import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nexacon_sdk/nexacon_sdk.dart';
import 'package:get/get.dart';
import '../../../config/nexacon_config.dart';
import '../../../services/token_storage_service.dart';
import '../../../utils/phone_formatter.dart';

/// Service wrapper for Nexacon SDK messaging functionality
/// Handles real-time messaging, contact management, and message history
class NexaconMessagingService extends GetxService {
  NexaconSDK? _sdk;
  MessagingManager? _messagingManager;
  NexaconClient? _httpClient; // Separate client for HTTP API calls
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

  Completer<void>? _initCompleter;
  bool _httpReady = false;

  /// Ensure the HTTP client/connection is initialized before use.
  /// Safe to call repeatedly and from anywhere; will not re-initialize if ready.
  Future<void> ensureInitialized() async {
    if (_httpReady) return;
    await initializeConnection();
  }

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

  /// Force re-initialize: try refresh token first, fall back to full re-init
  Future<void> forceReinitialize() async {
    print('🔄 forceReinitialize: attempting token refresh...');
    isConnected.value = false;

    // Always clear stored credentials and fetch fresh ones for 403 errors
    // This ensures we get a fresh NX token and WebSocket connection
    print('🔄 Clearing stored NX credentials and fetching fresh ones...');
    await _tokenStorage.clearNxTokenData();
    _sdk = null;
    await initializeConnection();
  }

  /// Initialize SDK connection for messaging
  /// This establishes the NX connection required for real-time chat
  Future<void> initializeConnection() async {
    if (_httpReady) return;
    if (_initCompleter != null) return _initCompleter!.future;

    print('🚀 initializeConnection() called');
    _initCompleter = Completer<void>();

    try {
      // Create separate HTTP client for API calls
      if (_httpClient == null) {
        print('📦 Creating HTTP client for API calls');
        _httpClient = NexaconClient(
          apiKey: NexaconConfig.apiKey,
          secretKey: NexaconConfig.secretKey,
          baseUrl: 'https://nxservice.quantumvision-tech.com/api/v1.0',
        );
      }

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
        _httpReady = false;
        if (!_initCompleter!.isCompleted) {
          _initCompleter!.complete();
        }
        return;
      }

      // Format phone number with country code
      final formattedPhone = PhoneFormatter.formatAsNxId(phone);
      print('📡 Initializing messaging connection with phone: $formattedPhone');

      try {
        // Check if we have stored NX token data
        final hasNxData = await _tokenStorage.hasNxTokenData();
        print('🔐 Has stored NX data: $hasNxData');

        String? nxtoken;
        String? nxid;
        String? wsUrl;

        if (hasNxData) {
          // Use stored credentials to avoid API call
          nxtoken = await _tokenStorage.getNxToken();
          nxid = await _tokenStorage.getNxJid();
          wsUrl = await _tokenStorage.getNxWsUrl();

          print('🔑 Stored token: ${nxtoken?.substring(0, 20)}...');
          print('🆔 Stored JID: $nxid');
          print('🌐 Stored WS URL: $wsUrl');

          if (wsUrl != null && wsUrl.startsWith('https://')) {
            wsUrl = wsUrl.replaceFirst('https://', 'wss://');
          }

          print('✅ Using stored NX credentials');
        } else {
          // Fetch NX token directly via auth API without WebSocket connection
          print('🔐 No stored NX credentials, fetching from API...');

          final credentials =
              await _httpClient!.auth.getNxToken(username: formattedPhone);

          nxtoken = credentials['token'];
          nxid = credentials['jid'];
          wsUrl = credentials['nxws'];

          // Store the credentials returned by SDK (including refresh_token if present)
          if (nxtoken != null && nxid != null && wsUrl != null) {
            await _tokenStorage.storeNxTokenData(
              token: nxtoken,
              jid: nxid,
              wsUrl: wsUrl,
              refreshToken: credentials['refresh_token'] as String?,
            );
            print('✅ NX credentials stored for future use');
          } else {
            throw Exception('Failed to get valid NX credentials from API');
          }
        }

        // Set the NX token on the client for HTTP API calls
        if (nxtoken != null) {
          _httpClient!.setToken(nxtoken);
          print('✅ NX token set on client for HTTP API calls');
        } else {
          throw Exception('NX token is null, cannot set on client');
        }

        // Try to establish NX WebSocket connection for real-time messaging
        // If this fails, we can still use HTTP API calls
        try {
          print('🔌 Attempting to establish NX WebSocket connection...');
          final nxManager = _sdk!.xmppManager;
          if (nxManager == null) {
            print('⚠️ NX manager not available, skipping WebSocket connection');
          } else {
            final nxConnected = await nxManager.connect(
              jid: nxid!,
              password: nxtoken,
              wsUrl: wsUrl!,
            );

            if (nxConnected) {
              print('✅ NX WebSocket connection established');

              // Create MessagingManager from nxManager for sending messages
              _messagingManager = MessagingManager(nxManager);
              print('📨 MessagingManager created');

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
            } else {
              print(
                  '⚠️ NX WebSocket connection failed, but HTTP API calls will still work');
            }
          }
        } catch (e) {
          print('⚠️ NX WebSocket connection failed: $e');
          print('⚠️ HTTP API calls will still work with the NX token');
        }

        print('✅ Messaging SDK initialized successfully');
        print('📦 SDK client: ${_sdk?.client != null ? "exists" : "null"}');
        print('✅ isConnected: ${isConnected.value}');

        _httpReady = true;
        if (!_initCompleter!.isCompleted) {
          _initCompleter!.complete();
        }
      } catch (e) {
        print('❌ Failed to initialize messaging connection: $e');
        print('❌ Stack trace: ${StackTrace.current}');
        rethrow;
      }
    } catch (e, st) {
      _httpReady = false;
      if (!_initCompleter!.isCompleted) {
        _initCompleter!.completeError(e, st);
      }
    } finally {
      _initCompleter = null;
    }
  }

  /// Send a message using HTTP API (reliable delivery)
  Future<Map<String, dynamic>> sendMessage({
    required String to,
    required String message,
  }) async {
    print('📤 sendMessage called');
    print('📤 To (original): $to');
    print('📤 Message: $message');
    print('📤 HTTP Client: ${_httpClient != null ? "initialized" : "null"}');

    if (_httpClient == null) {
      print('❌ HTTP Client not initialized');
      throw Exception('Messaging service not initialized');
    }

    // Strip domain suffix for API compatibility (API expects phone number only)
    final recipient = to.split('@').first;
    print('📤 To (stripped): $recipient');

    try {
      print('📤 Sending message via HTTP API...');
      final response = await _httpClient!.messaging.send(
        to: recipient,
        message: message,
        messageType: 'chat',
      );
      print('✅ Message sent successfully: $response');

      // Also send via WebSocket if available for real-time delivery
      if (_messagingManager != null) {
        try {
          _messagingManager!.sendMessage(to: to, message: message);
          print('✅ Message also sent via WebSocket for real-time delivery');
        } catch (e) {
          print('⚠️ WebSocket send failed (message already sent via HTTP): $e');
        }
      }

      return response;
    } catch (e) {
      print('❌ Failed to send message: $e');
      rethrow;
    }
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

  /// Add a contact with optional display name
  Future<Map<String, dynamic>> addContact(String nxid, {String? name}) async {
    print('📨 addContact called with nxid: $nxid, name: $name');

    final client = _sdk?.client;
    if (client == null) {
      print('❌ SDK client is null - cannot add contact');
      throw Exception('Messaging service not initialized - client is null');
    }

    print('📨 Calling client.messaging.addContact with nxid and name...');
    try {
      final result = await client.messaging.addContact(nxid, name: name);
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
  Future<MessageHistoryResponse> getMessageHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? sender,
    String? peer,
    String? messageType,
    int page = 1,
    int pageSize = 20,
  }) async {
    final client = _httpClient;
    if (client == null) {
      throw Exception('Messaging service not initialized');
    }

    return await client.messaging.getMessageHistory(
      startDate: startDate,
      endDate: endDate,
      sender: sender,
      peer: peer,
      messageType: messageType,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Get message history for a specific conversation (both sent and received)
  ///
  /// Enhanced API automatically resolves peer identifiers:
  /// - Supports phone with/without + prefix (e.g., 255788811169 or +255788811169)
  /// - Supports full JID (e.g., +255788811189@nxservice.quantumvision-tech.com)
  /// - Returns ALL messages between you and peer (sent OR received)
  Future<List<NexaconMessage>> getConversationHistory(
    String contactNxid, {
    int pageSize = 50,
  }) async {
    debugPrint('📨 getConversationHistory called for contact: $contactNxid');

    try {
      MessageHistoryResponse history;
      // Enhanced API handles all peer formats automatically:
      // - Bare phone: 255788811169
      // - With + prefix: +255788811169
      // - Full JID: +255788811189@nxservice.quantumvision-tech.com
      // Just pass the contactNxid as-is, API will resolve it
      final peer = contactNxid.split('@').first; // Strip domain if present
      debugPrint(
          '📨 Calling getMessageHistory with peer: $peer (API will auto-resolve)');

      // Don't filter by messageType to get all messages (chat, sms, etc.)
      history = await getMessageHistory(
        peer: peer,
        pageSize: pageSize,
      );
      debugPrint('📨 getMessageHistory returned successfully');

      debugPrint(
          '📨 getConversationHistory: SDK response type: ${history.runtimeType}');
      debugPrint(
          '📨 getConversationHistory: history.messages type: ${history.messages.runtimeType}');
      debugPrint(
          '📨 getConversationHistory: history.messages value: ${history.messages}');

      debugPrint('📨 Conversation messages: ${history.messages.length}');

      // Sort by timestamp ascending (oldest first for display)
      final sortedMessages = List<NexaconMessage>.from(history.messages);
      sortedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return sortedMessages;
    } on APIException catch (e) {
      if (e.statusCode == 403) {
        debugPrint('⚠️ 403 error - NX token invalid, refreshing...');
        await forceReinitialize();
        // Retry after token refresh
        final peer = contactNxid.split('@').first;
        final history = await getMessageHistory(
          peer: peer,
          pageSize: pageSize,
        );
        debugPrint('📨 getMessageHistory returned successfully after retry');

        // Sort by timestamp ascending (oldest first for display)
        final sortedMessages = List<NexaconMessage>.from(history.messages);
        sortedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        return sortedMessages;
      } else {
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ getConversationHistory error: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Get ALL messages for the current user (sent and received)
  ///
  /// Enhanced API feature: Returns all your messages without filtering by peer
  /// Useful for displaying a unified message inbox or search across all conversations
  Future<List<NexaconMessage>> getAllMessages({
    int pageSize = 100,
    int page = 1,
  }) async {
    debugPrint('📨 getAllMessages called (page: $page, pageSize: $pageSize)');

    try {
      // Call getMessageHistory without peer parameter to get ALL messages
      final history = await getMessageHistory(
        pageSize: pageSize,
        page: page,
      );
      debugPrint(
          '📨 getAllMessages returned ${history.messages.length} messages');

      // Sort by timestamp descending (newest first for inbox view)
      final sortedMessages = List<NexaconMessage>.from(history.messages);
      sortedMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return sortedMessages;
    } catch (e) {
      debugPrint('❌ getAllMessages error: $e');
      rethrow;
    }
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
