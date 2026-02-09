import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';

class MutedBlockedPage extends StatefulWidget {
  final ApiService apiService;

  const MutedBlockedPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<MutedBlockedPage> createState() => _MutedBlockedPageState();
}

class _MutedBlockedPageState extends State<MutedBlockedPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _mutedUsers = [];
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final mutes = await widget.apiService.getMutes();
      final blocks = await widget.apiService.getBlocks();
      setState(() {
        _mutedUsers = mutes;
        _blockedUsers = blocks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unmute(String userId, int index) async {
    try {
      await widget.apiService.unmuteUser(userId);
      setState(() => _mutedUsers.removeAt(index));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unmute: $e'), backgroundColor: Colors.red.shade800),
        );
      }
    }
  }

  Future<void> _unblock(String userId, int index) async {
    try {
      await widget.apiService.unblockUser(userId);
      setState(() => _blockedUsers.removeAt(index));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unblock: $e'), backgroundColor: Colors.red.shade800),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: CyberpunkTheme.backgroundBlack,
        elevation: 0,
        title: const Text(
          'Muted & Blocked',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CyberpunkTheme.textWhite),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: CyberpunkTheme.neonCyan,
          indicatorWeight: 2,
          labelColor: CyberpunkTheme.neonCyan,
          unselectedLabelColor: CyberpunkTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: [
            Tab(text: 'Muted (${_mutedUsers.length})'),
            Tab(text: 'Blocked (${_blockedUsers.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: CyberpunkTheme.neonCyan))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(_mutedUsers, isMuted: true),
                _buildUserList(_blockedUsers, isMuted: false),
              ],
            ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users, {required bool isMuted}) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMuted ? Icons.volume_off_rounded : Icons.block_rounded,
              size: 48,
              color: CyberpunkTheme.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              isMuted ? S.of(context).noMutedUsers : S.of(context).noBlockedUsers,
              style: const TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: CyberpunkTheme.neonCyan,
      backgroundColor: CyberpunkTheme.surfaceDark,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final username = user['username'] ?? user['acct'] ?? '';
          final displayName = user['display_name'] ?? username;
          final avatarUrl = user['avatar'] ?? user['avatar_static'] ?? '';
          final userId = user['id']?.toString() ?? '';

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: CyberpunkTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CyberpunkTheme.borderDark),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: CyberpunkTheme.surfaceDark,
                backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? const Icon(Icons.person, color: CyberpunkTheme.textTertiary, size: 22)
                    : null,
              ),
              title: Text(
                displayName,
                style: const TextStyle(color: CyberpunkTheme.textWhite, fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '@$username',
                style: const TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: TextButton(
                onPressed: () {
                  if (isMuted) {
                    _unmute(userId, index);
                  } else {
                    _unblock(userId, index);
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: isMuted ? CyberpunkTheme.neonCyan : CyberpunkTheme.neonPink,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: (isMuted ? CyberpunkTheme.neonCyan : CyberpunkTheme.neonPink).withOpacity(0.3),
                    ),
                  ),
                ),
                child: Text(
                  isMuted ? 'Unmute' : 'Unblock',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
