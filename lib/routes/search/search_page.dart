import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/models/accountUsers.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchPage extends StatefulWidget {
  final ApiService apiService;

  const SearchPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Search results
  List<AccountUsers> _accountResults = [];
  List<Status> _statusResults = [];
  List<Map<String, dynamic>> _hashtagResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  // Discover / Trending
  List<Status> _trendingPosts = [];
  List<Status> _discoverPosts = [];
  List<AccountUsers> _popularAccounts = [];  // fix: was Account
  List<Map<String, dynamic>> _trendingHashtags = [];
  List<AccountUsers> _suggestions = [];
  bool _isLoadingDiscover = true;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _loadDiscover();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadDiscover() async {
    try {
      final trending = await widget.apiService.getTrendingPosts(limit: 20);
      final discover = await widget.apiService.discoverPosts(limit: 30);
      // For popular accounts, we get Account objects but our UI uses AccountUsers
      // We'll handle this by fetching popular accounts and converting
      List<AccountUsers> popular = [];
      try {
        final accounts = await widget.apiService.discoverPopularAccounts(limit: 10);
        popular = accounts.map((a) => AccountUsers(
          id: a.id ?? '',
          username: a.username ?? '',
          displayName: a.display_name ?? '',
          acct: a.username ?? '',
          isLocked: false,
          isBot: false,
          avatarUrl: a.avatar ?? '',
          headerUrl: '',
          note: a.note ?? '',
          followers_count: a.followers_count ?? 0,
          following_count: a.following_count ?? 0,
          statuses_count: a.statuses_count ?? 0,
        )).toList();
      } catch (e) {
        appLogger.error('Error loading popular accounts', e);
      }

      // Load trending hashtags
      List<Map<String, dynamic>> hashtags = [];
      try {
        hashtags = await widget.apiService.discoverTrendingHashtags(limit: 10);
      } catch (e) {
        appLogger.error('Error loading trending hashtags', e);
      }

      // Load follow suggestions
      List<AccountUsers> suggestions = [];
      try {
        final suggestionAccounts = await widget.apiService.getSuggestions(limit: 8);
        suggestions = suggestionAccounts.map((a) => AccountUsers(
          id: a.id ?? '',
          username: a.username ?? '',
          displayName: a.display_name ?? '',
          acct: a.username ?? '',
          isLocked: false,
          isBot: false,
          avatarUrl: a.avatar ?? '',
          headerUrl: '',
          note: a.note ?? '',
          followers_count: a.followers_count ?? 0,
          following_count: a.following_count ?? 0,
          statuses_count: a.statuses_count ?? 0,
        )).toList();
      } catch (e) {
        appLogger.error('Error loading suggestions', e);
      }

      setState(() {
        _trendingPosts = trending;
        _discoverPosts = discover;
        _popularAccounts = popular;
        _trendingHashtags = hashtags;
        _suggestions = suggestions;
        _isLoadingDiscover = false;
      });
    } catch (e, s) {
      appLogger.error('Error loading discover', e, s);
      setState(() => _isLoadingDiscover = false);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _accountResults = [];
        _statusResults = [];
        _hashtagResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      appLogger.debug('V2 search: $query');
      final results = await widget.apiService.searchV2(query, limit: 40);

      final List<AccountUsers> accounts = [];
      if (results['accounts'] != null) {
        for (var a in results['accounts']) {
          try {
            accounts.add(AccountUsers(
              id: (a['id'] ?? '').toString(),
              username: a['username'] ?? '',
              displayName: a['display_name'] ?? '',
              acct: a['acct'] ?? a['username'] ?? '',
              isLocked: a['locked'] ?? false,
              isBot: a['bot'] ?? false,
              avatarUrl: a['avatar'] ?? '',
              headerUrl: a['header'] ?? '',
              note: a['note'] ?? '',
              followers_count: a['followers_count'] ?? 0,
              following_count: a['following_count'] ?? 0,
              statuses_count: a['statuses_count'] ?? 0,
            ));
          } catch (_) {}
        }
      }

      final List<Status> statuses = [];
      if (results['statuses'] != null) {
        for (var s in results['statuses']) {
          try {
            statuses.add(Status.fromJson(s));
          } catch (_) {}
        }
      }

      final List<Map<String, dynamic>> hashtags = [];
      if (results['hashtags'] != null) {
        for (var h in results['hashtags']) {
          if (h is Map<String, dynamic>) hashtags.add(h);
        }
      }

      setState(() {
        _accountResults = accounts;
        _statusResults = statuses;
        _hashtagResults = hashtags;
        _isSearching = false;
      });
    } catch (error, stackTrace) {
      appLogger.error('Search error', error, stackTrace);
      setState(() => _isSearching = false);
    }
  }

  void _navigateToProfile(AccountUsers account) {
    Navigator.pushNamed(context, '/UserProfile', arguments: {'userId': account.id});
  }

  void _navigateToPost(Status post) {
    Navigator.pushNamed(context, '/PostDetail', arguments: {
      'post': post,
      'apiService': widget.apiService,
    });
  }

  void _navigateToHashtag(String tag) {
    Navigator.pushNamed(context, '/HashtagTimeline', arguments: {'tag': tag});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      body: Stack(
        children: [
          // Ambient background glows
          Positioned(
            top: -120, right: -80,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 280, height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      CyberpunkTheme.neonCyan.withOpacity(0.06 + _pulseController.value * 0.03),
                      Colors.transparent,
                    ]),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -100, left: -60,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 220, height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      CyberpunkTheme.neonPink.withOpacity(0.04 + _pulseController.value * 0.02),
                      Colors.transparent,
                    ]),
                  ),
                );
              },
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Text(
                         S.of(context).explore,
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: CyberpunkTheme.textWhite,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: CyberpunkTheme.neonCyan,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: CyberpunkTheme.neonCyan.withOpacity(0.6), blurRadius: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: CyberpunkTheme.cardDark,
                      border: Border.all(
                        color: _focusNode.hasFocus
                            ? CyberpunkTheme.neonCyan.withOpacity(0.3)
                            : CyberpunkTheme.borderDark,
                        width: 1,
                      ),
                      boxShadow: _focusNode.hasFocus
                          ? [BoxShadow(color: CyberpunkTheme.neonCyan.withOpacity(0.05), blurRadius: 20, spreadRadius: 2)]
                          : null,
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: const TextStyle(color: CyberpunkTheme.textWhite, fontSize: 16),
                      decoration: InputDecoration(
                         hintText: S.of(context).searchHint,
                         hintStyle: TextStyle(color: CyberpunkTheme.textTertiary, fontSize: 16),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: _focusNode.hasFocus ? CyberpunkTheme.neonCyan : CyberpunkTheme.textTertiary,
                          size: 22,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: CyberpunkTheme.textTertiary),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _accountResults = [];
                                    _statusResults = [];
                                    _hashtagResults = [];
                                    _hasSearched = false;
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                      ),
                      onChanged: (value) {
                        setState(() {});
                        if (value.length >= 2) {
                          Future.delayed(const Duration(milliseconds: 400), () {
                            if (_searchController.text == value) _performSearch(value);
                          });
                        }
                      },
                      onSubmitted: _performSearch,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Results or Discover
                Expanded(child: _hasSearched ? _buildSearchResults() : _buildDiscoverContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Results ─────────────────────────────────────────────────

  Widget _buildSearchResults() {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32, height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(CyberpunkTheme.neonCyan),
              ),
            ),
            const SizedBox(height: 16),
             Text(S.of(context).searching, style: TextStyle(color: CyberpunkTheme.textTertiary, fontSize: 14)),
          ],
        ),
      );
    }

    final hasResults = _accountResults.isNotEmpty || _statusResults.isNotEmpty || _hashtagResults.isNotEmpty;
    if (!hasResults) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CyberpunkTheme.cardDark,
                border: Border.all(color: CyberpunkTheme.borderDark),
              ),
              child: const Icon(Icons.search_off_rounded, size: 32, color: CyberpunkTheme.textTertiary),
            ),
            const SizedBox(height: 20),
             Text(S.of(context).noResults, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CyberpunkTheme.textWhite)),
             const SizedBox(height: 6),
             Text(S.of(context).tryDifferentKeywords, style: const TextStyle(fontSize: 14, color: CyberpunkTheme.textTertiary)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        // Hashtags
        if (_hashtagResults.isNotEmpty) ...[
          _sectionHeader('Hashtags', Icons.tag_rounded),
          ..._hashtagResults.take(5).map((h) => _buildHashtagTile(h)),
          const SizedBox(height: 16),
        ],

        // Accounts
        if (_accountResults.isNotEmpty) ...[
           _sectionHeader(S.of(context).followers, Icons.people_outline_rounded),
          ..._accountResults.take(10).map((a) => _UserCard(
            account: a,
            onTap: () => _navigateToProfile(a),
            index: _accountResults.indexOf(a),
          )),
          const SizedBox(height: 16),
        ],

        // Posts
        if (_statusResults.isNotEmpty) ...[
           _sectionHeader(S.of(context).posts, Icons.grid_view_rounded),
          _buildPostGrid(_statusResults),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: CyberpunkTheme.neonCyan),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CyberpunkTheme.neonCyan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHashtagTile(Map<String, dynamic> hashtag) {
    final name = hashtag['name'] ?? '';
    final url = hashtag['url'] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToHashtag(name),
          borderRadius: BorderRadius.circular(12),
          splashColor: CyberpunkTheme.neonCyan.withOpacity(0.06),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: CyberpunkTheme.cardDark,
              border: Border.all(color: CyberpunkTheme.borderDark, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CyberpunkTheme.neonCyan.withOpacity(0.1),
                    border: Border.all(color: CyberpunkTheme.neonCyan.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.tag_rounded, size: 18, color: CyberpunkTheme.neonCyan),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '#$name',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CyberpunkTheme.textWhite),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: CyberpunkTheme.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Discover Content (shown when not searching) ────────────────────

  Widget _buildDiscoverContent() {
    if (_isLoadingDiscover) {
      return Center(
        child: SizedBox(
          width: 32, height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(CyberpunkTheme.neonCyan),
          ),
        ),
      );
    }

    final hasTrending = _trendingPosts.isNotEmpty;
    final hasDiscover = _discoverPosts.isNotEmpty;
    final hasPopular = _popularAccounts.isNotEmpty;
    final hasHashtags = _trendingHashtags.isNotEmpty;
    final hasSuggestions = _suggestions.isNotEmpty;

    if (!hasTrending && !hasDiscover && !hasPopular && !hasHashtags && !hasSuggestions) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadDiscover,
      color: CyberpunkTheme.neonCyan,
      backgroundColor: CyberpunkTheme.cardDark,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        children: [
          // Trending Hashtags
          if (hasHashtags) ...[
            _sectionHeader('Trending Hashtags', Icons.tag_rounded),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _trendingHashtags.take(8).map((t) {
                final name = t['name'] ?? t['hashtag'] ?? '';
                final uses = t['history'] is List && (t['history'] as List).isNotEmpty
                    ? (t['history'] as List).first['uses'] ?? ''
                    : t['count'] ?? '';
                return GestureDetector(
                  onTap: () => _navigateToHashtag(name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [CyberpunkTheme.neonCyan.withOpacity(0.15), CyberpunkTheme.pinkMuted.withOpacity(0.1)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: CyberpunkTheme.neonCyan.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('#$name', style: const TextStyle(color: CyberpunkTheme.neonCyan, fontSize: 13, fontWeight: FontWeight.w600)),
                        if (uses.toString().isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text('$uses', style: TextStyle(color: CyberpunkTheme.textTertiary, fontSize: 11)),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Popular Accounts carousel
          if (hasPopular) ...[
             _sectionHeader(S.of(context).explore, Icons.local_fire_department_rounded),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _popularAccounts.length,
                itemBuilder: (ctx, i) => _buildPopularAccountCard(_popularAccounts[i]),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Follow Suggestions
          if (hasSuggestions) ...[
            _sectionHeader('Suggested for You', Icons.person_add_outlined),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                itemBuilder: (ctx, i) => _buildPopularAccountCard(_suggestions[i]),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Trending posts
          if (hasTrending) ...[
             _sectionHeader(S.of(context).explore, Icons.trending_up_rounded),
            _buildPostGrid(_trendingPosts.take(9).toList()),
            const SizedBox(height: 20),
          ],

          // Discover posts
          if (hasDiscover) ...[
             _sectionHeader(S.of(context).explore, Icons.explore_outlined),
            _buildPostGrid(_discoverPosts.take(15).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildPopularAccountCard(AccountUsers account) {
    return GestureDetector(
      onTap: () => _navigateToProfile(account),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    CyberpunkTheme.neonCyan.withOpacity(0.7),
                    CyberpunkTheme.neonPink.withOpacity(0.5),
                  ],
                ),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: CyberpunkTheme.backgroundBlack,
                backgroundImage: account.avatar.isNotEmpty
                    ? CachedNetworkImageProvider(account.avatar) : null,
                child: account.avatar.isEmpty
                    ? const Icon(Icons.person_rounded, size: 24, color: CyberpunkTheme.textTertiary)
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              account.display_name.isNotEmpty ? account.display_name : account.username,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: CyberpunkTheme.textWhite),
              maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
            ),
            Text(
              '@${account.username}',
              style: const TextStyle(fontSize: 10, color: CyberpunkTheme.textTertiary),
              maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostGrid(List<Status> posts) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      itemCount: posts.length,
      itemBuilder: (ctx, i) {
        final post = posts[i];
        final imageUrl = post.attach.isNotEmpty ? post.attach : _getFirstMediaUrl(post);
        if (imageUrl.isEmpty) {
          return Container(
            color: CyberpunkTheme.cardDark,
            child: const Center(child: Icon(Icons.article_outlined, color: CyberpunkTheme.textTertiary)),
          );
        }
        return GestureDetector(
          onTap: () => _navigateToPost(post),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: CyberpunkTheme.cardDark),
              errorWidget: (_, __, ___) => Container(
                color: CyberpunkTheme.cardDark,
                child: const Icon(Icons.broken_image_rounded, color: CyberpunkTheme.textTertiary, size: 20),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getFirstMediaUrl(Status post) {
    try {
      final media = post.getFirstMedia();
      if (media != null) {
        return media['url'] ?? media['preview_url'] ?? '';
      }
    } catch (_) {}
    return '';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      CyberpunkTheme.neonCyan.withOpacity(0.08 + _pulseController.value * 0.04),
                      CyberpunkTheme.cardDark,
                    ],
                  ),
                  border: Border.all(
                    color: CyberpunkTheme.neonCyan.withOpacity(0.15 + _pulseController.value * 0.1),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.explore_outlined,
                  size: 36,
                  color: CyberpunkTheme.neonCyan.withOpacity(0.6 + _pulseController.value * 0.2),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
           Text(S.of(context).findYourPeople, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: CyberpunkTheme.textWhite)),
           const SizedBox(height: 8),
           Text(S.of(context).searchByUsername, style: const TextStyle(fontSize: 14, color: CyberpunkTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ── User Card ────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final AccountUsers account;
  final VoidCallback onTap;
  final int index;

  const _UserCard({
    Key? key,
    required this.account,
    required this.onTap,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: CyberpunkTheme.neonCyan.withOpacity(0.06),
          highlightColor: CyberpunkTheme.neonCyan.withOpacity(0.03),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: CyberpunkTheme.cardDark,
              border: Border.all(color: CyberpunkTheme.borderDark, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        CyberpunkTheme.neonCyan.withOpacity(0.6),
                        CyberpunkTheme.neonPink.withOpacity(0.4),
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: CyberpunkTheme.backgroundBlack,
                    backgroundImage: account.avatar.isNotEmpty
                        ? CachedNetworkImageProvider(account.avatar) : null,
                    child: account.avatar.isEmpty
                        ? const Icon(Icons.person_rounded, size: 24, color: CyberpunkTheme.textTertiary) : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.display_name.isNotEmpty ? account.display_name : account.username,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CyberpunkTheme.textWhite, height: 1.3),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${account.username}',
                        style: const TextStyle(fontSize: 13, color: CyberpunkTheme.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (account.followers_count != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: CyberpunkTheme.neonCyan.withOpacity(0.08),
                      border: Border.all(color: CyberpunkTheme.neonCyan.withOpacity(0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 14, color: CyberpunkTheme.neonCyan.withOpacity(0.8)),
                        const SizedBox(width: 4),
                        Text(
                          _formatCount(account.followers_count!),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CyberpunkTheme.neonCyan.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 20, color: CyberpunkTheme.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
