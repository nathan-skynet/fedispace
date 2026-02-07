import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Instagram-style post card for timeline
class InstagramPostCard extends StatefulWidget {
  final Status status;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;
  final VoidCallback? onProfileTap;

  const InstagramPostCard({
    Key? key,
    required this.status,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onBookmark,
    this.onProfileTap,
  }) : super(key: key);

  @override
  State<InstagramPostCard> createState() => _InstagramPostCardState();
}

class _InstagramPostCardState extends State<InstagramPostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (!widget.status.favorited) {
      _likeAnimationController.forward(from: 0.0);
      widget.onLike?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(context, isDark),

        // Image/Media
        if (widget.status.hasMediaAttachments) _buildMedia(context),

        // Action buttons
        _buildActions(context),

        // Likes count
        if (widget.status.favourites_count > 0) _buildLikesCount(context),

        // Caption
        _buildCaption(context),

        // View comments
        if (widget.status.replies_count > 0) _buildViewComments(context),

        // Time
        _buildTimeAgo(context, isDark),

        const SizedBox(height: 12),
        const InstagramDivider(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onProfileTap,
            child: CircleAvatar(
              radius: 16,
              backgroundImage: widget.status.avatar.isNotEmpty
                  ? CachedNetworkImageProvider(widget.status.avatar)
                  : null,
              child: widget.status.avatar.isEmpty
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: widget.onProfileTap,
              child: Text(
                widget.status.acct,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Icon(
            Icons.more_vert,
            size: 20,
            color: isDark ? Colors.white : Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: CachedNetworkImage(
              imageUrl: widget.status.attach,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: InstagramLoadingIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              ),
            ),
          ),
          // Heart animation overlay
          AnimatedBuilder(
            animation: _likeAnimation,
            builder: (context, child) {
              return _likeAnimation.value > 0
                  ? Opacity(
                      opacity: 1.0 - _likeAnimation.value,
                      child: Transform.scale(
                        scale: 0.5 + (_likeAnimation.value * 1.5),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 100,
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          InstagramActionButton(
            icon: widget.status.favorited
                ? Icons.favorite
                : Icons.favorite_border,
            onTap: () => widget.onLike?.call(),
            color: widget.status.favorited
                ? const Color(0xFFED4956)
                : null,
          ),
          const SizedBox(width: 16),
          InstagramActionButton(
            icon: Icons.mode_comment_outlined,
            onTap: () => widget.onComment?.call(),
          ),
          const SizedBox(width: 16),
          InstagramActionButton(
            icon: Icons.send_outlined,
            onTap: () => widget.onShare?.call(),
          ),
          const Spacer(),
          InstagramActionButton(
            icon: widget.status.reblogged
                ? Icons.bookmark
                : Icons.bookmark_border,
            onTap: () => widget.onBookmark?.call(),
          ),
        ],
      ),
    );
  }

  Widget _buildLikesCount(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        '${widget.status.favourites_count} ${widget.status.favourites_count == 1 ? 'like' : 'likes'}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCaption(BuildContext context) {
    // Remove HTML tags for display
    final cleanContent = widget.status.content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');

    if (cleanContent.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14,
          ),
          children: [
            TextSpan(
              text: '${widget.status.acct} ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: cleanContent),
          ],
        ),
      ),
    );
  }

  Widget _buildViewComments(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GestureDetector(
        onTap: widget.onComment,
        child: Text(
          'View all ${widget.status.replies_count} ${widget.status.replies_count == 1 ? 'comment' : 'comments'}',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFA8A8A8)
                : const Color(0xFF8E8E8E),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeAgo(BuildContext context, bool isDark) {
    DateTime? createdAt;
    try {
      if (widget.status.created_at.isNotEmpty) {
        createdAt = DateTime.parse(widget.status.created_at);
      }
    } catch (_) {}

    if (createdAt == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(
        timeago.format(createdAt, locale: 'en_short'),
        style: TextStyle(
          fontSize: 11,
          color: isDark ? const Color(0xFFA8A8A8) : const Color(0xFF8E8E8E),
        ),
      ),
    );
  }
}
