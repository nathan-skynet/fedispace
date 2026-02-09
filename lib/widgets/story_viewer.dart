import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fedispace/models/story.dart';
import 'package:fedispace/models/account.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class StoryViewer extends StatefulWidget {
  final Story story;
  final ApiService? apiService;

  const StoryViewer({Key? key, required this.story, this.apiService}) : super(key: key);

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animController;
  VideoPlayerController? _videoController;
  int _currentIndex = 0;
  final TextEditingController _replyController = TextEditingController();
  bool _isOwnStory = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(vsync: this);

    // Check if this is our own story
    if (widget.apiService?.currentAccount != null) {
      _isOwnStory = widget.story.account.id == widget.apiService!.currentAccount!.id;
    }

    // Start first story
    if (widget.story.items.isNotEmpty) {
      final firstItem = widget.story.items.first;
      appLogger.info('StoryViewer: Loading first item type=${firstItem.type} url=${firstItem.url}');
      _loadStory(item: firstItem);

      // Mark as viewed
      if (widget.apiService != null) {
        widget.apiService!.markStoryViewed(firstItem.id).catchError((e) {
          appLogger.error('Failed to mark story as viewed', e);
        });
      }
    }

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animController.stop();
        _animController.reset();
        setState(() {
          if (_currentIndex + 1 < widget.story.items.length) {
            _currentIndex += 1;
            _loadStory(item: widget.story.items[_currentIndex]);
          } else {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    _videoController?.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _loadStory({required StoryItem item, bool animateToPage = true}) {
    _animController.stop();
    _animController.reset();
    _videoController?.dispose();
    _videoController = null;

    appLogger.info('StoryViewer._loadStory: type=${item.type} url=${item.url}');

    if (item.type == 'video') {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(item.url))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            if (_videoController!.value.isInitialized) {
              _animController.duration = _videoController!.value.duration;
              _videoController!.play();
              _animController.forward();
            }
          }
        }).catchError((e) {
          appLogger.error('Video init error', e);
          // Fallback: treat as 10s image
          if (mounted) {
            _animController.duration = const Duration(seconds: 10);
            _animController.forward();
          }
        });
    } else {
      // Photo — default duration
      _animController.duration = Duration(seconds: item.duration > 0 ? item.duration : 5);
      _animController.forward();
    }
  }

  void _onTapDown(TapDownDetails details) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dx = details.globalPosition.dx;

    if (dx < screenWidth / 3) {
      setState(() {
        if (_currentIndex - 1 >= 0) {
          _currentIndex -= 1;
          _loadStory(item: widget.story.items[_currentIndex]);
        }
      });
    } else {
      setState(() {
        if (_currentIndex + 1 < widget.story.items.length) {
          _currentIndex += 1;
          _loadStory(item: widget.story.items[_currentIndex]);
        } else {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _showViewers() async {
    if (widget.apiService == null) return;
    final viewers = await widget.apiService!.getStoryViewers(
      widget.story.items[_currentIndex].id,
    );
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '${viewers.length} viewer${viewers.length == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            ...viewers.take(20).map((a) => ListTile(
              leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(a.avatar),
              ),
              title: Text(a.displayName, style: const TextStyle(color: Colors.white)),
              subtitle: Text('@${a.username}', style: const TextStyle(color: Colors.white60)),
            )),
            if (viewers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No viewers yet', style: TextStyle(color: Colors.white54, fontSize: 15)),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Story', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to delete this story?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final deletedIndex = _currentIndex;
              final ok = await widget.apiService!.deleteStory(
                widget.story.items[deletedIndex].id,
              );
              if (ok && mounted) {
                // Remove the deleted item from the list
                setState(() {
                  widget.story.items.removeAt(deletedIndex);
                  if (widget.story.items.isEmpty) {
                    // No more stories, close viewer
                    Navigator.of(context).pop();
                    return;
                  }
                  // Adjust current index if we deleted the last item
                  if (_currentIndex >= widget.story.items.length) {
                    _currentIndex = widget.story.items.length - 1;
                  }
                  _loadStory(item: widget.story.items[_currentIndex]);
                });
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent(StoryItem item) {
    if (item.type == 'video') {
      // Video content
      if (_videoController != null && _videoController!.value.isInitialized) {
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    // Image content (photo or any non-video type)
    final imageUrl = item.url;
    if (imageUrl.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
            SizedBox(height: 8),
            Text('Image unavailable', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        appLogger.error('Story image failed to load: $imageUrl', error);
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 48),
              const SizedBox(height: 8),
              Text(
                'Failed to load image',
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 4),
              Text(
                imageUrl.length > 60 ? '...${imageUrl.substring(imageUrl.length - 60)}' : imageUrl,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.story.items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No stories', style: TextStyle(color: Colors.white54, fontSize: 18)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go back', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final StoryItem item = widget.story.items[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onTapDown,
        child: Stack(
          children: [
            // ── Fullscreen media content ──────────────────────────
            Positioned.fill(
              child: _buildMediaContent(item),
            ),

            // ── Top gradient overlay ──────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              height: 140,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── Progress Bars ─────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 10,
              right: 10,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Row(
                    children: widget.story.items.asMap().map((i, e) {
                      return MapEntry(
                        i,
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: i == _currentIndex
                                    ? _animController.value
                                    : i < _currentIndex ? 1.0 : 0.0,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation(Colors.white),
                                minHeight: 2.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).values.toList(),
                  );
                },
              ),
            ),

            // ── User Info + Close button ──────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: CachedNetworkImageProvider(widget.story.account.avatar),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.story.account.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom gradient overlay ───────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: _isOwnStory ? 180 : 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── Own story: Viewers + Delete buttons ───────────────
            if (_isOwnStory && widget.apiService != null)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                left: 24,
                right: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Viewers button
                    GestureDetector(
                      onTap: _showViewers,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_rounded, color: Colors.white, size: 28),
                            SizedBox(width: 10),
                            Text(
                              'Viewers',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Delete button
                    GestureDetector(
                      onTap: _confirmDelete,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_rounded, color: Colors.redAccent, size: 28),
                            SizedBox(width: 10),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Other's story: Reply bar ──────────────────────────
            if (!_isOwnStory && widget.apiService != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Reply to story...',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.15),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            final text = _replyController.text.trim();
                            if (text.isEmpty) return;
                            final ok = await widget.apiService!.commentOnStory(
                              widget.story.items[_currentIndex].id,
                              text,
                            );
                            if (ok && mounted) {
                              _replyController.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reply sent!', style: TextStyle(color: Colors.white)),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
