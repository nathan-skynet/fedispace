import 'dart:async';
import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:flutter/material.dart';

class NotificationPollingService {
  static final NotificationPollingService _instance = NotificationPollingService._internal();

  factory NotificationPollingService() {
    return _instance;
  }

  NotificationPollingService._internal();

  ApiService? _apiService;
  Timer? _pollingTimer;
  String? _lastNotificationId;
  bool _isPolling = false;
  
  // DM polling state
  final Set<String> _knownDmIds = {};
  bool _dmBaselineSet = false;

  void init(ApiService apiService) {
    _apiService = apiService;
    appLogger.info("NotificationPollingService initialized");
    initializeNotifications();
  }

  /// Initialize AwesomeNotifications channels
  void initializeNotifications() {
    AwesomeNotifications().initialize('resource://drawable/logo', [
      NotificationChannel(
        channelGroupKey: 'Story notifications',
        channelKey: 'stories',
        channelName: 'Story',
        channelDescription: 'Notification channel for stories',
        channelShowBadge: true,
        importance: NotificationImportance.High,
        enableVibration: true,
      ),
      NotificationChannel(
        channelGroupKey: 'mention notifications',
        channelKey: 'mention',
        channelName: 'Mention',
        channelDescription: 'Notification channel for mention',
        defaultColor: Colors.redAccent,
        ledColor: Colors.white,
        channelShowBadge: true,
        importance: NotificationImportance.High,
      ),
      NotificationChannel(
        channelGroupKey: 'favourite notifications',
        channelKey: 'favourite',
        channelName: 'Favourite',
        channelDescription: 'Notification channel for favourite',
        defaultColor: Colors.redAccent,
        ledColor: Colors.white,
        channelShowBadge: true,
        importance: NotificationImportance.High,
      ),
      NotificationChannel(
        channelGroupKey: 'follow notifications',
        channelKey: 'follow',
        channelName: 'Follow',
        channelDescription: 'Notification channel for follow',
        defaultColor: Colors.redAccent,
        ledColor: Colors.white,
        channelShowBadge: true,
        importance: NotificationImportance.High,
      ),
      NotificationChannel(
        channelGroupKey: 'follow_request notifications',
        channelKey: 'follow_request',
        channelName: 'Follow request',
        channelDescription: 'Notification channel for follow request',
        defaultColor: Colors.redAccent,
        ledColor: Colors.white,
        channelShowBadge: true,
        importance: NotificationImportance.High,
      ),
      NotificationChannel(
        channelGroupKey: 'reblog notifications',
        channelKey: 'reblog',
        channelName: 'Reblog',
        channelDescription: 'Notification channel for reblog',
        defaultColor: Colors.redAccent,
        ledColor: Colors.white,
        channelShowBadge: true,
        importance: NotificationImportance.High,
      ),
      NotificationChannel(
        channelGroupKey: 'status notifications',
        channelKey: 'status',
        channelName: 'Status',
        channelDescription: 'Notification channel for status',
        defaultColor: Colors.redAccent,
        ledColor: Colors.white,
        channelShowBadge: true,
        importance: NotificationImportance.High,
      ),
      NotificationChannel(
        channelGroupKey: 'Internal notifications',
        channelKey: 'internal',
        channelName: 'Internal',
        channelDescription: 'Internal notification channel',
        defaultColor: const Color(0xFF00F3FF),
        ledColor: Colors.white,
        channelShowBadge: true,
        importance: NotificationImportance.High,
      ),
      NotificationChannel(
        channelGroupKey: 'Direct message notifications',
        channelKey: 'direct_message',
        channelName: 'Direct Messages',
        channelDescription: 'Notification channel for direct messages',
        defaultColor: const Color(0xFF0095F6),
        ledColor: Colors.white,
        channelShowBadge: true,
        importance: NotificationImportance.High,
        enableVibration: true,
      ),
    ]);
  }

