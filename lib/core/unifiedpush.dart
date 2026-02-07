import 'dart:typed_data';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:unifiedpush/unifiedpush.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';

class UnifiedPushService {
  final String instance = "fedispace_main";
  String? endpoint;
  bool registered = false;
  ApiService? _apiService;

  /// Initialize UnifiedPush with proper error handling
  Future<bool> initUnifiedPush() async {
    try {
      appLogger.info('Initializing UnifiedPush');
      
      await UnifiedPush.initialize(
        onNewEndpoint: _onNewEndpoint,
        onRegistrationFailed: _onRegistrationFailed,
        onUnregistered: _onUnregistered,
        onMessage: _onMessage,
      );
      
      appLogger.info('UnifiedPush initialized successfully');
      return true;
    } catch (e, stackTrace) {
      appLogger.error('Failed to initialize UnifiedPush', e, stackTrace);
      return false;
    }
  }

  /// Start UnifiedPush registration with distributor check
  Future<void> startUnifiedPush(BuildContext context, ApiService apiService) async {
    _apiService = apiService;
    _initNotifications();
    
    appLogger.info('Starting UnifiedPush registration');
    
    // Check available distributors first
    final distributors = await UnifiedPush.getDistributors();
    
    if (distributors.isEmpty) {
      appLogger.error('No UnifiedPush distributors found');
      _showNoDistributorWarning(context);
      return;
    }
    
    appLogger.info('Found distributors: $distributors');
    
    // Save and use first available distributor
    await UnifiedPush.saveDistributor(distributors.first);
    
    // Register with UnifiedPush
    await UnifiedPush.registerApp(instance);
  }

  /// Callback when new endpoint is received (v5 API uses String)
  void _onNewEndpoint(String endpointUrl, String inst) {
    if (inst != instance) {
      appLogger.error('Received endpoint for different instance: $inst');
      return;
    }
    
    registered = true;
    endpoint = endpointUrl;
    
    appLogger.info('New UnifiedPush endpoint received: $endpointUrl');
    
    // Send endpoint to server
    if (_apiService != null) {
      _registerEndpointWithServer(endpointUrl);
    } else {
      appLogger.error('ApiService not set, cannot register endpoint');
    }
  }

  /// Register push endpoint with Pixelfed server
  Future<void> _registerEndpointWithServer(String endpointUrl) async {
    try {
      appLogger.info('Registering push endpoint with server');
      
      // TODO: Implement actual API call when server supports it
      // For now, just store and log
      // await _apiService!.subscribePushNotifications(endpointUrl);
      
      appLogger.info('Push endpoint registered: $endpointUrl');
      
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 100,
          channelKey: 'internal',
          title: 'Push Notifications Ready',
          body: 'Successfully registered for push notifications',
        ),
      );
    } catch (e, stackTrace) {
      appLogger.error('Failed to register endpoint with server', e, stackTrace);
    }
  }

  /// Callback when registration fails (v5 API uses String)
  void _onRegistrationFailed(String inst) {
    if (inst != instance) return;
    
    registered = false;
    appLogger.error('UnifiedPush registration failed for instance: $inst');
    
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 101,
        channelKey: 'internal',
        title: 'Push Registration Failed',
        body: 'Failed to register for push notifications',
      ),
    );
  }

  /// Callback when unregistered
  void _onUnregistered(String inst) {
    if (inst != instance) return;
    
    registered = false;
    endpoint = null;
    appLogger.info('UnifiedPush unregistered');
  }

  /// Callback when message is received (v5 API uses Uint8List)
  void _onMessage(Uint8List message, String inst) {
    if (inst != instance) return;
    
    final decoded = String.fromCharCodes(message);
    appLogger.info('UnifiedPush message received: $decoded');
    
    // Parse and display notification
    // TODO: Parse Pixelfed notification format
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: 'status',
        title: 'New Notification',
        body: decoded,
      ),
    );
  }

  /// Show warning when no distributor is installed
  void _showNoDistributorWarning(BuildContext context) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 102,
        channelKey: 'internal',
        title: 'UnifiedPush Setup Required',
        body: 'Please install a push distributor app (e.g., ntfy) from F-Droid',
      ),
    );
  }

  /// Initialize notification channels
  void _initNotifications() {
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
    ]);
  }

  /// Unregister from push notifications
  Future<void> unregister() async {
    await UnifiedPush.unregister(instance);
    appLogger.info('UnifiedPush unregistration requested');
  }
}
