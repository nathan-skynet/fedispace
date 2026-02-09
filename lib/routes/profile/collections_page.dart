import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';

/// Collections viewer — shows all collections for current user (or a specified user)
class CollectionsPage extends StatefulWidget {
  final ApiService apiService;
  final String? accountId; // null = current user

  const CollectionsPage({Key? key, required this.apiService, this.accountId}) : super(key: key);

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  List<Map<String, dynamic>> _collections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    setState(() => _isLoading = true);
    try {
      final id = widget.accountId ?? widget.apiService.currentAccount?.id;
      if (id != null) {
        _collections = await widget.apiService.getUserCollections(id);
      } else {
        _collections = await widget.apiService.getMyCollections();
      }
    } catch (e, s) {
      appLogger.error('Error loading collections', e, s);
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
        title: Text(S.of(context).collections, style: const TextStyle(color: CyberpunkTheme.textWhite, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: CyberpunkTheme.neonCyan),
      ),
      body: _isLoading
          ? const Center(child: InstagramLoadingIndicator(size: 28))
          : _collections.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.collections_outlined, size: 56, color: CyberpunkTheme.neonCyan.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(S.of(context).noCollections, style: const TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCollections,
                  color: CyberpunkTheme.neonCyan,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _collections.length,
                    itemBuilder: (context, index) {
                      final col = _collections[index];
                      final title = col['title'] ?? 'Untitled';
                      final description = col['description'] ?? '';
                      final thumbUrl = col['thumb'] ?? col['thumbnail'] ?? '';
                      final postCount = col['post_count'] ?? col['items_count'] ?? 0;

                      return GestureDetector(
                        onTap: () => _openCollection(col['id'].toString(), title),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: CyberpunkTheme.cardDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CyberpunkTheme.borderDark),
                          ),
                          child: Row(
                            children: [
                              if (thumbUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                  child: CachedNetworkImage(
                                    imageUrl: thumbUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      width: 80, height: 80,
                                      color: CyberpunkTheme.surfaceDark,
                                      child: const Icon(Icons.image, color: CyberpunkTheme.textTertiary),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 80, height: 80,
                                  decoration: BoxDecoration(
                                    color: CyberpunkTheme.surfaceDark,
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                  ),
                                  child: const Icon(Icons.collections_outlined, color: CyberpunkTheme.neonCyan, size: 32),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(title, style: const TextStyle(color: CyberpunkTheme.textWhite, fontWeight: FontWeight.w600, fontSize: 15)),
                                      if (description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(description, style: const TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                      const SizedBox(height: 4),
                                      Text('$postCount posts', style: const TextStyle(color: CyberpunkTheme.neonCyan, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: CyberpunkTheme.textTertiary),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _openCollection(String collectionId, String title) async {
    final items = await widget.apiService.getCollectionItems(collectionId);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CollectionDetailPage(
          title: title,
          items: items,
          apiService: widget.apiService,
        ),
      ),
    );
  }
}

/// Detail view for a collection — shows grid of posts
class _CollectionDetailPage extends StatelessWidget {
  final String title;
  final List<Status> items;
  final ApiService apiService;

  const _CollectionDetailPage({required this.title, required this.items, required this.apiService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: CyberpunkTheme.backgroundBlack,
        elevation: 0,
        title: Text(title, style: const TextStyle(color: CyberpunkTheme.textWhite, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: CyberpunkTheme.neonCyan),
      ),
      body: items.isEmpty
          ? Center(child: Text(S.of(context).emptyCollection, style: const TextStyle(color: CyberpunkTheme.textSecondary)))
          : GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final post = items[index];
                final imageUrl = post.hasMediaAttachments ? post.attach : '';
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/PostDetail', arguments: {'post': post, 'apiService': apiService});
                  },
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                      : Container(
                          color: CyberpunkTheme.cardDark,
                          child: const Icon(Icons.article_outlined, color: CyberpunkTheme.textTertiary),
                        ),
                );
              },
            ),
    );
  }
}
