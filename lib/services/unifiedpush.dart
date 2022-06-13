
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:unifiedpush/constants.dart';
import 'package:unifiedpush/unifiedpush.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

var instance = "myInstance";
var endpoint = "";
var registered = false;

class UnifiedPushService {
  late final UnifiedPush unifiedPush;

  Future<bool> InitUnifiedPush() async {
    print("init push ok");
    await UnifiedPush.initialize(
      onNewEndpoint:
      onNewEndpoint, // takes (String endpoint, String instance) in args
      onRegistrationFailed: onRegistrationFailed, // takes (String instance)
      onUnregistered: onUnregistered, // takes (String instance)
      onMessage: onMessage,
    );
    return true;
  }


  Future<void> StartUnifiedPush(context) async {
    await UnifiedPush.registerAppWithDialog(context, instance, [featureAndroidBytesMessage]);
    debugPrint("UnifiedPushService started");
    _initNotifications();
  }



  Future<bool> onMessage(Uint8List message, String instance) async {

    String convertUint8ListToString(Uint8List uint8list) {
          return String.fromCharCodes(uint8list);
    };

     print(convertUint8ListToString(message));

      _initNotifications();
      AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 1,
            channelKey: 'stories',
            title: 'This is Notification title',
            body: 'This is Body of Noti',
            bigPicture: 'https://protocoderspoint.com/wp-content/uploads/2021/05/Monitize-flutter-app-with-google-admob-min-741x486.png',
            notificationLayout: NotificationLayout.BigPicture
        ),
      );
     return true;
  }

    void _initNotifications() async {
    WidgetsFlutterBinding.ensureInitialized();
    AwesomeNotifications().initialize(
        'resource://drawable/logo',
        [            // notification icon
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
              importance: NotificationImportance.High
          ),

          NotificationChannel(
              channelGroupKey: 'favourite notifications',
              channelKey: 'favourite',
              channelName: 'Favourite',
              channelDescription: 'Notification channel for favourite',
              defaultColor: Colors.redAccent,
              ledColor: Colors.white,
              channelShowBadge: true,
              importance: NotificationImportance.High
          ),

          NotificationChannel(
              channelGroupKey: 'follow notifications',
              channelKey: 'follow',
              channelName: 'Follow',
              channelDescription: 'Notification channel for follow',
              defaultColor: Colors.redAccent,
              ledColor: Colors.white,
              channelShowBadge: true,
              importance: NotificationImportance.High
          ),

          NotificationChannel(
              channelGroupKey: 'follow_request notifications',
              channelKey: 'follow_request',
              channelName: 'Follow request',
              channelDescription: 'Notification channel for follow request',
              defaultColor: Colors.redAccent,
              ledColor: Colors.white,
              channelShowBadge: true,
              importance: NotificationImportance.High
          ),

          NotificationChannel(
              channelGroupKey: 'reblog notifications',
              channelKey: 'reblog',
              channelName: 'Reblog',
              channelDescription: 'Notification channel for reblog',
              defaultColor: Colors.redAccent,
              ledColor: Colors.white,
              channelShowBadge: true,
              importance: NotificationImportance.High
          ),

          NotificationChannel(
              channelGroupKey: 'status notifications',
              channelKey: 'status',
              channelName: 'Status',
              channelDescription: 'Notification channel for status',
              defaultColor: Colors.redAccent,
              ledColor: Colors.white,
              channelShowBadge: true,
              importance: NotificationImportance.High
          ),
          NotificationChannel(
              channelGroupKey: 'Internal notifications',
              channelKey: 'internal',
              channelName: 'internal',
              channelDescription: 'Internal notification channel',
              defaultColor: Colors.redAccent,
              ledColor: Colors.white,
              channelShowBadge: true,
              importance: NotificationImportance.High
          )
        ]
    );
  }

  void onNewEndpoint(String _endpoint, String _instance) {
    if (_instance != instance) {
      return;
    }
    registered = true;
    endpoint = _endpoint;
    debugPrint(endpoint);
  }

  void onRegistrationFailed(String _instance) {
    //TODO
  }

  void onUnregistered(String _instance) {
    if (_instance != instance) {
      return;
    }
    registered = false;
    debugPrint("unregistered");
  }
}

