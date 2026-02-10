// Modern Instagram-style timeline with 3-tab Fediverse support
import 'dart:io';
import 'dart:math' as math;

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

class _TimelineState extends State<Timeline> with TickerProviderStateMixin {
  late final TabController _tabController;
  late final List<_TimelineTab> _tabs;

  // Logo animation controllers
  late final AnimationController _shimmerController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    // Shimmer animation — gradient sweep across the logo
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    // Glow pulse — subtle breathing neon glow
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Only show tabs when on the main home screen
    if (widget.typeTimeLine == 'home') {
      _tabs = [
        _TimelineTab(label: 'Accueil', type: 'home', icon: Icons.home_rounded),
        _TimelineTab(label: 'Local', type: 'local', icon: Icons.people_rounded),
        _TimelineTab(label: 'Fédéré', type: 'federated', icon: Icons.public_rounded),
      ];
      _tabController = TabController(length: _tabs.length, vsync: this);
    } else {
      _tabs = [
        _TimelineTab(label: widget.typeTimeLine, type: widget.typeTimeLine, icon: Icons.list),
      ];
      _tabController = TabController(length: 1, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _shimmerController.dispose();
    _glowController.dispose();
    super.dispose();
  }

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

  /// Builds the ultra-premium animated neon logo
  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_shimmerController, _glowController]),
      builder: (context, child) {
        final shimmerValue = _shimmerController.value;
        final glowValue = _glowController.value;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Glow shadow layer — breathing neon pulse
            Positioned.fill(
              child: Opacity(
                opacity: 0.3 + (glowValue * 0.4),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: const [
                      CyberpunkTheme.neonCyan,
                      CyberpunkTheme.neonPink,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'FediSpace',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: CyberpunkTheme.neonCyan.withOpacity(0.8),
                          blurRadius: 20 + (glowValue * 15),
                        ),
                        Shadow(
                          color: CyberpunkTheme.neonPink.withOpacity(0.5),
                          blurRadius: 30 + (glowValue * 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Main text — holographic gradient shimmer
            ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment(-1.0 + (shimmerValue * 3.0), 0.0),
                  end: Alignment(0.0 + (shimmerValue * 3.0), 0.0),
                  colors: const [
                    CyberpunkTheme.neonCyan,
                    CyberpunkTheme.neonPink,
                    CyberpunkTheme.neonYellow,
                    CyberpunkTheme.neonCyan,
                  ],
                  stops: const [0.0, 0.33, 0.66, 1.0],
                  tileMode: TileMode.mirror,
                ).createShader(bounds);
              },
              child: Text(
                'FediSpace',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Colors.white, // Required for ShaderMask
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // If not the home screen, show a single timeline without tabs
    if (widget.typeTimeLine != 'home') {
      return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: CyberpunkTheme.backgroundBlack,
          body: _TimelineFeed(
            apiService: widget.apiService,
            typeTimeLine: widget.typeTimeLine,
            showStoryBar: false,
          ),
        ),
      );
    }

    // Home screen: show 3-tab layout
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: CyberpunkTheme.backgroundBlack,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: true,
              backgroundColor: CyberpunkTheme.backgroundBlack,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: _buildAnimatedLogo(),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(44),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: CyberpunkTheme.borderDark,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: CyberpunkTheme.neonCyan,
                    unselectedLabelColor: CyberpunkTheme.textTertiary,
                    labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    indicatorColor: CyberpunkTheme.neonCyan,
                    indicatorWeight: 2.5,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerHeight: 0,
                    tabs: _tabs.map((tab) => Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tab.icon, size: 16),
                          const SizedBox(width: 6),
                          Text(tab.label),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: _tabs.map((tab) => _TimelineFeed(
              apiService: widget.apiService,
              typeTimeLine: tab.type,
              showStoryBar: tab.type == 'home',
            )).toList(),
          ),
        ),
      ),
    );
  }
}

/// Data class for tab configuration
class _TimelineTab {
  final String label;
  final String type;
  final IconData icon;

  const _TimelineTab({
    required this.label,
    required this.type,
    required this.icon,
  });
}

/// Individual timeline feed widget (used for each tab)
class _TimelineFeed extends StatefulWidget {
  final ApiService apiService;
  final String typeTimeLine;
  final bool showStoryBar;

  const _TimelineFeed({
    required this.apiService,
    required this.typeTimeLine,
    this.showStoryBar = false,
  });

  @override
  State<_TimelineFeed> createState() => _TimelineFeedState();
}

class _TimelineFeedState extends State<_TimelineFeed> with AutomaticKeepAliveClientMixin {
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
         appLogger.debug('Fetching ${widget.typeTimeLine} timeline page: $key');
         final List<model.Status> newItems = await widget.apiService.getStatusList(key, _pageSize, widget.typeTimeLine);
         return newItems;
       } catch (error, stackTrace) {
          appLogger.error('Error fetching ${widget.typeTimeLine} timeline', error, stackTrace);
          rethrow;
       }
    },
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  void _handleLike(dynamic post) async {
    appLogger.debug('Like tapped');
    try {
      if (post.favourited == true) {
        await widget.apiService.undoFavoriteStatus(post.id);
      } else {
        await widget.apiService.favoriteStatus(post.id);
      }
      _pagingController.refresh();
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
      _pagingController.refresh();
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
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
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
              itemBuilder: (context, status, index) {
                return Column(
                  children: [
                    // Show story bar before the first item on home tab
                    if (index == 0 && widget.showStoryBar)
                      StoryBar(apiService: widget.apiService),
                    InstagramPostCard(
                      status: status,
                      onLike: () => _handleLike(status),
                      onComment: () => _handleComment(status),
                      onShare: () => _handleShare(status),
                      onBookmark: () => _handleBookmark(status),
                      onProfileTap: () => _handleProfileTap(status),
                    ),
                  ],
                );
              },
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
                    Text(
                      _getEmptyMessage(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CyberpunkTheme.textWhite),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getEmptySubMessage(),
                      style: const TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getEmptyMessage() {
    switch (widget.typeTimeLine) {
      case 'home':
        return 'No posts yet';
      case 'local':
        return 'No local posts';
      case 'federated':
        return 'No federated posts';
      default:
        return 'No posts';
    }
  }

  String _getEmptySubMessage() {
    switch (widget.typeTimeLine) {
      case 'home':
        return 'Follow people to see their posts here';
      case 'local':
        return 'No one on your server has posted yet';
      case 'federated':
        return 'No posts from the fediverse yet';
      default:
        return '';
    }
  }
}
