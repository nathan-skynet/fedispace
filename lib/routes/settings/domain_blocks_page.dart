import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';

/// Domain blocks management page
class DomainBlocksPage extends StatefulWidget {
  final ApiService apiService;

  const DomainBlocksPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<DomainBlocksPage> createState() => _DomainBlocksPageState();
}

class _DomainBlocksPageState extends State<DomainBlocksPage> {
  List<String> _domains = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDomains();
  }

  Future<void> _loadDomains() async {
    setState(() => _isLoading = true);
    try {
      _domains = await widget.apiService.getDomainBlocks();
    } catch (e, s) {
      appLogger.error('Error loading domain blocks', e, s);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _addDomain() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: CyberpunkTheme.borderDark)),
        title: Text(S.of(context).blockDomain, style: const TextStyle(color: CyberpunkTheme.textWhite, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: CyberpunkTheme.textWhite),
          decoration: InputDecoration(
            hintText: 'example.com',
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
              final domain = controller.text.trim();
              if (domain.isEmpty) return;
              Navigator.pop(ctx);
              final ok = await widget.apiService.blockDomain(domain);
              if (ok && mounted) {
                setState(() => _domains.insert(0, domain));
              }
            },
            child: Text(S.of(context).block, style: const TextStyle(color: CyberpunkTheme.neonPink, fontWeight: FontWeight.w600)),
          ),
        ],
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
        title: Text(S.of(context).blockedDomains, style: const TextStyle(color: CyberpunkTheme.textWhite, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: CyberpunkTheme.neonCyan),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: CyberpunkTheme.neonCyan),
            onPressed: _addDomain,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: InstagramLoadingIndicator(size: 28))
          : _domains.isEmpty
              ? Center(child: Text(S.of(context).noBlockedDomains, style: const TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 16)))
              : RefreshIndicator(
                  onRefresh: _loadDomains,
                  color: CyberpunkTheme.neonCyan,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _domains.length,
                    separatorBuilder: (_, __) => const Divider(color: CyberpunkTheme.borderDark, height: 1),
                    itemBuilder: (context, index) {
                      final domain = _domains[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: CyberpunkTheme.neonPink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.block, color: CyberpunkTheme.neonPink, size: 20),
                        ),
                        title: Text(domain, style: const TextStyle(color: CyberpunkTheme.textWhite, fontSize: 14)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: CyberpunkTheme.textTertiary, size: 18),
                          onPressed: () async {
                            final ok = await widget.apiService.unblockDomain(domain);
                            if (ok && mounted) {
                              setState(() => _domains.removeAt(index));
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('$domain unblocked', style: const TextStyle(color: Colors.white)),
                                behavior: SnackBarBehavior.floating,
                              ));
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
