import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:camera/camera.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/notification.dart';
import 'package:fedispace/core/unifiedpush.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/routes/homepage/homepage.dart';
import 'package:fedispace/routes/post/desc.dart';
import 'package:fedispace/routes/post/send.dart';
import 'package:fedispace/widgets/story_viewer.dart';
import 'package:fedispace/routes/post/takecamera.dart';
import 'package:fedispace/routes/post/view.dart' as post_view;
import 'package:fedispace/routes/presentation/home.dart';
import 'package:fedispace/routes/profile/profile.dart';
import 'package:fedispace/routes/timeline/timeline.dart';
import 'package:fedispace/routes/main_screen.dart';
import 'package:fedispace/routes/notifications/notifications_page.dart';
import 'package:fedispace/routes/profile/edit_profile.dart';
import 'package:fedispace/routes/profile/user_profile_page.dart';
import 'package:fedispace/routes/timeline/tag_timeline.dart';
import 'package:fedispace/routes/followers/followers_list_page.dart';
import 'package:fedispace/routes/bookmarks/bookmarks_page.dart';
import 'package:fedispace/routes/liked/liked_posts_page.dart';
import 'package:fedispace/routes/post/post_detail_page.dart';
import 'package:fedispace/routes/messages/direct_messages_page.dart';
import 'package:fedispace/routes/settings/settings_page.dart';
import 'package:fedispace/routes/settings/muted_blocked_page.dart';
import 'package:fedispace/routes/search/search_page.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:fedispace/routes/messages/conversation_detail_page.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:flutter/material.dart';

/// Global navigator key for notification-based navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

List<CameraDescription> cameras = [];

const String isolateName = 'isolate';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(MyApp());
}

// Main Class
class MyApp extends StatefulWidget {
  final apiService = ApiService();
  final unifiedPush = UnifiedPushService();

  MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late StreamSubscription _intentSub;
  final title = 'Fedi Space';

  void _setupNotificationListeners() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onNotificationAction,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _onNotificationAction(ReceivedAction receivedAction) async {
    final payload = receivedAction.payload;
    if (payload != null && payload['type'] == 'dm') {
      final context = navigatorKey.currentContext;
      if (context == null) return;
      
      // Navigate to the DM list; the user can then select the conversation
      Navigator.of(context).pushNamed('/DirectMessages');
    }
  }

  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
    _setupNotificationListeners();
    _setupShareIntentListener();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_locale');
    if (code != null && code.isNotEmpty) {
      setState(() { _locale = Locale(code); });
    }
  }

  void setLocale(Locale locale) {
    setState(() { _locale = locale; });
  }

  @override
  void dispose() {
    _intentSub.cancel();
    super.dispose();
  }

  void _setupShareIntentListener() {
    // Handle shared content when app is opened from share
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedFiles(value);
      }
    });

    // Handle shared content while app is running
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedFiles(value);
      }
    });
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    // Wait a moment for navigation to be ready
    Future.delayed(const Duration(milliseconds: 500), () {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      // Collect image paths
      final imagePaths = files
          .where((f) => f.type == SharedMediaType.image)
          .map((f) => f.path)
          .toList();

      // Collect text
      final textFiles = files.where((f) => f.type == SharedMediaType.text).toList();
      final sharedText = textFiles.isNotEmpty ? textFiles.first.path : null;

      if (imagePaths.isNotEmpty || sharedText != null) {
        Navigator.of(context).pushNamed('/sendPosts', arguments: {
          'sharedImages': imagePaths,
          'sharedText': sharedText,
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: title,
      theme: CyberpunkTheme.theme,
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (_locale != null) return _locale;
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale?.languageCode) return supported;
        }
        return supportedLocales.first;
      },
      initialRoute: '/Login',
      routes: {
        '/Login': (context) =>
            HomeScreen(apiService: widget.apiService, unifiedPushService: widget.unifiedPush),
        '/MainScreen': (context) => MainScreen(apiService: widget.apiService),
        '/Notifications': (context) => NotificationsPage(apiService: widget.apiService),
        '/EditProfile': (context) => EditProfilePage(apiService: widget.apiService),
        '/Settings': (context) => SettingsPage(apiService: widget.apiService),
        '/MutedBlocked': (context) => MutedBlockedPage(apiService: widget.apiService),
        '/UserProfile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return UserProfilePage(apiService: widget.apiService, userId: args['userId']);
        },
        '/FollowersList': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return FollowersListPage(
            apiService: widget.apiService,
            userId: args['userId'],
            isFollowers: args['isFollowers'],
          );
        },
        '/Bookmarks': (context) => BookmarksPage(apiService: widget.apiService),
        '/LikedPosts': (context) => LikedPostsPage(apiService: widget.apiService),
        '/PostDetail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PostDetailPage(apiService: widget.apiService, post: args['post']);
        },
        '/statusDetail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return FutureBuilder<Status>(
            future: widget.apiService.getStatus(args['statusId']),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return PostDetailPage(apiService: widget.apiService, post: snapshot.data!);
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
        '/DirectMessages': (context) => DirectMessagesPage(apiService: widget.apiService),
        '/TimeLine': (context) =>
            Timeline(apiService: widget.apiService, typeTimeLine: "home"),
        '/Local': (context) =>
            Timeline(apiService: widget.apiService, typeTimeLine: "public"),
        '/Photo': (context) =>
            Timeline(apiService: widget.apiService, typeTimeLine: "home"),
        '/Bookmark': (context) =>
            BookmarksPage(apiService: widget.apiService),
        '/Profile': (context) => Profile(apiService: widget.apiService),
        '/Live': (context) =>
            Timeline(apiService: widget.apiService, typeTimeLine: "public"),
        '/Camera': (context) => CameraScreen(apiService: widget.apiService),
        '/StoryViewer': (context) => StoryViewer(
            story: (ModalRoute.of(context)!.settings.arguments as Map)['story'],
            apiService: widget.apiService,
          ),
        '/Notification': (context) => Notif(apiService: widget.apiService),
        '/View': (context) => const post_view.View(),
        '/Search': (context) =>
            SearchPage(apiService: widget.apiService),
        '/Desc': (context) => Desc(apiService: widget.apiService),
        '/sendPosts': (context) => sendPosts(apiService: widget.apiService),
        '/presentation': (context) => const presentation(),
        '/TagTimeline': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return TagTimeline(apiService: widget.apiService, tag: args['tag']);
        },
      },
    );
  }
}
