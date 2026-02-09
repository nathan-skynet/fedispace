import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/widgets/instagram_bottom_nav.dart';
import 'package:fedispace/routes/timeline/timeline_modern.dart';
import 'package:fedispace/routes/search/search_page.dart';
import 'package:fedispace/routes/profile/profile.dart';
import 'package:fedispace/core/notification_service.dart';
import 'package:fedispace/routes/messages/direct_messages_page.dart';
import 'package:fedispace/routes/post/send.dart';

/// Main screen with Instagram-style bottom navigation
/// Handles navigation between Home, Search, Create, Stories/Reels, and Profile
class MainScreen extends StatefulWidget {
  final ApiService apiService;

  const MainScreen({Key? key, required this.apiService}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initNotifications();
    _loadProfileImage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationPollingService().stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationPollingService().startPolling();
    } else if (state == AppLifecycleState.paused) {
      NotificationPollingService().stopPolling();
    }
  }

  void _initNotifications() {
     NotificationPollingService().init(widget.apiService);
     NotificationPollingService().startPolling();
  }

  Future<void> _loadProfileImage() async {
    try {
      final account = await widget.apiService.getCurrentAccount();
      setState(() {
        _profileImageUrl = account.avatar;
      });
    } catch (e) {
      // Ignore error, will show default avatar
    }
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      // Create Post - Push as modal/page instead of switching tab
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => sendPosts(apiService: widget.apiService),
        ),
      );
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        // Home timeline
        return Timeline(
          apiService: widget.apiService,
          typeTimeLine: 'home',
        );
      case 1:
        // Search
        return SearchPage(apiService: widget.apiService);
      case 2:
        // Create post (modal - technically unreachable via tab tap now)
        return Container();
      case 3:
        // Direct Messages & Stories
        return DirectMessagesPage(apiService: widget.apiService);
      case 4:
        // Profile
        return Profile(apiService: widget.apiService);
      default:
        return Timeline(
          apiService: widget.apiService,
          typeTimeLine: 'home',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getCurrentPage(),
      bottomNavigationBar: InstagramBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        profileImageUrl: _profileImageUrl,
      ),
    );
  }
}

// Placeholder widgets for features not yet implemented

// End of MainScreen
