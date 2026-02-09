// Modern Instagram-style timeline
import 'dart:io';

import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/models/status.dart' as model;
import 'package:fedispace/widgets/instagram_post_card.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:fedispace/utils/social_actions.dart';
import 'package:fedispace/widgets/story_bar.dart';
import 'package:google_fonts/google_fonts.dart';

class Timeline extends StatefulWidget {
  final ApiService apiService;
  final String typeTimeLine;

  const Timeline({
    Key? key,
    required this.apiService,
    required this.typeTimeLine,
  }) : super(key: key);

  @override
  State<Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  static const _pageSize = 20;

  late final PagingController<String?, model.Status> _pagingController = PagingController(
    getNextPageKey: (state) {
      if ((state.pages ?? []).isEmpty) return "";
      final lastPage = state.pages!.last;
      if (lastPage.length < _pageSize) return null;
      return lastPage.last.id;
    },
    fetchPage: (pageKey) async {
       try {
         final key = (pageKey == "" || pageKey == null) ? null : pageKey;
         appLogger.debug('Fetching timeline page: $key');
         final List<model.Status> newItems = await widget.apiService.getStatusList(key, _pageSize, widget.typeTimeLine);
         return newItems;
       } catch (error, stackTrace) {
          appLogger.error('Error fetching timeline', error, stackTrace);
          rethrow;
       }
    },
  );

  Future<bool> _onWillPop() async {
    if (widget.typeTimeLine == 'home') {
      return (await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: CyberpunkTheme.cardDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Exit App?', style: TextStyle(color: CyberpunkTheme.textWhite)),
              content: const Text('Do you want to exit the app?', style: TextStyle(color: CyberpunkTheme.textSecondary)),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel', style: TextStyle(color: CyberpunkTheme.textSecondary)),
                ),
                TextButton(
                  onPressed: () => exit(0),
                  child: const Text('Exit', style: TextStyle(color: CyberpunkTheme.neonPink)),
                ),
              ],
            ),
          )) ??
          false;
    }
    return true;
  }

  void _loadPosts() {
    _pagingController.refresh();
  }

  void _handleLike(dynamic post) async {
    appLogger.debug('Like tapped');
    try {
      if (post.favourited == true) {
        await widget.apiService.undoFavoriteStatus(post.id);
      } else {
        await widget.apiService.favoriteStatus(post.id);
      }
      _loadPosts();
    } catch (e) {
      appLogger.error('Failed to toggle like', e);
    }
  }

  void _handleComment(model.Status status) {
    Navigator.pushNamed(
      context,
      '/PostDetail',
      arguments: {'post': status},
    );
  }

  void _handleShare(dynamic post) {
    SocialActions.shareStatus(post);
  }

  void _handleBookmark(dynamic post) async {
    try {
      if (post.bookmarked == true) {
        await widget.apiService.undoBookmarkStatus(post.id);
      } else {
        await widget.apiService.bookmarkStatus(post.id);
      }
      _loadPosts();
    } catch (e) {
      appLogger.error('Failed to toggle bookmark', e);
    }
  }

  void _handleProfileTap(dynamic post) {
    if (post.account != null) {
      Navigator.pushNamed(context, '/UserProfile', arguments: {'userId': post.account.id});
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: CyberpunkTheme.backgroundBlack,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: CyberpunkTheme.backgroundBlack,
              elevation: 0,
              toolbarHeight: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0.5),
                child: Container(height: 0.5, color: CyberpunkTheme.borderDark),
              ),
            ),
            SliverToBoxAdapter(
              child: StoryBar(apiService: widget.apiService),
            ),
          ],
          body: RefreshIndicator(
            color: CyberpunkTheme.neonCyan,
            backgroundColor: CyberpunkTheme.cardDark,
            onRefresh: () => Future.sync(_pagingController.refresh),
            child: ValueListenableBuilder<PagingState<String?, model.Status>>(
              valueListenable: _pagingController,
              builder: (context, state, child) {
                return PagedListView<String?, model.Status>(
                  state: state,
                  fetchNextPage: _pagingController.fetchNextPage,
                  builderDelegate: PagedChildBuilderDelegate<model.Status>(
                    itemBuilder: (context, status, index) => InstagramPostCard(
                      status: status,
                      onLike: () => _handleLike(status),
                      onComment: () => _handleComment(status),
                      onShare: () => _handleShare(status),
                      onBookmark: () => _handleBookmark(status),
                      onProfileTap: () => _handleProfileTap(status),
                    ),
                    firstPageErrorIndicatorBuilder: (context) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off_rounded, size: 48, color: CyberpunkTheme.textTertiary),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load posts',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CyberpunkTheme.textWhite),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${state.error}',
                            style: const TextStyle(color: CyberpunkTheme.textTertiary, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: _pagingController.refresh,
                            style: TextButton.styleFrom(
                              foregroundColor: CyberpunkTheme.neonCyan,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: CyberpunkTheme.neonCyan.withOpacity(0.3)),
                              ),
                            ),
                            child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    firstPageProgressIndicatorBuilder: (context) => const Center(
                      child: InstagramLoadingIndicator(size: 32),
                    ),
                    newPageProgressIndicatorBuilder: (context) => const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: InstagramLoadingIndicator(size: 24)),
                    ),
                    noItemsFoundIndicatorBuilder: (context) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.explore_outlined, size: 64, color: CyberpunkTheme.neonCyan.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          const Text(
                            'No posts yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CyberpunkTheme.textWhite),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Follow people to see their posts here',
                            style: TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