  /// Start polling for notifications
  void startPolling() {
    if (_isPolling) return;
    if (_apiService == null) {
      appLogger.error("NotificationPollingService: ApiService not initialized");
      return;
    }

    appLogger.info("Starting notification polling (10s interval)");
    _isPolling = true;

    // Initial fetch to set the baseline (don't notify for existing ones)
    _fetchNotifications(isInitial: true);
    _fetchDMs(isInitial: true);

    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchNotifications();
      _fetchDMs();
    });
  }

  /// Stop polling
  void stopPolling() {
    if (!_isPolling) return;
    
    appLogger.info("Stopping notification polling");
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
  }

  Future<void> _fetchNotifications({bool isInitial = false}) async {
    try {
      if (_apiService == null) return;

      // check if we are logged in
      final account = await _apiService!.getCurrentAccount(); // This throws if not logged in usually, or returns null? 
      // Actually ApiService.getNotification throws if error.

      final responseBody = await _apiService!.getNotification();
      final List<dynamic> notifications = jsonDecode(responseBody);

      if (notifications.isEmpty) return;

      // Sort by ID to ensure we have the latest
      // IDs are strings in Mastodon/Pixelfed but usually lexicographically sortable or numeric
      // Let's assume the API returns them in reverse chronological order (newest first).
      
      final latestNotification = notifications.first;
      final String latestId = latestNotification['id'].toString();

      if (_lastNotificationId == null) {
        // First run, just set the ID
        _lastNotificationId = latestId;
        appLogger.info("NotificationPollingService: Baseline ID set to $_lastNotificationId");
        return;
      }

      if (latestId != _lastNotificationId) {
         // Potential new notification(s)
         // For simplicity in this v1, we just notify for the very latest one if it's new
         // In a robust system, we'd iterate backwards until we find _lastNotificationId
         
         // Basic check: is the latest ID "greater" than the last one? 
         // Since IDs are IDs, checking inequality is enough if we assume we poll often enough.
         // But to be sure it's NEW, we should check if the list contains the old ID, 
         // and everything before it is new.
         
         // Simpler approach: If ID is different and we assume it's newer:
         // (Realistically, if we poll every 10s, we likely get 1 or 2 max).
         
         // Let's iterate and find new ones
         List<dynamic> newNotifications = [];
         for (var notif in notifications) {
           if (notif['id'].toString() == _lastNotificationId) break;
           newNotifications.add(notif);
         }
         
         if (newNotifications.isNotEmpty) {
           appLogger.info("NotificationPollingService: Found ${newNotifications.length} new notifications");
           _lastNotificationId = latestId;

           if (!isInitial) {
             for (var notif in newNotifications.reversed) {
               await _showNotification(notif);
               // Small delay to prevent overlapping sounds
               await Future.delayed(const Duration(milliseconds: 500));
             }
           }
         }
      }

    } catch (e) {
      // appLogger.error("Error polling notifications", e);
      // Fail silently to catch intermittent network issues without spamming logs too hard
    }
  }

  Future<void> _showNotification(Map<String, dynamic> notification) async {
    try {
      final type = notification['type'];
      final account = notification['account'];
      final username = account['display_name'] != "" ? account['display_name'] : account['username'];
      final avatarUrl = account['avatar_static'];
      
      String title = "New Activity";
      String body = "You have a new notification";
      String channelKey = "internal"; // Default

      switch (type) {
        case 'mention':
          title = "New Mention";
          body = "$username mentioned you";
          channelKey = "mention";
          break;
        case 'follow':
          title = "New Follower";
          body = "$username followed you";
          channelKey = "follow";
          break;
        case 'favourite':
          title = "New Like";
          body = "$username liked your post";
          channelKey = "favourite";
          break;
        case 'reblog':
          title = "New Boost";
          body = "$username shared your post";
          channelKey = "reblog";
          break;
         case 'poll':
           title = "Poll Ended";
           body = "A poll you voted in has ended";
           channelKey = "status";
           break;
        default:
          title = "New Notification ($type)";
          body = "From $username";
          channelKey = "internal";
      }

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique Int ID
          channelKey: channelKey,
          title: title,
          body: body,
          bigPicture: avatarUrl,
          notificationLayout: NotificationLayout.BigPicture, // Show avatar if possible
          category: NotificationCategory.Social,
        ),
      );
    } catch (e) {
      appLogger.error("Error showing local notification", e);
    }
  }

  /// Poll for new DMs globally
  Future<void> _fetchDMs({bool isInitial = false}) async {
    try {
      if (_apiService == null) return;

      final conversations = await _apiService!.getConversationsByScope(scope: 'inbox', limit: 20);
      
      if (conversations.isEmpty) return;
      
      final Set<String> currentIds = {};
      
      for (var conv in conversations) {
        if (conv is! Map) continue;
        final lastStatus = conv['last_status'];
        if (lastStatus == null || lastStatus is! Map) continue;
        
        final statusId = lastStatus['id']?.toString();
        if (statusId == null) continue;
        
        currentIds.add(statusId);
        
        // On first run, just record the IDs
        if (isInitial || !_dmBaselineSet) continue;
        
        // Check if this is a new message we haven't seen
        if (!_knownDmIds.contains(statusId)) {
          // It's a new DM — check it's not from us
          final account = lastStatus['account'];
          if (account == null) continue;
          
          // Skip if the sender is the current user (our own messages)
          final senderId = account['id']?.toString();
          final currentUserId = _apiService!.currentAccount?.id;
          if (senderId != null && currentUserId != null && senderId == currentUserId) {
            _knownDmIds.add(statusId); // Track it but don't notify
            continue;
          }
          
          final senderName = account['display_name']?.toString().isNotEmpty == true 
              ? account['display_name'] 
              : account['username'] ?? 'Someone';
          final avatarUrl = account['avatar_static']?.toString();
          
          // Extract message content
          String content = lastStatus['content_text'] ?? 
              lastStatus['content']?.toString().replaceAll(RegExp(r'<[^>]*>'), '') ?? 
              'New message';
          if (content.length > 100) content = '${content.substring(0, 100)}...';
          
          appLogger.info("New DM from $senderName: $content");
          
          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              channelKey: 'direct_message',
              title: '💬 $senderName',
              body: content,
              bigPicture: avatarUrl,
              notificationLayout: avatarUrl != null ? NotificationLayout.BigPicture : NotificationLayout.Default,
              category: NotificationCategory.Message,
              payload: {
                'type': 'dm',
                'senderId': account['id']?.toString() ?? '',
                'senderName': senderName.toString(),
              },
            ),
          );
        }
      }
      
      // Update known IDs
      _knownDmIds.clear();
      _knownDmIds.addAll(currentIds);
      if (!_dmBaselineSet) _dmBaselineSet = true;
      
    } catch (e) {
      // Fail silently
    }
  }
}
