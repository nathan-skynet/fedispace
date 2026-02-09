import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:fedispace/routes/profile/follow_requests_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:google_fonts/google_fonts.dart';

class NotificationsPage extends StatefulWidget {
  final ApiService apiService;

  const NotificationsPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with SingleTickerProviderStateMixin {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _loadNotifications();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      appLogger.debug('Loading notifications...');
      final response = await widget.apiService.getNotification();
      
      List<dynamic> parsed = [];

      if (response != null) {
        if (response is String) {
          try {
            parsed = jsonDecode(response);
          } catch (e) {
            appLogger.error('JSON decode error', e);
          }
        } else if (response is List) {
          parsed = response;
        }
      }
      
      setState(() {
        _notifications = parsed;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      appLogger.error('Error loading notifications', error, stackTrace);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      final success = await widget.apiService.clearNotifications();
      if (success) {
        setState(() => _notifications.clear());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
               content: Text(S.of(context).notificationsCleared, style: GoogleFonts.inter(color: Colors.white)),
              backgroundColor: CyberpunkTheme.surfaceDark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (error, stackTrace) {
      appLogger.error('Error clearing notifications', error, stackTrace);
    }
  }

  void _showClearDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: CyberpunkTheme.borderDark),
        ),
         title: Text(S.of(context).clearAll, style: GoogleFonts.inter(color: CyberpunkTheme.textWhite, fontSize: 18, fontWeight: FontWeight.w700)),
         content: Text(S.of(context).clearAllConfirm, style: GoogleFonts.inter(color: CyberpunkTheme.textSecondary, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
             child: Text(S.of(context).cancel, style: GoogleFonts.inter(color: CyberpunkTheme.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: CyberpunkTheme.neonPink.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
             child: Text(S.of(context).clearAll, style: GoogleFonts.inter(color: CyberpunkTheme.neonPink, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) _clearAllNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      body: Stack(
        children: [
          // Ambient orbs
          Positioned(
            top: -100,
            left: -60,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) => Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      CyberpunkTheme.neonPink.withOpacity(0.05 + _pulseController.value * 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -40,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) => Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      CyberpunkTheme.neonCyan.withOpacity(0.04 + _pulseController.value * 0.02),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                  child: Row(
                    children: [
                      // Back button
                      if (Navigator.canPop(context))
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: CyberpunkTheme.textWhite),
                          onPressed: () => Navigator.pop(context),
                        ),
                      Text(
                         S.of(context).notifications,
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: CyberpunkTheme.textWhite,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Live indicator
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) => Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: CyberpunkTheme.neonPink,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: CyberpunkTheme.neonPink.withOpacity(0.3 + _pulseController.value * 0.4),
                                blurRadius: 6 + _pulseController.value * 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Follow Requests
                      IconButton(
                        icon: const Icon(Icons.person_add_alt_1_outlined, color: CyberpunkTheme.textTertiary, size: 22),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => FollowRequestsPage(apiService: widget.apiService),
                            ),
                          );
                        },
                         tooltip: S.of(context).followRequests,
                      ),
                      if (_notifications.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_sweep_outlined, color: CyberpunkTheme.textTertiary, size: 22),
                          onPressed: _showClearDialog,
                           tooltip: S.of(context).clearAll,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Notification count badge
                if (!_isLoading && _notifications.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: CyberpunkTheme.neonCyan.withOpacity(0.08),
                            border: Border.all(color: CyberpunkTheme.neonCyan.withOpacity(0.15)),
                          ),
                          child: Text(
                             '${_notifications.length} ${S.of(context).notifications.toLowerCase()}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CyberpunkTheme.neonCyan.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!_isLoading && _notifications.isNotEmpty)
                  const SizedBox(height: 12),

                // Body
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
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
             Text(S.of(context).loading, style: GoogleFonts.inter(color: CyberpunkTheme.textTertiary, fontSize: 14)),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: CyberpunkTheme.neonCyan,
      backgroundColor: CyberpunkTheme.surfaceDark,
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _NotificationCard(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) => Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CyberpunkTheme.neonPink.withOpacity(0.06 + _pulseController.value * 0.04),
                    CyberpunkTheme.surfaceDark,
                  ],
                ),
                border: Border.all(
                  color: CyberpunkTheme.neonPink.withOpacity(0.1 + _pulseController.value * 0.1),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 36,
                color: CyberpunkTheme.neonPink.withOpacity(0.5 + _pulseController.value * 0.2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
             S.of(context).noResults,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: CyberpunkTheme.textWhite),
          ),
          const SizedBox(height: 8),
          Text(
             S.of(context).notifications,
            style: GoogleFonts.inter(fontSize: 14, color: CyberpunkTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'];
    final account = notification['account'];

    if (type == 'mention' || type == 'favourite' || type == 'reblog' || type == 'status') {
      if (notification['status'] != null) {
        Navigator.pushNamed(context, '/statusDetail', arguments: {
          'statusId': notification['status']['id'],
          'apiService': widget.apiService,
        });
      }
    } else if (type == 'follow') {
      Navigator.pushNamed(context, '/UserProfile', arguments: {'userId': account['id']});
    }
  }
}

// ──────────────────────────────────────────────
// Notification Card — Premium Cyberpunk Style
// ──────────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = notification['type'];
    final account = notification['account'];
    final createdAt = notification['created_at'];

    String text = '';
    IconData icon = Icons.notifications_none;
    Color accentColor = CyberpunkTheme.neonCyan;

    switch (type) {
      case 'follow':
        text = S.of(context).startedFollowing;
        icon = Icons.person_add_rounded;
        accentColor = CyberpunkTheme.neonCyan;
        break;
      case 'favourite':
        text = S.of(context).likedYourPost;
        icon = Icons.favorite_rounded;
        accentColor = CyberpunkTheme.neonPink;
        break;
      case 'reblog':
        text = S.of(context).boostedYourPost;
        icon = Icons.repeat_rounded;
        accentColor = const Color(0xFF2ECC71);
        break;
      case 'mention':
        text = S.of(context).mentionedYou;
        icon = Icons.alternate_email_rounded;
        accentColor = const Color(0xFFF39C12);
        break;
      case 'poll':
        text = S.of(context).pollEnded;
        icon = Icons.poll_rounded;
        accentColor = CyberpunkTheme.neonCyan;
        break;
      case 'status':
        text = S.of(context).postedNew;
        icon = Icons.article_rounded;
        accentColor = CyberpunkTheme.neonCyan;
        break;
    }

    final String displayName = account?['display_name'] ?? account?['username'] ?? '';
    final String avatar = account?['avatar'] ?? '';

    String timeText = '';
    if (createdAt != null) {
      try {
        timeText = timeago.format(DateTime.parse(createdAt));
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: accentColor.withOpacity(0.06),
          highlightColor: accentColor.withOpacity(0.03),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              // Premium dark glass background
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0D0D12),
                  const Color(0xFF111118),
                ],
              ),
              border: Border.all(
                color: accentColor.withOpacity(0.08),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with gradient ring
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accentColor.withOpacity(0.6),
                            accentColor.withOpacity(0.15),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF0D0D12),
                        backgroundImage: avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
                        child: avatar.isEmpty
                            ? const Icon(Icons.person_rounded, size: 22, color: CyberpunkTheme.textTertiary)
                            : null,
                      ),
                    ),
                    // Type badge
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0D12),
                          shape: BoxShape.circle,
                          border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(icon, size: 10, color: accentColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: displayName,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: CyberpunkTheme.textWhite,
                                height: 1.4,
                              ),
                            ),
                            TextSpan(
                              text: ' $text',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: CyberpunkTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (timeText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            timeText,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: CyberpunkTheme.textTertiary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Accent dot indicator
                const SizedBox(width: 8),
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withOpacity(0.5),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
