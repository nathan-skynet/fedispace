import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/models/account.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:fedispace/utils/social_actions.dart';
import 'package:video_player/video_player.dart';
import 'dart:math';
import 'package:video_viewer/video_viewer.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:full_screen_image_null_safe/full_screen_image_null_safe.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cyberpunk-themed post detail view with comments
class PostDetailPage extends StatefulWidget {
  final ApiService apiService;
  final Status post;

  const PostDetailPage({
    Key? key,
    required this.apiService,
    required this.post,
  }) : super(key: key);

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  
  List<Status> _comments = [];
  bool _isLoadingComments = false;
  bool _isFavorited = false;
  bool _isBookmarked = false;
  int _favoritesCount = 0;
  late VideoViewerController _videoController;
  String? _replyToId;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.post.favorited;
    _isBookmarked = widget.post.reblogged;
    _favoritesCount = widget.post.favourites_count;
    _videoController = VideoViewerController();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      appLogger.debug('Loading comments for post: ${widget.post.id}');
      final contextMap = await widget.apiService.getContext(widget.post.id);
      final List<Status> comments = [];
      if (contextMap['descendants'] != null) {
        for (var item in contextMap['descendants']) {
          if (item is Map<String, dynamic>) {
            comments.add(Status.fromJson(item));
          }
        }
      }
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (error, stackTrace) {
      appLogger.error('Error loading comments', error, stackTrace);
      setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _toggleLike() async {
    try {
      await widget.apiService.favoriteStatus(widget.post.id);
      setState(() {
        _isFavorited = !_isFavorited;
        _favoritesCount += _isFavorited ? 1 : -1;
      });
    } catch (error, stackTrace) {
      appLogger.error('Error toggling like', error, stackTrace);
    }
  }

  Future<void> _toggleBookmark() async {
    setState(() => _isBookmarked = !_isBookmarked);
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    try {
      final replyId = _replyToId ?? widget.post.id;
      await widget.apiService.createPosts(inReplyToId: replyId, content: text);
      _commentController.clear();
      _commentFocus.unfocus();
      setState(() => _replyToId = null);
      _loadComments();
    } catch (error, stackTrace) {
      appLogger.error('Error posting comment', error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to post comment'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateToProfile(String userId) {
    Navigator.pushNamed(context, '/UserProfile', arguments: {'userId': userId});
  }

  void _replyToComment(Status comment) {
    setState(() {
      _replyToId = comment.id;
      _commentController.text = '@${comment.acct} ';
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentController.text.length),
      );
    });
    _commentFocus.requestFocus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  // ── More options ──────────────────────────────────────────────────

  void _showMoreOptions() {
    final isOwnPost = widget.post.account.id == widget.apiService.currentAccount?.id;
    showModalBottomSheet(
      context: context,
      backgroundColor: CyberpunkTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: CyberpunkTheme.textTertiary, borderRadius: BorderRadius.circular(2)),
            ),
            if (isOwnPost) ...[
              _optionTile(Icons.push_pin_outlined, 'Pin to profile', () async {
                Navigator.pop(ctx);
                final ok = await widget.apiService.pinStatus(widget.post.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? 'Pinned!' : 'Failed to pin', style: const TextStyle(color: Colors.white)),
                    backgroundColor: ok ? CyberpunkTheme.neonCyan.withOpacity(0.8) : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }),
              _optionTile(Icons.edit_outlined, 'Edit post', () {
                Navigator.pop(ctx);
                _showEditDialog();
              }),
              _optionTile(Icons.archive_outlined, 'Archive', () async {
                Navigator.pop(ctx);
                final ok = await widget.apiService.archivePost(widget.post.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? 'Archived' : 'Failed to archive', style: const TextStyle(color: Colors.white)),
                    backgroundColor: ok ? CyberpunkTheme.neonCyan.withOpacity(0.8) : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ));
                  if (ok) Navigator.pop(context);
                }
              }),
            ],
            _optionTile(Icons.history_outlined, 'View edit history', () {
              Navigator.pop(ctx);
              _showEditHistory();
            }),
            _optionTile(Icons.collections_bookmark_outlined, 'Add to collection', () async {
              Navigator.pop(ctx);
              final collections = await widget.apiService.getMyCollections();
              if (!mounted) return;
              if (collections.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(S.of(context).noCollections, style: const TextStyle(color: Colors.white)),
                  backgroundColor: CyberpunkTheme.surfaceDark,
                  behavior: SnackBarBehavior.floating,
                ));
                return;
              }
              showModalBottomSheet(
                context: context,
                backgroundColor: CyberpunkTheme.surfaceDark,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                builder: (c2) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(S.of(context).pickCollection, style: const TextStyle(color: CyberpunkTheme.textWhite, fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      ...collections.map((col) => ListTile(
                        title: Text(col['title'] ?? 'Untitled', style: const TextStyle(color: CyberpunkTheme.textWhite)),
                        leading: const Icon(Icons.collections_outlined, color: CyberpunkTheme.neonCyan),
                        onTap: () async {
                          Navigator.pop(c2);
                          final ok = await widget.apiService.addToCollection(col['id'].toString(), widget.post.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(ok ? S.of(context).success : S.of(context).error, style: const TextStyle(color: Colors.white)),
                              backgroundColor: ok ? CyberpunkTheme.neonCyan.withOpacity(0.8) : Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        },
                      )),
                    ],
                  ),
                ),
              );
            }),
            if (isOwnPost)
              _optionTile(Icons.delete_outline_rounded, 'Delete post', () async {
                Navigator.pop(ctx);
                final ok = await widget.apiService.deleteStatus(widget.post.id);
                if (mounted && ok != null) Navigator.pop(context);
              }, color: CyberpunkTheme.neonPink),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? CyberpunkTheme.textWhite, size: 22),
      title: Text(label, style: TextStyle(color: color ?? CyberpunkTheme.textWhite, fontSize: 15)),
      onTap: onTap,
      dense: true,
    );
  }

  void _showEditDialog() {
    final controller = TextEditingController(text: widget.post.content.replaceAll(RegExp(r'<[^>]*>'), ''));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: CyberpunkTheme.borderDark)),
        title: Text(S.of(context).editPost, style: const TextStyle(color: CyberpunkTheme.textWhite, fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          maxLines: 6,
          style: const TextStyle(color: CyberpunkTheme.textWhite, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Edit your post...',
            hintStyle: const TextStyle(color: CyberpunkTheme.textTertiary),
            filled: true,
            fillColor: CyberpunkTheme.cardDark,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.of(context).cancel, style: const TextStyle(color: CyberpunkTheme.textTertiary))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await widget.apiService.editStatus(widget.post.id, content: controller.text);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Post updated!' : 'Failed to edit', style: const TextStyle(color: Colors.white)),
                  backgroundColor: ok ? CyberpunkTheme.neonCyan.withOpacity(0.8) : Colors.red,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            style: TextButton.styleFrom(backgroundColor: CyberpunkTheme.neonCyan.withOpacity(0.1)),
            child: Text(S.of(context).save, style: const TextStyle(color: CyberpunkTheme.neonCyan, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showEditHistory() async {
    final history = await widget.apiService.getStatusHistory(widget.post.id);
    if (!mounted) return;
    if (history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.of(context).noEditHistory, style: const TextStyle(color: Colors.white)),
        backgroundColor: CyberpunkTheme.surfaceDark,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: CyberpunkTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        expand: false,
        builder: (_, scroller) => ListView.separated(
          controller: scroller,
          padding: const EdgeInsets.all(16),
          itemCount: history.length + 1,
          separatorBuilder: (_, __) => const Divider(color: CyberpunkTheme.borderDark, height: 1),
          itemBuilder: (_, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('Edit history (${history.length} revisions)', style: const TextStyle(color: CyberpunkTheme.textWhite, fontSize: 16, fontWeight: FontWeight.w700)),
              );
            }
            final rev = history[i - 1];
            final content = (rev['content'] ?? '').toString().replaceAll(RegExp(r'<[^>]*>'), '');
            final createdAt = rev['created_at'] != null ? DateTime.tryParse(rev['created_at'].toString()) : null;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (createdAt != null)
                    Text(timeago.format(createdAt), style: const TextStyle(color: CyberpunkTheme.neonCyan, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(content, style: const TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 14, height: 1.4)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: CyberpunkTheme.backgroundBlack,
        elevation: 0,
        title: const Text(
          'Post',
          style: TextStyle(
            color: CyberpunkTheme.textWhite,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: CyberpunkTheme.neonCyan),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 24, color: CyberpunkTheme.textSecondary),
            onPressed: () => SocialActions.shareStatus(widget.post),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, size: 24, color: CyberpunkTheme.textSecondary),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadComments,
              color: CyberpunkTheme.neonCyan,
              backgroundColor: CyberpunkTheme.surfaceDark,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPostHeader(),
                    if (widget.post.hasMediaAttachments) _buildPostImage(),
                    _buildPostActions(),
                    _buildLikesCount(),
                    _buildPostCaption(),
                    _buildPostTime(),
                    _buildDivider(),
                    _buildCommentsSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  // ── Post header ───────────────────────────────────────────────────

  Widget _buildPostHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(widget.post.account.id),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: CyberpunkTheme.neonCyan.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(color: CyberpunkTheme.neonCyan.withOpacity(0.15), blurRadius: 8),
                ],
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: CyberpunkTheme.cardDark,
                backgroundImage: widget.post.avatar.isNotEmpty
                    ? CachedNetworkImageProvider(widget.post.avatar)
                    : null,
                child: widget.post.avatar.isEmpty
                    ? const Icon(Icons.person, size: 22, color: CyberpunkTheme.textTertiary)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _navigateToProfile(widget.post.account.id),
                  child: Text(
                    widget.post.acct,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CyberpunkTheme.textWhite,
                    ),
                  ),
                ),
                if (widget.post.account.displayName.isNotEmpty)
                  Text(
                    widget.post.account.displayName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CyberpunkTheme.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded, color: CyberpunkTheme.textSecondary),
            color: CyberpunkTheme.surfaceDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'share') SocialActions.shareStatus(widget.post);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'share', child: Text('Share', style: TextStyle(color: CyberpunkTheme.textWhite))),
            ],
          ),
        ],
      ),
    );
  }

  // ── Post image / carousel ────────────────────────────────────────

  Widget _buildPostImage() {
    if (widget.post.attachement.length > 1) {
      return CarouselSlider.builder(
        itemCount: widget.post.attachement.length,
        options: CarouselOptions(
          height: 420,
          viewportFraction: 1.0,
          enableInfiniteScroll: false,
          autoPlay: false,
        ),
        itemBuilder: (context, index, realIdx) {
          final attachment = widget.post.attachement[index];
          final url = attachment["url"] ?? "";
          final isVideo = url.toLowerCase().contains(".mp4") || url.toLowerCase().contains(".mov");
          if (isVideo) {
            return SizedBox(
              width: double.infinity,
              height: 420,
              child: VideoViewer(
                enableVerticalSwapingGesture: false,
                enableHorizontalSwapingGesture: false,
                onFullscreenFixLandscape: false,
                style: VideoViewerStyle(),
                controller: _videoController,
                source: {
                  url: VideoSource(video: VideoPlayerController.network(url)),
                },
              ),
            );
          } else {
            return FullScreenWidget(
              child: Hero(
                tag: "${widget.post.id}_${index}_${Random().nextInt(10000)}",
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: CyberpunkTheme.cardDark,
                    child: const Center(child: InstagramLoadingIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: CyberpunkTheme.cardDark,
                    child: const Icon(Icons.broken_image_rounded, color: CyberpunkTheme.textTertiary, size: 40),
                  ),
                ),
              ),
            );
          }
        },
      );
    }

    final firstMedia = widget.post.getFirstMedia();
    final isVideoType = firstMedia != null && (firstMedia['type'] == 'video' || firstMedia['type'] == 'gifv');
    final isVideoExtension = widget.post.attach.toLowerCase().contains('.mp4') || widget.post.attach.toLowerCase().contains('.mov');
    final isVideo = isVideoType || isVideoExtension;

    if (isVideo) {
      return SizedBox(
        width: double.infinity,
        height: 420,
        child: VideoViewer(
          enableVerticalSwapingGesture: false,
          enableHorizontalSwapingGesture: false,
          onFullscreenFixLandscape: false,
          style: VideoViewerStyle(),
          controller: _videoController,
          source: {
            widget.post.attach: VideoSource(
              video: VideoPlayerController.network(widget.post.attach),
            ),
          },
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.0,
      child: FullScreenWidget(
        child: Hero(
          tag: "${widget.post.id}_single_${Random().nextInt(10000)}",
          child: CachedNetworkImage(
            imageUrl: widget.post.attach,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: CyberpunkTheme.cardDark,
              child: const Center(child: InstagramLoadingIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: CyberpunkTheme.cardDark,
              child: const Icon(Icons.broken_image_rounded, color: CyberpunkTheme.textTertiary, size: 40),
            ),
          ),
        ),
      ),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────

  Widget _buildPostActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _actionIcon(
            _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            onTap: _toggleLike,
            color: _isFavorited ? const Color(0xFFFF2D55) : CyberpunkTheme.textWhite,
            glowColor: _isFavorited ? const Color(0xFFFF2D55) : null,
          ),
          const SizedBox(width: 20),
          _actionIcon(
            Icons.mode_comment_outlined,
            onTap: () => _commentFocus.requestFocus(),
            color: CyberpunkTheme.textWhite,
          ),
          const SizedBox(width: 20),
          _actionIcon(
            Icons.send_outlined,
            onTap: () => SocialActions.shareStatus(widget.post),
            color: CyberpunkTheme.textWhite,
          ),
          const Spacer(),
          _actionIcon(
            _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            onTap: _toggleBookmark,
            color: _isBookmarked ? CyberpunkTheme.neonCyan : CyberpunkTheme.textWhite,
            glowColor: _isBookmarked ? CyberpunkTheme.neonCyan : null,
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, {required VoidCallback onTap, required Color color, Color? glowColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: glowColor != null
            ? BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: glowColor.withOpacity(0.4), blurRadius: 10)],
              )
            : null,
        child: Icon(icon, size: 28, color: color),
      ),
    );
  }

  // ── Likes count ───────────────────────────────────────────────────

  Widget _buildLikesCount() {
    if (_favoritesCount == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: () => _showLikedBySheet(),
        child: Text(
          '$_favoritesCount ${_favoritesCount == 1 ? 'like' : 'likes'}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: CyberpunkTheme.textWhite,
          ),
        ),
      ),
    );
  }

  void _showLikedBySheet() {
    _showAccountListSheet(
      title: 'Liked by',
      icon: Icons.favorite_rounded,
      iconColor: const Color(0xFFFF2D55),
      fetcher: () => widget.apiService.getFavouritedBy(widget.post.id),
    );
  }

  void _showBoostedBySheet() {
    _showAccountListSheet(
      title: 'Boosted by',
      icon: Icons.repeat_rounded,
      iconColor: CyberpunkTheme.neonCyan,
      fetcher: () => widget.apiService.getRebloggedBy(widget.post.id),
    );
  }

  void _showAccountListSheet({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Future<List<Account>> Function() fetcher,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CyberpunkTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return FutureBuilder<List<Account>>(
          future: fetcher(),
          builder: (ctx, snap) {
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: CyberpunkTheme.borderDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20, color: iconColor),
                      const SizedBox(width: 8),
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CyberpunkTheme.textWhite)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: CyberpunkTheme.borderDark),
                  // Content
                  if (snap.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: CyberpunkTheme.neonCyan),
                    )
                  else if (!snap.hasData || snap.data!.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No one yet', style: TextStyle(color: CyberpunkTheme.textTertiary)),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: snap.data!.length,
                        itemBuilder: (ctx, i) {
                          final a = snap.data![i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: (a.avatar != null && a.avatar!.isNotEmpty)
                                  ? NetworkImage(a.avatar!) : null,
                              backgroundColor: CyberpunkTheme.surfaceDark,
                              child: (a.avatar == null || a.avatar!.isEmpty)
                                  ? const Icon(Icons.person, color: CyberpunkTheme.textTertiary) : null,
                            ),
                            title: Text(
                              (a.display_name != null && a.display_name!.isNotEmpty) ? a.display_name! : (a.username ?? ''),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CyberpunkTheme.textWhite),
                            ),
                            subtitle: Text(
                              '@${a.username ?? ''}',
                              style: const TextStyle(fontSize: 13, color: CyberpunkTheme.textSecondary),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              if (a.id != null) _navigateToProfile(a.id!);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Caption ───────────────────────────────────────────────────────

  Widget _buildPostCaption() {
    final cleanContent = widget.post.content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');

    if (cleanContent.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: CyberpunkTheme.textWhite,
            fontSize: 16,
            height: 1.5,
          ),
          children: [
            TextSpan(
              text: '${widget.post.acct}  ',
              style: const TextStyle(fontWeight: FontWeight.w700, color: CyberpunkTheme.neonCyan),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _navigateToProfile(widget.post.account.id),
            ),
            ..._buildRichContentSpans(cleanContent),
          ],
        ),
      ),
    );
  }

  /// Parse text content and create tappable spans for #hashtags, @mentions, and URLs
  List<InlineSpan> _buildRichContentSpans(String text) {
    final List<InlineSpan> spans = [];
    final regex = RegExp(
      r'(#[\w\u00C0-\u024F]+)|(@[\w@.\-]+)|(https?://[^\s,<>\]]+)',
      caseSensitive: false,
    );

    int lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      final matched = match.group(0)!;
      if (matched.startsWith('#')) {
        spans.add(TextSpan(
          text: matched,
          style: const TextStyle(color: CyberpunkTheme.neonCyan, fontWeight: FontWeight.w600),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              Navigator.pushNamed(context, '/TagTimeline', arguments: {'tag': matched.substring(1)});
            },
        ));
      } else if (matched.startsWith('@')) {
        spans.add(TextSpan(
          text: matched,
          style: const TextStyle(color: CyberpunkTheme.neonCyan, fontWeight: FontWeight.w600),
          recognizer: TapGestureRecognizer()
            ..onTap = () => appLogger.info('Mention tapped: ${matched.substring(1)}'),
        ));
      } else {
        spans.add(TextSpan(
          text: matched,
          style: TextStyle(color: CyberpunkTheme.neonCyan.withOpacity(0.8), decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final uri = Uri.tryParse(matched);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
        ));
      }
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }
    return spans;
  }

  // ── Post time ─────────────────────────────────────────────────────

  Widget _buildPostTime() {
    DateTime? createdAt;
    try {
      if (widget.post.created_at.isNotEmpty) {
        createdAt = DateTime.parse(widget.post.created_at);
      }
    } catch (_) {}
    if (createdAt == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        timeago.format(createdAt, locale: 'en'),
        style: const TextStyle(
          fontSize: 13,
          color: CyberpunkTheme.textTertiary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 0.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            CyberpunkTheme.neonCyan.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  // ── Comments section ──────────────────────────────────────────────

  Widget _buildCommentsSection() {
    if (_isLoadingComments) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: SizedBox(
            width: 28, height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(CyberpunkTheme.neonCyan),
            ),
          ),
        ),
      );
    }

    if (_comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.mode_comment_outlined, size: 44, color: CyberpunkTheme.textTertiary.withOpacity(0.5)),
              const SizedBox(height: 12),
              const Text(
                'No comments yet',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CyberpunkTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Be the first to comment',
                style: TextStyle(fontSize: 14, color: CyberpunkTheme.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '${_comments.length} ${_comments.length == 1 ? 'Comment' : 'Comments'}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CyberpunkTheme.textWhite,
            ),
          ),
        ),
        ..._comments.map((comment) => _buildCommentItem(comment)),
      ],
    );
  }

  Widget _buildCommentItem(Status comment) {
    final cleanContent = comment.content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');

    DateTime? createdAt;
    try {
      if (comment.created_at.isNotEmpty) {
        createdAt = DateTime.parse(comment.created_at);
      }
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(comment.account.id),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: CyberpunkTheme.cardDark,
              backgroundImage: comment.avatar.isNotEmpty
                  ? CachedNetworkImageProvider(comment.avatar)
                  : null,
              child: comment.avatar.isEmpty
                  ? const Icon(Icons.person, size: 18, color: CyberpunkTheme.textTertiary)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: CyberpunkTheme.textWhite,
                      fontSize: 15,
                      height: 1.45,
                    ),
                    children: [
                      TextSpan(
                        text: '${comment.acct}  ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: CyberpunkTheme.neonCyan,
                          fontSize: 14,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _navigateToProfile(comment.account.id),
                      ),
                      ..._buildRichContentSpans(cleanContent),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (createdAt != null)
                      Text(
                        timeago.format(createdAt, locale: 'en_short'),
                        style: const TextStyle(fontSize: 12, color: CyberpunkTheme.textTertiary),
                      ),
                    if (comment.favourites_count > 0) ...[
                      const SizedBox(width: 14),
                      Text(
                        '${comment.favourites_count} ${comment.favourites_count == 1 ? 'like' : 'likes'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CyberpunkTheme.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () => _replyToComment(comment),
                      child: const Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: CyberpunkTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              try {
                if (comment.favorited != true) {
                  await widget.apiService.favoriteStatus(comment.id!);
                } else {
                  await widget.apiService.undoFavoriteStatus(comment.id!);
                }
                _loadComments();
              } catch (e) {
                appLogger.error('Failed to like comment', e);
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Icon(
                comment.favorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 18,
                color: comment.favorited ? const Color(0xFFFF2D55) : CyberpunkTheme.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Comment input ─────────────────────────────────────────────────

  Widget _buildCommentInput() {
    return Container(
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: CyberpunkTheme.neonCyan.withOpacity(0.15), width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply indicator
          if (_replyToId != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CyberpunkTheme.neonCyan.withOpacity(0.06),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, size: 16, color: CyberpunkTheme.neonCyan),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Replying to comment',
                      style: TextStyle(fontSize: 13, color: CyberpunkTheme.textSecondary),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _replyToId = null;
                      _commentController.clear();
                    }),
                    child: const Icon(Icons.close_rounded, size: 18, color: CyberpunkTheme.textSecondary),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: CyberpunkTheme.cardDark,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: CyberpunkTheme.borderDark),
                      ),
                      child: TextField(
                        controller: _commentController,
                        focusNode: _commentFocus,
                        style: const TextStyle(
                          fontSize: 15,
                          color: CyberpunkTheme.textWhite,
                        ),
                        decoration: InputDecoration(
                          hintText: _replyToId != null ? 'Write a reply...' : 'Add a comment...',
                          border: InputBorder.none,
                          hintStyle: const TextStyle(color: CyberpunkTheme.textTertiary, fontSize: 15),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _postComment,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [CyberpunkTheme.neonCyan, Color(0xFF0088FF)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: CyberpunkTheme.neonCyan.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
