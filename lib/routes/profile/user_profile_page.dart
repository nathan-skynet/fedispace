import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/models/accountUsers.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:fedispace/widgets/instagram_post_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Instagram-style user profile page for viewing other users
class UserProfilePage extends StatefulWidget {
  final ApiService apiService;
  final String userId;

  const UserProfilePage({
    Key? key,
    required this.apiService,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  AccountUsers? _account;
  List<Status> _posts = [];
  bool _isLoading = true;
  bool _isLoadingPosts = false;
  bool _isFollowing = false;
  
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      appLogger.debug('Loading user profile: ${widget.userId}');
      final account = await widget.apiService.getUserAccount(widget.userId);
      setState(() {
        _account = account;
        _isFollowing = account.following ?? false;
        _isLoading = false;
      });
      _loadPosts();
    } catch (error, stackTrace) {
      appLogger.error('Error loading profile', error, stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoadingPosts = true;
    });

    try {
      final response =
          await widget.apiService.getUserStatus(widget.userId, 1, null);
      final List<dynamic> postsData = response as List<dynamic>;
      setState(() {
        _posts = postsData
            .map((data) => Status.fromJson(data as Map<String, dynamic>))
            .toList();
        _isLoadingPosts = false;
      });
    } catch (error, stackTrace) {
      appLogger.error('Error loading posts', error, stackTrace);
      setState(() {
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    try {
      if (_isFollowing) {
        await widget.apiService.unFollow(widget.userId);
      } else {
        await widget.apiService.followStatus(widget.userId);
      }
      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (error, stackTrace) {
      appLogger.error('Error toggling follow', error, stackTrace);
    }
  }

  void _navigateToFollowers() {
    Navigator.pushNamed(
      context,
      '/FollowersList',
      arguments: {'userId': widget.userId, 'isFollowers': true},
    );
  }

  void _navigateToFollowing() {
    Navigator.pushNamed(
      context,
      '/FollowersList',
      arguments: {'userId': widget.userId, 'isFollowers': false},
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: InstagramLoadingIndicator(size: 32)),
      );
    }

    if (_account == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Profile not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_account!.username),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show options menu
            },
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(isDark),
                  _buildStats(),
                  _buildBio(),
                  _buildActionButtons(),
                  const SizedBox(height: 16),
                  const InstagramDivider(),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  onTap: (index) => setState(() => _currentTab = index),
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on)),
                    Tab(icon: Icon(Icons.person_pin_outlined)),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsGrid(),
            _buildTaggedGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: _account!.avatar.isNotEmpty
                ? CachedNetworkImageProvider(_account!.avatar)
                : null,
            child: _account!.avatar.isEmpty
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn(
                    _account!.statuses_count?.toString() ?? '0', 'Posts'),
                GestureDetector(
                  onTap: _navigateToFollowers,
                  child: _buildStatColumn(
                      _account!.followers_count?.toString() ?? '0',
                      'Followers'),
                ),
                GestureDetector(
                  onTap: _navigateToFollowing,
                  child: _buildStatColumn(
                      _account!.following_count?.toString() ?? '0',
                      'Following'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFA8A8A8)
                : const Color(0xFF8E8E8E),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return const SizedBox.shrink();
  }

  Widget _buildBio() {
    if (_account!.display_name.isEmpty && _account!.note.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_account!.display_name.isNotEmpty)
            Text(
              _account!.display_name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (_account!.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _account!.note.replaceAll(RegExp(r'<[^>]*>'), ''),
              style: const TextStyle(fontSize: 14),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: InstagramFollowButton(
              isFollowing: _isFollowing,
              onPressed: _toggleFollow,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 30,
            child: OutlinedButton(
              onPressed: () {
                // TODO: Message user
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Icon(Icons.mail_outline, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsGrid() {
    if (_isLoadingPosts) {
      return const Center(child: InstagramLoadingIndicator(size: 32));
    }

    if (_posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Posts Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return GestureDetector(
          onTap: () {
            // TODO: Navigate to post detail
          },
          child: CachedNetworkImage(
            imageUrl: post.attach,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[300]),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaggedGrid() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_pin_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Tagged Posts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}
