import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nexacon_messaging/nexacon_messaging.dart';
import 'package:get/get.dart';
import '../../../config/nexacon_config.dart';
import '../../../services/token_storage_service.dart';
import '../../../utils/phone_formatter.dart';

/// Service wrapper for Nexacon Messaging SDK
/// Handles real-time messaging with presence, typing indicators, and receipts
class NexaconMessagingService extends GetxService {
  NexaconMessaging? _messaging;
  final TokenStorageService _tokenStorage = Get.find<TokenStorageService>();
  StreamSubscription<NxConnectionState>? _connectionStateSubscription;

  // Expose streams from NexaconMessaging
  Stream<NxMessage> get messageStream =>
      _messaging?.messageStream ?? const Stream.empty();
  Stream<NxTypingEvent> get typingStream =>
      _messaging?.typingStream ?? const Stream.empty();
  Stream<NxReadReceipt> get readReceiptStream =>
      _messaging?.readReceiptStream ?? const Stream.empty();
  Stream<NxDeliveryReceipt> get deliveryReceiptStream =>
      _messaging?.deliveryReceiptStream ?? const Stream.empty();
  Stream<NxPresence> get presenceStream =>
      _messaging?.presenceStream ?? const Stream.empty();
  Stream<NxConnectionState> get connectionStateStream =>
      _messaging?.connectionStateStream ?? const Stream.empty();

  // Connection state
  final isConnected = false.obs;

  Completer<void>? _initCompleter;

  /// Ensure the connection is initialized before use
  Future<void> ensureInitialized() async {
    if (isConnected.value) return;
    await initializeConnection();
  }

  /// Initialize the messaging service
  Future<void> initialize() async {
    if (_messaging == null) {
      _messaging = NexaconMessaging(
        apiKey: NexaconConfig.apiKey,
        secretKey: NexaconConfig.secretKey,
      );
      print('✅ NexaconMessaging instance created');

      // Cancel old listener if exists
      await _connectionStateSubscription?.cancel();

      // Listen to connection state changes
      _connectionStateSubscription = _messaging!.connectionStateStream.listen((
        state,
      ) {
        isConnected.value = state == NxConnectionState.authenticated;
        print('🔌 Connection state: $state');
      });
    }

    print('✅ NexaconMessagingService initialized');
  }

  /// Force re-initialize: clear credentials and reconnect
  Future<void> forceReinitialize() async {
    print('🔄 forceReinitialize: clearing credentials and reconnecting...');
    isConnected.value = false;

    // Clear stored credentials
    await _tokenStorage.clearNxTokenData();

    // Disconnect current connection
    await _messaging?.disconnect();

    // Reinitialize
    await initializeConnection();
  }

