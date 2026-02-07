import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/widgets/instagram_post_card.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';

/// Instagram-style liked posts page
class LikedPostsPage extends StatefulWidget {
  final ApiService apiService;

  const LikedPostsPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<LikedPostsPage> createState() => _LikedPostsPageState();
}

class _LikedPostsPageState extends State<LikedPostsPage> {
  List<Status> _likedPosts = [];
  bool _isLoading = true;
  String? _nextPageId;

  @override
  void initState() {
    super.initState();
    _loadLikedPosts();
  }

  Future<void> _loadLikedPosts({String? maxId}) async {
    setState(() {
      _isLoading = maxId == null;
    });

    try {
      appLogger.debug('Loading liked posts');
      // Using favorites endpoint
      final response = await widget.apiService.getFav(maxId);
      
      final List<Status> posts = response;

      setState(() {
        if (maxId == null) {
          _likedPosts = posts;
        } else {
          _likedPosts.addAll(posts);
        }
        _nextPageId = posts.isNotEmpty ? posts.last.id : null;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      appLogger.error('Error loading liked posts', error, stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleLike(Status status) {
    // Unlike the post
    setState(() {
      _likedPosts.removeWhere((p) => p.id == status.id);
    });
    widget.apiService.favoriteStatus(status.id);
  }

  void _handleComment(Status status) {
    // TODO: Navigate to comments
    appLogger.debug('Comment tapped: ${status.id}');
  }

  void _handleShare(Status status) {
    // TODO: Implement share
    appLogger.debug('Share tapped: ${status.id}');
  }

  void _handleBookmark(Status status) {
    // TODO: Implement bookmark
    appLogger.debug('Bookmark tapped: ${status.id}');
  }

  void _handleProfileTap(Status status) {
    Navigator.pushNamed(
      context,
      '/UserProfile',
      arguments: {'userId': status.account.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liked Posts'),
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: InstagramLoadingIndicator(size: 32));
    }

    if (_likedPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            const SizedBox(height: 16),
            Text(
              'No Liked Posts',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'When you like posts, they\'ll appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadLikedPosts(),
      child: ListView.builder(
        itemCount: _likedPosts.length + (_nextPageId != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _likedPosts.length) {
            // Load more
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: TextButton(
                  onPressed: () => _loadLikedPosts(maxId: _nextPageId),
                  child: const Text('Load More'),
                ),
              ),
            );
          }

          final post = _likedPosts[index];
          return InstagramPostCard(
            status: post,
            onLike: () => _handleLike(post),
            onComment: () => _handleComment(post),
            onShare: () => _handleShare(post),
            onBookmark: () => _handleBookmark(post),
            onProfileTap: () => _handleProfileTap(post),
          );
        },
      ),
    );
  }
}
