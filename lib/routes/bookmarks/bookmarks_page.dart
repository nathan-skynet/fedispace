import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/widgets/instagram_post_card.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:fedispace/utils/social_actions.dart';

/// Instagram-style bookmarks page
class BookmarksPage extends StatefulWidget {
  final ApiService apiService;

  const BookmarksPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  List<Status> _bookmarks = [];
  bool _isLoading = true;
  String? _nextPageId;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks({String? maxId}) async {
    setState(() {
      _isLoading = maxId == null;
    });

    try {
      appLogger.debug('Loading bookmarks');
      final bookmarks = await widget.apiService.getBookmarks(
        maxId: maxId,
        limit: 20,
      );

      setState(() {
        if (maxId == null) {
          _bookmarks = bookmarks;
        } else {
          _bookmarks.addAll(bookmarks);
        }
        _nextPageId = bookmarks.isNotEmpty ? bookmarks.last.id : null;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      appLogger.error('Error loading bookmarks', error, stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleLike(Status status) {
    widget.apiService.favoriteStatus(status.id);
  }

  void _handleComment(Status status) {
    // TODO: Navigate to comments
    appLogger.debug('Comment tapped: ${status.id}');
  }

  void _handleShare(Status status) {
    SocialActions.shareStatus(status);
  }

  void _handleBookmark(Status status) {
    // Remove from bookmarks
    setState(() {
      _bookmarks.removeWhere((b) => b.id == status.id);
    });
    // TODO: Call API to remove bookmark
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
        title: Text(S.of(context).bookmarks),
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: InstagramLoadingIndicator(size: 32));
    }

    if (_bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).bookmarks,
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
                'Save photos and videos that you want to see again. No one is notified, and only you can see what you\'ve saved.',
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
      onRefresh: () => _loadBookmarks(),
      child: ListView.builder(
        itemCount: _bookmarks.length + (_nextPageId != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _bookmarks.length) {
            // Load more
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: TextButton(
                  onPressed: () => _loadBookmarks(maxId: _nextPageId),
                  child: Text(S.of(context).loading),
                ),
              ),
            );
          }

          final bookmark = _bookmarks[index];
          return InstagramPostCard(
            status: bookmark,
            onLike: () => _handleLike(bookmark),
            onComment: () => _handleComment(bookmark),
            onShare: () => _handleShare(bookmark),
            onBookmark: () => _handleBookmark(bookmark),
            onProfileTap: () => _handleProfileTap(bookmark),
          );
        },
      ),
    );
  }
}