  /// Initialize connection for messaging
  Future<void> initializeConnection() async {
    if (isConnected.value) return;
    if (_initCompleter != null) return _initCompleter!.future;

    print('🚀 initializeConnection() called');
    _initCompleter = Completer<void>();

    try {
      // Ensure messaging instance exists
      if (_messaging == null) {
        await initialize();
      }

      // Get user's phone number for NX ID
      final userData = _tokenStorage.userData;
      print('👤 User data: ${userData != null ? "found" : "null"}');

      // Try multiple possible phone number fields
      String? phone = userData?['phone_number'] as String? ??
          userData?['phone'] as String? ??
          userData?['mobile'] as String? ??
          userData?['contact_number'] as String? ??
          userData?['phoneNumber'] as String? ??
          userData?['username'] as String?;

      // Check nested contact object
      if (phone == null || phone.isEmpty) {
        final contact = userData?['contact'] as Map<String, dynamic>?;
        phone = contact?['phone_number'] as String?;
      }

      print('📱 Phone: $phone');

      if (phone == null || phone.isEmpty) {
        print('❌ User phone number not found');
        if (!_initCompleter!.isCompleted) {
          _initCompleter!.complete();
        }
        return;
      }

      // Format phone number with country code (don't add domain - API returns it)
      final formattedPhone = PhoneFormatter.formatWithCountryCode(phone);
      print('📡 Initializing messaging connection with phone: $formattedPhone');

      try {
        // Check if we have stored NX token data
        final hasNxData = await _tokenStorage.hasNxTokenData();
        print('🔐 Has stored NX data: $hasNxData');

        String? nxtoken;
        String? nxid;
        String? wsUrl;

        if (hasNxData) {
          // Use stored credentials
          nxtoken = await _tokenStorage.getNxToken();
          nxid = await _tokenStorage.getNxJid();
          wsUrl = await _tokenStorage.getNxWsUrl();

          print('🔑 Using stored credentials');
          print('🆔 JID: $nxid');
          print('🌐 WS URL: $wsUrl');

          // Ensure wss:// protocol
          if (wsUrl != null && wsUrl.startsWith('https://')) {
            wsUrl = wsUrl.replaceFirst('https://', 'wss://');
          }
        } else {
          // Fetch NX token from API
          print('🔐 Fetching NX credentials from API...');

          final credentials = await _messaging!.api.getNxToken(formattedPhone);

          nxtoken = credentials['token'] as String?;
          nxid = credentials['jid'] as String?;
          wsUrl = credentials['nxws'] as String?;

          // Store credentials
          if (nxtoken != null && nxid != null && wsUrl != null) {
            await _tokenStorage.storeNxTokenData(
              token: nxtoken,
              jid: nxid,
              wsUrl: wsUrl,
              refreshToken: credentials['refresh_token'] as String?,
            );
            print('✅ NX credentials stored');
          } else {
            throw Exception('Failed to get valid NX credentials');
          }
        }

        if (nxtoken == null || nxid == null || wsUrl == null) {
          throw Exception('Missing NX credentials');
        }

        // Ensure the REST API client has the token for history/presence calls
        _messaging!.api.setToken(nxtoken);

        // Connect to NX WebSocket
        print('🔌 Connecting to NX WebSocket...');
        final connected = await _messaging!.connect(
          nxid: nxid,
          password: nxtoken,
          wsUrl: wsUrl,
        );

        if (connected) {
          print('✅ NX WebSocket connection established');
          isConnected.value = true;
        } else {
          print('❌ NX WebSocket connection failed - token may be expired');

          // If we used stored credentials and auth failed, clear them and retry with fresh token
          if (hasNxData) {
            print(
              '🔄 Clearing expired credentials and fetching fresh token...',
            );
            await _tokenStorage.clearNxTokenData();

            // Fetch fresh credentials
            final freshCredentials = await _messaging!.api.getNxToken(
              formattedPhone,
            );
            nxtoken = freshCredentials['token'] as String?;
            nxid = freshCredentials['jid'] as String?;
            wsUrl = freshCredentials['nxws'] as String?;

            if (nxtoken != null && nxid != null && wsUrl != null) {
              // Store fresh credentials
              await _tokenStorage.storeNxTokenData(
                token: nxtoken,
                jid: nxid,
                wsUrl: wsUrl,
                refreshToken: freshCredentials['refresh_token'] as String?,
              );

              // Disconnect old connection first
              await _messaging!.disconnect();

              // Retry connection with fresh token
              print('🔌 Retrying connection with fresh token...');
              final retryConnected = await _messaging!.connect(
                nxid: nxid,
                password: nxtoken,
                wsUrl: wsUrl,
              );

              if (retryConnected) {
                print('✅ NX WebSocket connection established with fresh token');
                isConnected.value = true;
              } else {
                print('❌ NX WebSocket connection failed even with fresh token');
              }
            }
          }
        }

        if (!_initCompleter!.isCompleted) {
          _initCompleter!.complete();
        }
      } catch (e) {
        print('❌ Failed to initialize messaging connection: $e');
        rethrow;
      }
    } catch (e, st) {
      if (!_initCompleter!.isCompleted) {
        _initCompleter!.completeError(e, st);
      }
    } finally {
      _initCompleter = null;
    }
  }

  /// Send a message (real-time via WebSocket)
  Future<void> sendMessage({
    required String to,
    required String message,
  }) async {
    print('📤 sendMessage called');
    print('📤 To: $to');
    print('📤 Message: $message');

    if (_messaging == null) {
      throw Exception('Messaging service not initialized');
    }

    // Check if connected
    if (!isConnected.value) {
      print('⚠️ Not connected, attempting to connect...');
      await initializeConnection();

      if (!isConnected.value) {
        throw Exception(
          'Failed to connect to messaging service. Please check your internet connection.',
        );
      }
    }

    try {
      await _messaging!.sendMessage(to: to, message: message);
      print('✅ Message sent successfully');
    } catch (e) {
      print('❌ Failed to send message: $e');
      rethrow;
    }
  }

  /// Send typing indicator
  void sendTypingIndicator(String to, {required bool isTyping}) {
    _messaging?.sendTypingIndicator(to, isTyping: isTyping);
  }

  /// Send read receipt
  void sendReadReceipt(String to, String messageId) {
    _messaging?.sendReadReceipt(to, messageId);
  }

