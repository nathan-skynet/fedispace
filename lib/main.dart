// Initial Import

import 'package:fedispace/routes/addposts/desc.dart';
import 'package:fedispace/routes/addposts/view.dart';
import 'package:fedispace/services/unifiedpush.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'package:fedispace/themes/dark.dart';
import 'package:fedispace/themes/light.dart';

import 'package:fedispace/routes/timeline.dart';
import 'package:fedispace/routes/login.dart';
import 'package:fedispace/routes/profile.dart';
import 'package:fedispace/routes/takecamera.dart';
import 'package:fedispace/services/api.dart';
import 'package:fedispace/routes/notification.dart';
import 'package:awesome_notifications/awesome_notifications.dart';


List<CameraDescription> cameras = [];
const String isolateName = 'isolate';

/// A port used to communicate from a background isolate to the UI isolate.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error in fetching the cameras: $e');
  }
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

Future<bool> returnatHome() async{
  Timeline(apiService: apiService,typeTimeLine: "public");
      return true;
}

AwesomeNotifications().actionStream.listen(
  (ReceivedNotification receivedNotification){
    Navigator.pushNamed(context, '/Notification');
  }
);
    return MaterialApp(
        title: title,
        theme: lightThemeData,
        darkTheme: darkThemeData,
        themeMode: ThemeMode.dark,
        debugShowCheckedModeBanner: false,
        initialRoute: '/Login',
        routes: {
           '/Login': (context) => HomeScreen(apiService: apiService, unifiedPushService: unifiedPush),
          '/TimeLine' : (context) => Timeline(apiService: apiService, typeTimeLine: "home"),
          '/Local' : (context) => Timeline(apiService: apiService,typeTimeLine: "public"),
          '/Photo' : (context) => Timeline(apiService: apiService, typeTimeLine: "home"),
          '/Bookmark' : (context) => Timeline(apiService: apiService,typeTimeLine: "public"),
          '/Profile' : (context) => Profile(apiService: apiService),
          '/Live' : (context) => Timeline(apiService: apiService,typeTimeLine: "public"),
          '/Camera' : (context) => CameraScreen(apiService: apiService),
          '/Notification' : (context) => Notif(apiService: apiService),
          '/View' : (context) => View(),
          '/Desc' : (context) => Desc(apiService: apiService),
        },
    );
  }
}
