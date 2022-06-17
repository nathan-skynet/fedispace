// Initial Import

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:camera/camera.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/notification.dart';
import 'package:fedispace/core/unifiedpush.dart';
import 'package:fedispace/routes/homepage/homepage.dart';
import 'package:fedispace/routes/post/desc.dart';
import 'package:fedispace/routes/post/send.dart';
import 'package:fedispace/routes/post/takecamera.dart';
import 'package:fedispace/routes/post/view.dart';
import 'package:fedispace/routes/presentation/home.dart';
import 'package:fedispace/routes/profile/profile.dart';
import 'package:fedispace/routes/timeline/timeline.dart';
import 'package:fedispace/themes/dark.dart';
import 'package:fedispace/themes/light.dart';
import 'package:flutter/material.dart';

List<CameraDescription> cameras = [];

const String isolateName = 'isolate';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

// Main Class
class MyApp extends StatelessWidget {
  final apiService = ApiService();
  final unifiedPush = UnifiedPushService();

  MyApp({Key? key}) : super(key: key);
  final title = 'Fedi Space';

  @override
  Widget build(BuildContext context) {
    Future<bool> returnatHome() async {
      Timeline(apiService: apiService, typeTimeLine: "public");
      return true;
    }

    AwesomeNotifications()
        .actionStream
        .listen((ReceivedNotification receivedNotification) {
      Navigator.pushNamed(context, '/Notification');
    });
    return MaterialApp(
      title: title,
      theme: lightThemeData,
      darkTheme: darkThemeData,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      initialRoute: '/Login',
      routes: {
        '/Login': (context) =>
            HomeScreen(apiService: apiService, unifiedPushService: unifiedPush),
        '/TimeLine': (context) =>
            Timeline(apiService: apiService, typeTimeLine: "home"),
        '/Local': (context) =>
            Timeline(apiService: apiService, typeTimeLine: "public"),
        '/Photo': (context) =>
            Timeline(apiService: apiService, typeTimeLine: "home"),
        '/Bookmark': (context) =>
            Timeline(apiService: apiService, typeTimeLine: "public"),
        '/Profile': (context) => Profile(apiService: apiService),
        '/Live': (context) =>
            Timeline(apiService: apiService, typeTimeLine: "public"),
        '/Camera': (context) => CameraScreen(apiService: apiService),
        '/Notification': (context) => Notif(apiService: apiService),
        '/View': (context) => const View(),
        '/Desc': (context) => Desc(apiService: apiService),
        '/sendPosts': (context) => sendPosts(apiService: apiService),
        '/presentation': (context) => const presentation(),
      },
    );
  }
}