  /// Update presence status
  void setOnline() => _messaging?.setOnline();
  void setAway() => _messaging?.setAway();
  void setBusy() => _messaging?.setBusy();
  void setOffline() => _messaging?.setOffline();

  /// Subscribe to a contact's presence updates (so we get live online/offline events)
  void subscribeToPresence(String nxid) {
    _messaging?.subscribeToPresence(nxid);
  }

  /// Get cached presence status for a contact (from real-time stream)
  NxPresenceStatus? getCachedPresenceStatus(String nxid) {
    return _messaging?.getPresenceStatus(nxid);
  }

  /// Fetch a contact's current presence via REST API (for initial state)
  Future<NxPresenceStatus?> fetchPresence(String nxid) async {
    try {
      if (_messaging == null) return null;
      final peer = nxid.split('@').first.replaceAll('+', '');
      debugPrint('👤 fetchPresence: peer=$peer');
      final result = await _messaging!.getPresence(peer);
      debugPrint('👤 fetchPresence response: $result');

      // Check is_online boolean first (used by heartbeat-style API)
      final isOnline = result['is_online'];
      if (isOnline is bool) {
        return isOnline ? NxPresenceStatus.online : NxPresenceStatus.offline;
      }

      // Then check status string
      final status = result['status']?.toString().toLowerCase();
      switch (status) {
        case 'online':
        case 'available':
          return NxPresenceStatus.online;
        case 'away':
          return NxPresenceStatus.away;
        case 'busy':
        case 'dnd':
          return NxPresenceStatus.busy;
        case 'offline':
        case 'unavailable':
          return NxPresenceStatus.offline;
        default:
          // Unknown status — don't assume offline, return null so
          // callers can try alternate approaches.
          return null;
      }
    } catch (e) {
      debugPrint('⚠️ fetchPresence error: $e');
      return null;
    }
  }

  /// Cached NX contacts for caller name resolution
  List<Map<String, dynamic>>? _cachedContacts;
  DateTime? _contactsLastFetch;
  static const Duration _contactsCacheTtl = Duration(minutes: 5);

  /// Get the current user's NX contact list, with short in-memory caching.
  Future<List<Map<String, dynamic>>> getContacts(
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedContacts != null &&
        _contactsLastFetch != null &&
        DateTime.now().difference(_contactsLastFetch!) < _contactsCacheTtl) {
      debugPrint('📇 Using cached NX contacts (${_cachedContacts!.length})');
      return _cachedContacts!;
    }

    await ensureInitialized();

    if (_messaging == null) {
      throw Exception('Messaging service not initialized');
    }

