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
import 'package:fedispace/routes/post/view.dart' as post_view;
import 'package:fedispace/routes/presentation/home.dart';
import 'package:fedispace/routes/profile/profile.dart';
import 'package:fedispace/routes/timeline/timeline.dart';
import 'package:fedispace/routes/main_screen.dart';
import 'package:fedispace/routes/notifications/notifications_page.dart';
import 'package:fedispace/routes/profile/edit_profile.dart';
import 'package:fedispace/routes/profile/user_profile_page.dart';
import 'package:fedispace/routes/followers/followers_list_page.dart';
import 'package:fedispace/routes/bookmarks/bookmarks_page.dart';
import 'package:fedispace/routes/liked/liked_posts_page.dart';
import 'package:fedispace/routes/post/post_detail_page.dart';
import 'package:fedispace/routes/messages/direct_messages_page.dart';
import 'package:fedispace/routes/settings/settings_page.dart';
import 'package:fedispace/routes/search/search_page.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
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

    // AwesomeNotifications listener moved to init

    return MaterialApp(
      title: title,
      theme: CyberpunkTheme.theme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/Login',
      routes: {
        '/Login': (context) =>
            HomeScreen(apiService: apiService, unifiedPushService: unifiedPush),
        '/MainScreen': (context) => MainScreen(apiService: apiService),
        '/Notifications': (context) => NotificationsPage(apiService: apiService),
        '/EditProfile': (context) => EditProfilePage(apiService: apiService),
        '/Settings': (context) => SettingsPage(apiService: apiService),
        '/UserProfile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return UserProfilePage(apiService: apiService, userId: args['userId']);
        },
        '/FollowersList': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return FollowersListPage(
            apiService: apiService,
            userId: args['userId'],
            isFollowers: args['isFollowers'],
          );
        },
        '/Bookmarks': (context) => BookmarksPage(apiService: apiService),
        '/LikedPosts': (context) => LikedPostsPage(apiService: apiService),
        '/PostDetail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PostDetailPage(apiService: apiService, post: args['post']);
        },
        '/statusDetail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return FutureBuilder<Status>(
            future: apiService.getStatus(args['statusId']),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return PostDetailPage(apiService: apiService, post: snapshot.data!);
              } else if (snapshot.hasError) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Error')),
                  body: Center(child: Text('Failed to load post: ${snapshot.error}')),
                );
              }
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Color(0xFF00F3FF))),
              );
            },
          );
        },
        '/DirectMessages': (context) => DirectMessagesPage(apiService: apiService),
        '/TimeLine': (context) =>
            Timeline(apiService: apiService, typeTimeLine: "home"),
        '/Local': (context) =>
            Timeline(apiService: apiService, typeTimeLine: "public"),
        '/Photo': (context) =>
            Timeline(apiService: apiService, typeTimeLine: "home"),
        '/Bookmark': (context) =>
            BookmarksPage(apiService: apiService),
        '/Profile': (context) => Profile(apiService: apiService),
        '/Live': (context) =>
            Timeline(apiService: apiService, typeTimeLine: "public"),
        '/Camera': (context) => CameraScreen(apiService: apiService),
        '/Notification': (context) => Notif(apiService: apiService),
        '/View': (context) => const post_view.View(),
        '/Search': (context) =>
            SearchPage(apiService: apiService),
        '/Desc': (context) => Desc(apiService: apiService),
        '/sendPosts': (context) => sendPosts(apiService: apiService),
        '/presentation': (context) => const presentation(),
      },
    );
  }
}
