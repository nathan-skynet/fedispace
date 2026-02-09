import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';

/// Archived posts page — displays grid of archived posts with unarchive option
class ArchivedPostsPage extends StatefulWidget {
  final ApiService apiService;

  const ArchivedPostsPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<ArchivedPostsPage> createState() => _ArchivedPostsPageState();
}

class _ArchivedPostsPageState extends State<ArchivedPostsPage> {
  List<Status> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchived();
  }

  Future<void> _loadArchived() async {
    setState(() => _isLoading = true);
    try {
      _posts = await widget.apiService.getArchivedPosts(limit: 40);
    } catch (e, s) {
      appLogger.error('Error loading archived posts', e, s);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: CyberpunkTheme.backgroundBlack,
        elevation: 0,
        title: Text(S.of(context).archive, style: const TextStyle(color: CyberpunkTheme.textWhite, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: CyberpunkTheme.neonCyan),
      ),
      body: _isLoading
          ? const Center(child: InstagramLoadingIndicator(size: 28))
          : _posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.archive_outlined, size: 56, color: CyberpunkTheme.neonCyan.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(S.of(context).noArchivedPosts, style: const TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadArchived,
                  color: CyberpunkTheme.neonCyan,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(2),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      final imageUrl = post.hasMediaAttachments ? post.attach : '';
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/PostDetail', arguments: {'post': post, 'apiService': widget.apiService});
                        },
                        onLongPress: () => _showUnarchiveDialog(post, index),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            imageUrl.isNotEmpty
                                ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                                : Container(
                                    color: CyberpunkTheme.cardDark,
                                    child: const Center(child: Icon(Icons.article_outlined, color: CyberpunkTheme.textTertiary)),
                                  ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                                child: const Icon(Icons.archive_outlined, color: CyberpunkTheme.neonCyan, size: 14),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _showUnarchiveDialog(Status post, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: CyberpunkTheme.borderDark)),
        title: Text(S.of(context).unarchive, style: const TextStyle(color: CyberpunkTheme.textWhite, fontWeight: FontWeight.w700)),
        content: Text(S.of(context).restorePost, style: const TextStyle(color: CyberpunkTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.of(context).cancel, style: const TextStyle(color: CyberpunkTheme.textTertiary))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await widget.apiService.unarchivePost(post.id);
              if (ok && mounted) {
                setState(() => _posts.removeAt(index));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(S.of(context).postRestored, style: const TextStyle(color: Colors.white)),
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: Text(S.of(context).unarchive, style: const TextStyle(color: CyberpunkTheme.neonCyan, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
