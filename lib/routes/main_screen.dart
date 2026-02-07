import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/widgets/instagram_bottom_nav.dart';
import 'package:fedispace/routes/timeline/timeline_modern.dart';
import 'package:fedispace/routes/search/search_page.dart';
import 'package:fedispace/routes/profile/profile.dart';

/// Main screen with Instagram-style bottom navigation
/// Handles navigation between Home, Search, Create, Stories/Reels, and Profile
class MainScreen extends StatefulWidget {
  final ApiService apiService;

  const MainScreen({Key? key, required this.apiService}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
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
        // Create post (placeholder for now)
        return _CreatePlaceholder();
      case 3:
        // Stories/Reels (placeholder for now)
        return _StoriesPlaceholder();
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

class _SearchPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search Coming Soon',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Search for users, hashtags, and posts',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_box_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Create Post Coming Soon',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Share photos and videos with your followers',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoriesPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stories'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Stories Coming Soon',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'View and share ephemeral content',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
