import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:fedispace/l10n/app_localizations.dart';

/// A premium server picker page that displays Pixelfed instances
/// for the user to choose where to create an account.
class ServerPickerPage extends StatefulWidget {
  const ServerPickerPage({super.key});

  @override
  State<ServerPickerPage> createState() => _ServerPickerPageState();
}

class _PixelfedServer {
  final String domain;
  String? title;
  String? description;
  int? userCount;
  int? statusCount;
  String? thumbnail;
  bool registrationsOpen = true;
  bool loaded = false;
  bool error = false;

  _PixelfedServer({required this.domain});
}

enum _ServerFilter { all, popular, small }

class _ServerPickerPageState extends State<ServerPickerPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  final TextEditingController _searchController = TextEditingController();
  _ServerFilter _activeFilter = _ServerFilter.all;
  String _searchQuery = '';

  final List<_PixelfedServer> _servers = [
    // Major / flagship instances
    _PixelfedServer(domain: 'pixelfed.social'),
    _PixelfedServer(domain: 'pixelfed.com'),
    _PixelfedServer(domain: 'gram.social'),
    _PixelfedServer(domain: 'pxlmo.com'),
    _PixelfedServer(domain: 'metapixl.com'),
    _PixelfedServer(domain: 'photos.social'),
    _PixelfedServer(domain: 'photofed.world'),
    // Regional — Europe
    _PixelfedServer(domain: 'pixelfed.de'),
    _PixelfedServer(domain: 'pixel.tchncs.de'),
    _PixelfedServer(domain: 'pxlfed.de'),
    _PixelfedServer(domain: 'pixelfed.fr'),
    _PixelfedServer(domain: 'pixelfed.es'),
    _PixelfedServer(domain: 'pixelfed.uno'),
    _PixelfedServer(domain: 'pixelshot.it'),
    _PixelfedServer(domain: 'pixelfed.dk'),
    _PixelfedServer(domain: 'pixelfed.cz'),
    _PixelfedServer(domain: 'pixelfed.ch'),
    _PixelfedServer(domain: 'pixelfed.ie'),
    _PixelfedServer(domain: 'pixelfed.si'),
    _PixelfedServer(domain: 'pixelfed.scot'),
    _PixelfedServer(domain: 'pixelfed.eus'),
    _PixelfedServer(domain: 'pixl.fi'),
    _PixelfedServer(domain: 'pixl.pt'),
    _PixelfedServer(domain: 'pixelfed.ru'),
    _PixelfedServer(domain: 'bolha.photos'),
    _PixelfedServer(domain: 'fotolibre.social'),
    // Regional — Americas
    _PixelfedServer(domain: 'pixelfed.ca'),
    _PixelfedServer(domain: 'pxlfd.ca'),
    _PixelfedServer(domain: 'pixelfed.cl'),
    // Regional — Asia-Pacific
    _PixelfedServer(domain: 'pixelfed.au'),
    _PixelfedServer(domain: 'pixelfed.tokyo'),
    _PixelfedServer(domain: 'sajin.life'),
    // Thematic / community
    _PixelfedServer(domain: 'pixelfed.art'),
    _PixelfedServer(domain: 'pixey.org'),
    _PixelfedServer(domain: 'spicy.social'),
    _PixelfedServer(domain: 'pet.tax'),
    _PixelfedServer(domain: 'crafty.social'),
    _PixelfedServer(domain: 'instapix.org'),
    _PixelfedServer(domain: 'pixelfed.global'),
    _PixelfedServer(domain: 'nicagram.com'),
  ];

  /// Servers filtered: hide errors, hide closed registrations, apply search + size filter
  List<_PixelfedServer> get _filteredServers {
    return _servers.where((s) {
      // Hide errored and closed-registration servers
      if (s.error) return false;
      if (s.loaded && !s.registrationsOpen) return false;

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchDomain = s.domain.toLowerCase().contains(q);
        final matchTitle = (s.title ?? '').toLowerCase().contains(q);
        final matchDesc = (s.description ?? '').toLowerCase().contains(q);
        if (!matchDomain && !matchTitle && !matchDesc) return false;
      }

      // Size filter
      if (_activeFilter == _ServerFilter.popular) {
        if (!s.loaded) return false;
        return (s.userCount ?? 0) >= 1000;
      } else if (_activeFilter == _ServerFilter.small) {
        if (!s.loaded) return false;
        return (s.userCount ?? 0) < 1000;
      }

      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    _fetchAllServers();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllServers() async {
    for (final server in _servers) {
      _fetchServerInfo(server);
    }
  }

  Future<void> _fetchServerInfo(_PixelfedServer server) async {
    try {
      final response = await http
          .get(Uri.parse('https://${server.domain}/api/v1/instance'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            server.title = data['title'] ?? server.domain;
            server.description =
                data['short_description'] ?? data['description'] ?? '';
            server.userCount = data['stats']?['user_count'] ?? 0;
            server.statusCount = data['stats']?['status_count'] ?? 0;
            server.thumbnail = data['thumbnail'];
            server.registrationsOpen = data['registrations'] ?? true;
            server.loaded = true;
          });
        }
      } else {
        if (mounted) setState(() => server.error = true);
      }
    } catch (_) {
      if (mounted) setState(() => server.error = true);
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _openRegistration(String domain) async {
    final url = Uri.parse('https://$domain/register');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = S.of(context);
    const accentColor = Color(0xFF00F3FF);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App-bar ──
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              expandedHeight: 140,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: Colors.white70,
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.only(left: 56, bottom: 16, right: 16),
                title: Text(
                  l.serverPickerTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1A1A2E),
                        Color(0xFF0A0A0F),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Subtitle ──
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Text(
                  l.serverPickerSubtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.5),
                    height: 1.4,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Search bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withValues(alpha: 0.06),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 0.5,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      hintText: l.serverPickerSearch,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 14,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Icon(
                          Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 20,
                        ),
                      ),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 0, minHeight: 0),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded,
                                  size: 18,
                                  color:
                                      Colors.white.withValues(alpha: 0.4)),
                              onPressed: () => setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              }),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Filter chips ──
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip(l.serverPickerFilterAll,
                        _ServerFilter.all, accentColor),
                    const SizedBox(width: 8),
                    _buildFilterChip(l.serverPickerFilterPopular,
                        _ServerFilter.popular, accentColor),
                    const SizedBox(width: 8),
                    _buildFilterChip(l.serverPickerFilterSmall,
                        _ServerFilter.small, accentColor),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Server list (filtered) ──
            Builder(builder: (context) {
              final filtered = _filteredServers;
              if (filtered.isEmpty && _servers.every((s) => s.loaded || s.error)) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text(
                          l.serverPickerNoResults,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final server = filtered[index];
                      return _ServerCard(
                        server: server,
                        accentColor: accentColor,
                        onTap: () => _openRegistration(server.domain),
                        formatCount: _formatCount,
                        l: l,
                        index: index,
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            }),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      String label, _ServerFilter filter, Color accentColor) {
    final isActive = _activeFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isActive
              ? accentColor.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: isActive
                ? accentColor.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive
                ? accentColor
                : Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _ServerCard extends StatefulWidget {
  final _PixelfedServer server;
  final Color accentColor;
  final VoidCallback onTap;
  final String Function(int) formatCount;
  final AppLocalizations l;
  final int index;

  const _ServerCard({
    required this.server,
    required this.accentColor,
    required this.onTap,
    required this.formatCount,
    required this.l,
    required this.index,
  });

  @override
  State<_ServerCard> createState() => _ServerCardState();
}

class _ServerCardState extends State<_ServerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final server = widget.server;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: Opacity(
            opacity: _fadeAnim.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: server.loaded && server.registrationsOpen
                ? widget.onTap
                : null,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.07),
                    Colors.white.withValues(alpha: 0.03),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Thumbnail background (blurred)
                    if (server.loaded && server.thumbnail != null)
                      Positioned.fill(
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                          child: Opacity(
                            opacity: 0.15,
                            child: Image.network(
                              server.thumbnail!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: server.loaded
                          ? _buildLoadedContent(server)
                          : _buildShimmer(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedContent(_PixelfedServer server) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row
        Row(
          children: [
            // Domain icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.accentColor.withValues(alpha: 0.2),
                    widget.accentColor.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: widget.accentColor.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Icon(
                Icons.language_rounded,
                color: widget.accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server.title ?? server.domain,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    server.domain,
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.accentColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Registration status chip
            _buildRegChip(server.registrationsOpen),
          ],
        ),

        // Description
        if (server.description != null && server.description!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            server.description!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.55),
              height: 1.4,
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Stats row
        Row(
          children: [
            _buildStatChip(
              Icons.people_alt_rounded,
              widget.formatCount(server.userCount ?? 0),
              widget.l.serverPickerUsers,
            ),
            const SizedBox(width: 10),
            _buildStatChip(
              Icons.photo_library_rounded,
              widget.formatCount(server.statusCount ?? 0),
              widget.l.serverPickerPosts,
            ),
            const Spacer(),
            // Arrow
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: server.registrationsOpen
                    ? widget.accentColor.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: server.registrationsOpen
                    ? widget.accentColor
                    : Colors.white24,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegChip(bool open) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: open
            ? const Color(0xFF00E676).withValues(alpha: 0.12)
            : Colors.red.withValues(alpha: 0.12),
        border: Border.all(
          color: open
              ? const Color(0xFF00E676).withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: open ? const Color(0xFF00E676) : Colors.red,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            open
                ? widget.l.serverPickerOpenReg
                : widget.l.serverPickerClosedReg,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: open
                  ? const Color(0xFF00E676).withValues(alpha: 0.9)
                  : Colors.red.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withValues(alpha: 0.06),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _shimmerBox(40, 40, 12),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(120, 16, 6),
                const SizedBox(height: 6),
                _shimmerBox(80, 12, 4),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        _shimmerBox(double.infinity, 12, 4),
        const SizedBox(height: 6),
        _shimmerBox(200, 12, 4),
        const SizedBox(height: 14),
        Row(
          children: [
            _shimmerBox(90, 28, 10),
            const SizedBox(width: 10),
            _shimmerBox(90, 28, 10),
          ],
        ),
      ],
    );
  }

  Widget _shimmerBox(double width, double height, double radius) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: Colors.white.withValues(alpha: 0.06),
      ),
    );
  }
}
