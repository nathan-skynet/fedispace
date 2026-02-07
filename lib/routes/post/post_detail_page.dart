import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Instagram-style post detail view with comments
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

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.post.favorited;
    _isBookmarked = widget.post.reblogged;
    _favoritesCount = widget.post.favourites_count;
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });

    try {
      appLogger.debug('Loading comments for post: ${widget.post.id}');
      final contextMap = await widget.apiService.getContext(widget.post.id);
      
      // Parse descendants (replies)
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
      setState(() {
        _isLoadingComments = false;
      });
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
    try {
      // TODO: Implement bookmark API call
      setState(() {
        _isBookmarked = !_isBookmarked;
      });
    } catch (error, stackTrace) {
      appLogger.error('Error toggling bookmark', error, stackTrace);
    }
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      appLogger.debug('Posting comment: $text');
      await widget.apiService.createPosts(
        inReplyToId: widget.post.id, // Reply to this post
        content: text,
      );
      
      _commentController.clear();
      _commentFocus.unfocus();
      _loadComments(); // Reload to show new comment
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment posted!')),
      );
    } catch (error, stackTrace) {
      appLogger.error('Error posting comment', error, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post comment')),
      );
    }
  }

  void _navigateToProfile(String userId) {
    Navigator.pushNamed(
      context,
      '/UserProfile',
      arguments: {'userId': userId},
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPostHeader(isDark),
                  if (widget.post.hasMediaAttachments) _buildPostImage(),
                  _buildPostActions(),
                  _buildLikesCount(),
                  _buildPostCaption(isDark),
                  _buildPostTime(isDark),
                  const InstagramDivider(),
                  _buildCommentsSection(isDark),
                ],
              ),
            ),
          ),
          _buildCommentInput(isDark),
        ],
      ),
    );
  }

  Widget _buildPostHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(widget.post.account.id),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: widget.post.avatar.isNotEmpty
                  ? CachedNetworkImageProvider(widget.post.avatar)
                  : null,
              child: widget.post.avatar.isEmpty
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToProfile(widget.post.account.id),
              child: Text(
                widget.post.acct,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostImage() {
    return AspectRatio(
      aspectRatio: 1.0,
      child: CachedNetworkImage(
        imageUrl: widget.post.attach,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(child: InstagramLoadingIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        ),
      ),
    );
  }

  Widget _buildPostActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          InstagramActionButton(
            icon: _isFavorited ? Icons.favorite : Icons.favorite_border,
            onTap: _toggleLike,
            color: _isFavorited ? const Color(0xFFED4956) : null,
          ),
          const SizedBox(width: 16),
          InstagramActionButton(
            icon: Icons.mode_comment_outlined,
            onTap: () {
              _commentFocus.requestFocus();
            },
          ),
          const SizedBox(width: 16),
          InstagramActionButton(
            icon: Icons.send_outlined,
            onTap: () {
              // TODO: Share
            },
          ),
          const Spacer(),
          InstagramActionButton(
            icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            onTap: _toggleBookmark,
          ),
        ],
      ),
    );
  }

  Widget _buildLikesCount() {
    if (_favoritesCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(
        '$_favoritesCount ${_favoritesCount == 1 ? 'like' : 'likes'}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPostCaption(bool isDark) {
    final cleanContent = widget.post.content
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
            color: isDark ? Colors.white : Colors.black,
            fontSize: 14,
          ),
          children: [
            TextSpan(
              text: '${widget.post.acct} ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: cleanContent),
          ],
        ),
      ),
    );
  }

  Widget _buildPostTime(bool isDark) {
    DateTime? createdAt;
    try {
      if (widget.post.created_at.isNotEmpty) {
        createdAt = DateTime.parse(widget.post.created_at);
      }
    } catch (_) {}

    if (createdAt == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        timeago.format(createdAt, locale: 'en'),
        style: TextStyle(
          fontSize: 12,
          color: isDark ? const Color(0xFFA8A8A8) : const Color(0xFF8E8E8E),
        ),
      ),
    );
  }

  Widget _buildCommentsSection(bool isDark) {
    if (_isLoadingComments) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: InstagramLoadingIndicator(size: 24)),
      );
    }

    if (_comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.mode_comment_outlined,
                size: 48,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              const SizedBox(height: 12),
              Text(
                'No comments yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Be the first to comment',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            '${_comments.length} ${_comments.length == 1 ? 'Comment' : 'Comments'}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ..._comments.map((comment) => _CommentItem(
              comment: comment,
              isDark: isDark,
              onProfileTap: () => _navigateToProfile(comment.account.id),
            )),
      ],
    );
  }

  Widget _buildCommentInput(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF262626) : const Color(0xFFDBDBDB),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _commentController,
                focusNode: _commentFocus,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFFA8A8A8)
                        : const Color(0xFF8E8E8E),
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            TextButton(
              onPressed: _postComment,
              child: const Text(
                'Post',
                style: TextStyle(
                  color: Color(0xFF0095F6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Status comment;
  final bool isDark;
  final VoidCallback onProfileTap;

  const _CommentItem({
    Key? key,
    required this.comment,
    required this.isDark,
    required this.onProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: CircleAvatar(
              radius: 16,
              backgroundImage: comment.avatar.isNotEmpty
                  ? CachedNetworkImageProvider(comment.avatar)
                  : null,
              child: comment.avatar.isEmpty
                  ? const Icon(Icons.person, size: 16)
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
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: '${comment.acct} ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: cleanContent),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (createdAt != null)
                      Text(
                        timeago.format(createdAt, locale: 'en_short'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFFA8A8A8)
                              : const Color(0xFF8E8E8E),
                        ),
                      ),
                    if (comment.favourites_count > 0) ...[
                      const SizedBox(width: 12),
                      Text(
                        '${comment.favourites_count} ${comment.favourites_count == 1 ? 'like' : 'likes'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFA8A8A8)
                              : const Color(0xFF8E8E8E),
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    Text(
                      'Reply',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFA8A8A8)
                            : const Color(0xFF8E8E8E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              comment.favorited ? Icons.favorite : Icons.favorite_border,
              size: 12,
              color: comment.favorited ? const Color(0xFFED4956) : null,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              // TODO: Like comment
            },
          ),
        ],
      ),
    );
  }
}
