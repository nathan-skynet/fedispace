import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';

/// Content filters (muted words) management page
class ContentFiltersPage extends StatefulWidget {
  final ApiService apiService;

  const ContentFiltersPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<ContentFiltersPage> createState() => _ContentFiltersPageState();
}

class _ContentFiltersPageState extends State<ContentFiltersPage> {
  List<Map<String, dynamic>> _filters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    setState(() => _isLoading = true);
    try {
      _filters = await widget.apiService.getFilters();
    } catch (e, s) {
      appLogger.error('Error loading filters', e, s);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _addFilter() {
    final titleCtrl = TextEditingController();
    final keywordCtrl = TextEditingController();
    String selectedAction = 'warn';
    final contextOptions = <String>['home', 'notifications', 'public', 'thread'];
    final selectedContexts = <String>{'home', 'public'};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: CyberpunkTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: CyberpunkTheme.borderDark)),
          title: Text(S.of(context).newFilter, style: const TextStyle(color: CyberpunkTheme.textWhite, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: CyberpunkTheme.textWhite),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: const TextStyle(color: CyberpunkTheme.textTertiary),
                    filled: true,
                    fillColor: CyberpunkTheme.cardDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: keywordCtrl,
                  style: const TextStyle(color: CyberpunkTheme.textWhite),
                  decoration: InputDecoration(
                    labelText: 'Keyword',
                    labelStyle: const TextStyle(color: CyberpunkTheme.textTertiary),
                    filled: true,
                    fillColor: CyberpunkTheme.cardDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Text(S.of(context).action, style: const TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _filterChip('Warn', selectedAction == 'warn', () => setDialogState(() => selectedAction = 'warn')),
                    const SizedBox(width: 8),
                    _filterChip('Hide', selectedAction == 'hide', () => setDialogState(() => selectedAction = 'hide')),
                  ],
                ),
                const SizedBox(height: 12),
                Text(S.of(context).applyTo, style: const TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: contextOptions.map((c) => _filterChip(
                    c[0].toUpperCase() + c.substring(1),
                    selectedContexts.contains(c),
                    () => setDialogState(() {
                      if (selectedContexts.contains(c)) {
                        selectedContexts.remove(c);
                      } else {
                        selectedContexts.add(c);
                      }
                    }),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.of(context).cancel, style: const TextStyle(color: CyberpunkTheme.textTertiary))),
            TextButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final keywords = keywordCtrl.text.trim().isNotEmpty
                    ? [{'keyword': keywordCtrl.text.trim(), 'whole_word': 'true'}]
                    : null;
                final result = await widget.apiService.createFilter(
                  title: titleCtrl.text.trim(),
                  context: selectedContexts.toList(),
                  filterAction: selectedAction,
                  keywords: keywords,
                );
                if (result != null && mounted) {
                  _loadFilters();
                }
              },
              child: Text(S.of(context).create, style: const TextStyle(color: CyberpunkTheme.neonCyan, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? CyberpunkTheme.neonCyan.withOpacity(0.2) : CyberpunkTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? CyberpunkTheme.neonCyan : CyberpunkTheme.borderDark),
        ),
        child: Text(label, style: TextStyle(color: selected ? CyberpunkTheme.neonCyan : CyberpunkTheme.textSecondary, fontSize: 12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: CyberpunkTheme.backgroundBlack,
        elevation: 0,
        title: Text(S.of(context).contentFilters, style: const TextStyle(color: CyberpunkTheme.textWhite, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: CyberpunkTheme.neonCyan),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: CyberpunkTheme.neonCyan),
            onPressed: _addFilter,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: InstagramLoadingIndicator(size: 28))
          : _filters.isEmpty
              ? Center(child: Text(S.of(context).noContentFilters, style: const TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 16)))
              : RefreshIndicator(
                  onRefresh: _loadFilters,
                  color: CyberpunkTheme.neonCyan,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const Divider(color: CyberpunkTheme.borderDark, height: 1),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final title = filter['title'] ?? 'Untitled';
                      final action = filter['filter_action'] ?? 'warn';
                      final contexts = (filter['context'] as List?)?.join(', ') ?? '';
                      final keywords = (filter['keywords'] as List?)?.map((k) => k['keyword'] ?? '').join(', ') ?? '';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: CyberpunkTheme.neonCyan.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            action == 'hide' ? Icons.visibility_off : Icons.warning_amber_rounded,
                            color: action == 'hide' ? CyberpunkTheme.neonPink : CyberpunkTheme.neonCyan,
                            size: 20,
                          ),
                        ),
                        title: Text(title, style: const TextStyle(color: CyberpunkTheme.textWhite, fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (keywords.isNotEmpty)
                              Text('Keywords: $keywords', style: const TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 12)),
                            Text('$action • $contexts', style: const TextStyle(color: CyberpunkTheme.textTertiary, fontSize: 11)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: CyberpunkTheme.textTertiary, size: 18),
                          onPressed: () async {
                            final id = filter['id']?.toString();
                            if (id == null) return;
                            final ok = await widget.apiService.deleteFilter(id);
                            if (ok && mounted) {
                              setState(() => _filters.removeAt(index));
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
