// Modern Instagram-style timeline
import 'dart:io';

import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/widgets/instagram_post_card.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

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

  late final PagingController<String?, Status> _pagingController = PagingController(
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
         return await widget.apiService.getStatusList(key, _pageSize, widget.typeTimeLine);
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
              title: const Text('Exit App?'),
              content: const Text('Do you want to exit the app?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => exit(0),
                  child: const Text('Exit'),
                ),
              ],
            ),
          )) ??
          false;
    }
    return true;
  }

  void _handleLike(Status status) {
    // TODO: Implement like functionality
    appLogger.debug('Like tapped: ${status.id}');
    widget.apiService.favoriteStatus(status.id);
  }

  void _handleComment(Status status) {
    Navigator.pushNamed(
      context,
      '/PostDetail',
      arguments: {'post': status},
    );
  }

  void _handleShare(Status status) {
    // TODO: Implement share functionality
    appLogger.debug('Share tapped: ${status.id}');
  }

  void _handleBookmark(Status status) {
    // TODO: Implement bookmark functionality
    appLogger.debug('Bookmark tapped: ${status.id}');
  }

  void _handleProfileTap(Status status) {
    // TODO: Navigate to profile
    appLogger.debug('Profile tapped: ${status.account.id}');
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = widget.typeTimeLine == 'home' ? 'FediSpace' : 'Explore';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.pushNamed(context, '/Notifications');
              },
            ),
            IconButton(
              icon: const Icon(Icons.send_outlined),
              onPressed: () {
                Navigator.pushNamed(context, '/DirectMessages');
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => Future.sync(_pagingController.refresh),
          child: ValueListenableBuilder<PagingState<String?, Status>>(
            valueListenable: _pagingController,
            builder: (context, state, child) => PagedListView<String?, Status>(
              state: state,
              fetchNextPage: _pagingController.fetchNextPage,
              padding: EdgeInsets.zero,
              builderDelegate: PagedChildBuilderDelegate<Status>(
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
                      const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load posts',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_pagingController.error}',
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _pagingController.refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                firstPageProgressIndicatorBuilder: (context) => const Center(
                  child: InstagramLoadingIndicator(size: 32),
                ),
                newPageProgressIndicatorBuilder: (context) => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: InstagramLoadingIndicator(size: 24),
                  ),
                ),
                noItemsFoundIndicatorBuilder: (context) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No posts yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Follow people to see their posts here',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
