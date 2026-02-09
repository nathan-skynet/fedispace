import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/models/account.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Follow Requests page — accept or reject pending follow requests
class FollowRequestsPage extends StatefulWidget {
  final ApiService apiService;

  const FollowRequestsPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<FollowRequestsPage> createState() => _FollowRequestsPageState();
}

class _FollowRequestsPageState extends State<FollowRequestsPage> {
  List<Account> _requests = [];
  bool _isLoading = true;
  final Set<String> _processing = {};

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final requests = await widget.apiService.getFollowRequests();
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e, s) {
      appLogger.error('Error loading follow requests', e, s);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _accept(Account account) async {
    if (account.id == null) return;
    setState(() => _processing.add(account.id!));
    try {
      final ok = await widget.apiService.acceptFollowRequest(account.id!);
      if (ok) {
        setState(() => _requests.removeWhere((a) => a.id == account.id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Accepted @${account.username}'),
              backgroundColor: CyberpunkTheme.neonCyan.withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      appLogger.error('Error accepting follow request', e);
    } finally {
      setState(() => _processing.remove(account.id));
    }
  }

  Future<void> _reject(Account account) async {
    if (account.id == null) return;
    setState(() => _processing.add(account.id!));
    try {
      final ok = await widget.apiService.rejectFollowRequest(account.id!);
      if (ok) {
        setState(() => _requests.removeWhere((a) => a.id == account.id));
      }
    } catch (e) {
      appLogger.error('Error rejecting follow request', e);
    } finally {
      setState(() => _processing.remove(account.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: CyberpunkTheme.backgroundBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: CyberpunkTheme.textWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Follow Requests',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: CyberpunkTheme.textWhite,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: CyberpunkTheme.neonCyan))
          : _requests.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadRequests,
                  color: CyberpunkTheme.neonCyan,
                  backgroundColor: CyberpunkTheme.cardDark,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (ctx, i) => _buildRequestCard(_requests[i]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CyberpunkTheme.cardDark,
              border: Border.all(color: CyberpunkTheme.borderDark),
            ),
            child: const Icon(Icons.person_add_disabled_rounded, size: 36, color: CyberpunkTheme.textTertiary),
          ),
          const SizedBox(height: 20),
          Text(
            S.of(context).noPendingRequests,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CyberpunkTheme.textWhite),
          ),
          const SizedBox(height: 6),
          Text(
            S.of(context).allCaughtUp,
            style: const TextStyle(fontSize: 14, color: CyberpunkTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Account account) {
    final isProcessing = _processing.contains(account.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: CyberpunkTheme.cardDark,
          border: Border.all(color: CyberpunkTheme.borderDark, width: 0.5),
        ),
        child: Row(
          children: [
            // Avatar
            GestureDetector(
              onTap: () {
                if (account.id != null) {
                  Navigator.pushNamed(context, '/UserProfile', arguments: {'userId': account.id});
                }
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      CyberpunkTheme.neonCyan.withOpacity(0.6),
                      CyberpunkTheme.neonPink.withOpacity(0.4),
                    ],
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: CyberpunkTheme.backgroundBlack,
                  backgroundImage: (account.avatar != null && account.avatar!.isNotEmpty)
                      ? CachedNetworkImageProvider(account.avatar!) : null,
                  child: (account.avatar == null || account.avatar!.isEmpty)
                      ? const Icon(Icons.person_rounded, size: 24, color: CyberpunkTheme.textTertiary)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (account.display_name != null && account.display_name!.isNotEmpty)
                        ? account.display_name! : (account.username ?? ''),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CyberpunkTheme.textWhite),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${account.username ?? ''}',
                    style: const TextStyle(fontSize: 13, color: CyberpunkTheme.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Action buttons
            if (isProcessing)
              const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: CyberpunkTheme.neonCyan),
              )
            else ...[
              // Accept
              GestureDetector(
                onTap: () => _accept(account),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [CyberpunkTheme.neonCyan, Color(0xFF00E5FF)],
                    ),
                    boxShadow: [
                      BoxShadow(color: CyberpunkTheme.neonCyan.withOpacity(0.3), blurRadius: 8),
                    ],
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Reject
              GestureDetector(
                onTap: () => _reject(account),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CyberpunkTheme.borderDark),
                    color: CyberpunkTheme.surfaceDark,
                  ),
                  child: const Icon(Icons.close_rounded, size: 16, color: CyberpunkTheme.textTertiary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
