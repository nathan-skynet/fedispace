import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'conversation_detail_page.dart';

/// New Direct Message - Select recipient page
class NewMessagePage extends StatefulWidget {
  final ApiService apiService;

  const NewMessagePage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<NewMessagePage> createState() => _NewMessagePageState();
}

class _NewMessagePageState extends State<NewMessagePage> {
  final TextEditingController _searchController = TextEditingController();
  final List<_UserSearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      appLogger.debug('Searching users: $query');
      final results = await widget.apiService.searchAccounts(query);
      
      setState(() {
        _isSearching = false;
         _searchResults.clear();
         for (var account in results) {
           _searchResults.add(_UserSearchResult(
             id: account.id,
             username: account.username,
             displayName: account.display_name,
             avatarUrl: account.avatar.isNotEmpty ? account.avatar : null,
           ));
         }
      });
    } catch (error, stackTrace) {
      appLogger.error('Error searching users', error, stackTrace);
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _startConversation(_UserSearchResult user) {
    // Navigate to conversation page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationDetailPage(
          apiService: widget.apiService,
          conversationId: 'new_${user.id}', // Temp ID
          recipientName: user.displayName,
          recipientUsername: user.username,
          recipientAvatar: user.avatarUrl,
          recipientId: user.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).newMessage),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? S.of(context).searchPeople
                              : S.of(context).noResults,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.avatarUrl != null
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: user.avatarUrl == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(user.displayName),
                            subtitle: Text('@${user.username}'),
                            onTap: () => _startConversation(user),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// Placeholder user search result model
class _UserSearchResult {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  _UserSearchResult({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });
}