    final contacts = await _messaging!.getContacts();
    _cachedContacts = contacts;
    _contactsLastFetch = DateTime.now();
    debugPrint('📇 Fetched ${contacts.length} NX contacts');
    return contacts;
  }

  /// Try to resolve a display name for a phone number or NX JID.
  ///
  /// 1. Searches the NX contacts list (cached for 5 minutes).
  /// 2. If no contact matches, fetches the latest message history for the
  ///    peer to retrieve the bare NX JID, then re-searches contacts.
  Future<String?> resolveCallerName(String phoneOrJid) async {
    if (phoneOrJid.trim().isEmpty) return null;

    // Normalize the input so we can match by phone digits or bare JID.
    final normalizedInput = _normalizeContactKey(phoneOrJid);
    if (normalizedInput.isEmpty) return null;

    try {
      final contacts = await getContacts();

      // 1. Search contacts by normalized phone / JID.
      for (final contact in contacts) {
        final keys = _extractContactKeys(contact);
        if (keys.contains(normalizedInput)) {
          final name = _extractContactName(contact);
          if (name != null && name.isNotEmpty) {
            debugPrint(
                '📇 Found caller name "$name" for $phoneOrJid in contacts');
            return name;
          }
        }
      }

      // 2. No contact match. Ask the history API for the peer and use the
      //    JID from the latest message to search contacts again.
      final history = await getConversationHistory(
        phoneOrJid,
        pageSize: 1,
      );

      if (history.messages.isNotEmpty) {
        final fromJid = history.messages.first.from;
        final bareJid = _normalizeContactKey(fromJid);

        for (final contact in contacts) {
          final keys = _extractContactKeys(contact);
          if (bareJid.isNotEmpty && keys.contains(bareJid)) {
            final name = _extractContactName(contact);
            if (name != null && name.isNotEmpty) {
              debugPrint(
                '📇 Found caller name "$name" for $phoneOrJid via history (JID: $bareJid)',
              );
              return name;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ resolveCallerName error for $phoneOrJid: $e');
    }

    return null;
  }

  /// Normalize a phone/JID to a comparable string of digits or bare JID.
  String _normalizeContactKey(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    // Strip domain if it's a JID
    var bare = trimmed.split('@').first;
    // Strip leading `+` and country code for phone comparison
    bare = bare.replaceAll('+', '').replaceAll(RegExp(r'^\s*255'), '');
    return bare.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// Extract all possible identifier values from a contact map.
  Set<String> _extractContactKeys(Map<String, dynamic> contact) {
    final keys = <String>{};
    final candidateFields = [
      'nxid',
      'username',
      'jid',
      'phone',
      'phone_number',
      'mobile',
      'contact_number',
      'owner_name',
    ];

    for (final field in candidateFields) {
      final value = contact[field]?.toString() ?? '';
      if (value.isNotEmpty) keys.add(_normalizeContactKey(value));
    }

    // Nested contact/phone object
    final contactObj = contact['contact'] as Map<String, dynamic>?;
    final phoneFromContact = contactObj?['phone_number']?.toString() ?? '';
    if (phoneFromContact.isNotEmpty) {
      keys.add(_normalizeContactKey(phoneFromContact));
    }

    return keys;
  }

  /// Extract the best display name from a contact map.
  String? _extractContactName(Map<String, dynamic> contact) {
    for (final field in ['name', 'display_name', 'full_name', 'owner_name']) {
      final value = contact[field]?.toString() ?? '';
      if (value.isNotEmpty) return value;
    }

    final firstName = contact['first_name']?.toString() ?? '';
    final lastName = contact['last_name']?.toString() ?? '';
    final parts = [firstName, lastName].where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(' ');

    return null;
  }

  /// Clear cached contacts, e.g. after reconnect or logout.
  void clearContactCache() {
    _cachedContacts = null;
    _contactsLastFetch = null;
    debugPrint('📇 NX contact cache cleared');
  }

  /// Disconnect messaging and reset state for logout / user switch.
  Future<void> disconnect() async {
    try {
      await _connectionStateSubscription?.cancel();
      _connectionStateSubscription = null;
      await _messaging?.disconnect();
      isConnected.value = false;
      clearContactCache();
      debugPrint('🔌 NexaconMessagingService disconnected and cleared');
    } catch (e) {
      debugPrint('⚠️ Error disconnecting messaging: $e');
    }
  }

  /// Get message history for a conversation (paginated via offset)
  Future<NxMessageHistoryResponse> getConversationHistory(
    String contactNxid, {
    int offset = 0,
    int pageSize = 50,
  }) async {
    debugPrint('📨 getConversationHistory(offset=$offset) for: $contactNxid');

    try {
      if (_messaging == null) {
        throw Exception('Messaging service not initialized');
      }

      final peer = contactNxid.split('@').first.replaceAll('+', '');
      debugPrint('📨 Fetching history for peer: $peer (stripped)');

      final history = await _messaging!.getMessageHistory(
        peer: peer,
        offset: offset,
        pageSize: pageSize,
      );

      debugPrint(
        '📨 API history: status=${history.status}, total=${history.total}, '
        'messages=${history.messages.length}, hasNext=${history.hasNext}, '
        'nextOffset=${history.nextOffset}',
      );

      return history;
    } catch (e) {
      debugPrint('❌ getConversationHistory error: $e');
      rethrow;
    }
  }

  /// Get all messages for the current user
  Future<List<NxHistoryMessage>> getAllMessages({
    int pageSize = 100,
    int offset = 0,
  }) async {
    debugPrint(
      '📨 getAllMessages called (offset: $offset, pageSize: $pageSize)',
    );

    try {
      if (_messaging == null) {
        throw Exception('Messaging service not initialized');
      }

      final history = await _messaging!.getMessageHistory(
        pageSize: pageSize,
        offset: offset,
      );

      debugPrint(
        '📨 API getAllMessages response: status=${history.status}, total=${history.total}, messages=${history.messages.length}',
      );

      // Sort by timestamp descending (newest first)
      final sortedMessages = List<NxHistoryMessage>.from(history.messages);
      sortedMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return sortedMessages;
    } catch (e) {
      debugPrint('❌ getAllMessages error: $e');
      rethrow;
    }
  }

  @override
  void onClose() {
    _connectionStateSubscription?.cancel();
    _messaging?.dispose();
    super.onClose();
  }
}
