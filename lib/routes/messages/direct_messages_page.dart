import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:fedispace/routes/messages/new_message_page.dart';
import 'package:fedispace/routes/messages/conversation_detail_page.dart';
import 'package:fedispace/widgets/story_bar.dart';

class DirectMessagesPage extends StatefulWidget {
  final ApiService apiService;

  const DirectMessagesPage({Key? key, required this.apiService})
      : super(key: key);

  @override
  State<DirectMessagesPage> createState() => _DirectMessagesPageState();
}

class _DirectMessagesPageState extends State<DirectMessagesPage> {
  final List<_Conversation> _conversations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);

    try {
      appLogger.debug('Loading direct messages');
      
      final inboxConversations = await widget.apiService.getConversationsByScope(scope: 'inbox', limit: 40);
      final sentConversations = await widget.apiService.getConversationsByScope(scope: 'sent', limit: 40);
      
      final List<dynamic> allConversations = [...inboxConversations, ...sentConversations];
      
      final Map<String, _Conversation> convByPartner = {};
      _lastParseError = null;
      
      for (var conv in allConversations) {
        try {
           if (conv == null) continue;
           
           final Map<String, dynamic> convMap = conv is Map ? Map<String, dynamic>.from(conv) : {};
           
           List<dynamic>? accounts;
           if (convMap.containsKey('accounts') && convMap['accounts'] is List) {
               accounts = convMap['accounts'];
           } else if (convMap.containsKey('participants') && convMap['participants'] is List) {
               accounts = convMap['participants'];
           }
           
           if (accounts != null && accounts.isNotEmpty) {
              final account = accounts[0];
              final String partnerId = account['id']?.toString() ?? '';
              
              final lastStatus = convMap['last_status'] ?? convMap['latest_message'];
              final String threadId = convMap['id']?.toString() ?? '';
              
              String lastMsgContent = '';
              if (lastStatus != null) {
                  lastMsgContent = lastStatus['content_text'] ?? lastStatus['content'] ?? lastStatus['body'] ?? lastStatus['message'] ?? '';
                  lastMsgContent = lastMsgContent.replaceAll(RegExp(r'<[^>]*>'), '');
              }
              
              DateTime? lastMsgTime;
              if (lastStatus != null) {
                  final created = lastStatus['created_at'];
                  if (created != null) {
                      lastMsgTime = DateTime.tryParse(created);
                  }
              }
              
              final newConv = _Conversation(
                id: threadId,
                username: account['username'] ?? '',
                displayName: account['display_name'] ?? account['username'] ?? '',
                avatarUrl: account['avatar'] ?? '',
                lastMessage: lastMsgContent,
                lastMessageTime: lastMsgTime ?? DateTime(2000),
                unread: convMap['unread'] ?? false,
                lastStatusId: lastStatus?['id']?.toString(),
                userId: partnerId,
              );
              
              if (!convByPartner.containsKey(partnerId) || 
                  newConv.lastMessageTime.isAfter(convByPartner[partnerId]!.lastMessageTime)) {
                convByPartner[partnerId] = newConv;
              }
           }
        } catch (e, stack) {
           appLogger.error('Error parsing conversation item', e);
           _lastParseError = 'Item Error: $e\nStack: $stack';
        }
      }
      
      final sortedConversations = convByPartner.values.toList()
        ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      setState(() {
        _conversations.clear();
        _conversations.addAll(sortedConversations);
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      appLogger.error('Error loading DMs', error, stackTrace);
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading DMs: $error'), backgroundColor: CyberpunkTheme.cardDark),
      );
    }
  }

  String? _lastParseError;

  Future<void> _showDebugInfo() async {
    try {
      final res1 = await widget.apiService.debugFetch('/api/v1/conversations?scope=inbox');
      
      String info = '--- /api/v1/conversations?scope=inbox ---\n';
      info += 'Status: ${res1['statusCode']}\n';
      info += 'URL: ${res1['url']}\n';
      if (res1['error'] != null) info += 'Error: ${res1['error']}\n';
      final body1 = res1['body'].toString();
      info += 'Body: ${body1.substring(0, body1.length > 200 ? 200 : body1.length)}\n\n';
      
      if (_lastParseError != null) {
          info += '--- PARSING ERROR ---\n$_lastParseError\n\n';
      } else {
          info += '--- PARSING ---\nNo specific parsing error recorded.\nlist count: ${_conversations.length}\n';
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: CyberpunkTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Debug Info', style: TextStyle(color: CyberpunkTheme.textWhite)),
          content: SingleChildScrollView(child: Text(info, style: const TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 12))),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: CyberpunkTheme.neonCyan)))],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: CyberpunkTheme.cardDark,
          title: const Text('Error', style: TextStyle(color: CyberpunkTheme.textWhite)),
          content: Text(e.toString(), style: const TextStyle(color: CyberpunkTheme.textSecondary)),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: CyberpunkTheme.neonCyan)))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: CyberpunkTheme.backgroundBlack,
        elevation: 0,
        title: Text(
           S.of(context).messages,
           style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: CyberpunkTheme.textWhite),
         ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_outlined, color: CyberpunkTheme.textTertiary, size: 20),
            onPressed: _showDebugInfo,
          ),
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: CyberpunkTheme.textWhite, size: 24),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => NewMessagePage(apiService: widget.apiService),
              ));
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: CyberpunkTheme.borderDark),
        ),
      ),
      body: RefreshIndicator(
        color: CyberpunkTheme.neonCyan,
        backgroundColor: CyberpunkTheme.cardDark,
        onRefresh: _loadConversations,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: InstagramLoadingIndicator(size: 28));
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: CyberpunkTheme.neonCyan.withOpacity(0.3)),
            const SizedBox(height: 16),
             Text(
               S.of(context).noConversations,
               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CyberpunkTheme.textWhite),
             ),
             const SizedBox(height: 8),
             Text(
               S.of(context).sendMessage,
               style: const TextStyle(fontSize: 14, color: CyberpunkTheme.textSecondary),
             ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => NewMessagePage(apiService: widget.apiService),
                ));
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: CyberpunkTheme.neonCyan,
                side: BorderSide(color: CyberpunkTheme.neonCyan.withOpacity(0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
               child: Text(S.of(context).sendMessage, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _conversations.length,
      separatorBuilder: (context, index) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 0.5,
        color: CyberpunkTheme.borderDark,
      ),
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        return _ConversationItem(
          conversation: conversation,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => ConversationDetailPage(
                apiService: widget.apiService,
                threadId: conversation.id,
                conversationId: conversation.username,
                recipientName: conversation.displayName,
                recipientUsername: conversation.username,
                recipientAvatar: conversation.avatarUrl.isNotEmpty ? conversation.avatarUrl : null,
                lastStatusId: conversation.lastStatusId,
                recipientId: conversation.userId,
              ),
            ));
          },
        );
      },
    );
  }
}

class _Conversation {
  final String id;
  final String username;
  final String displayName;
  final String avatarUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool unread;
  final String? lastStatusId;
  final String userId;

  _Conversation({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unread = false,
    this.lastStatusId,
    required this.userId,
  });
}

class _ConversationItem extends StatelessWidget {
  final _Conversation conversation;
  final VoidCallback onTap;

  const _ConversationItem({
    Key? key,
    required this.conversation,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: CyberpunkTheme.neonCyan.withOpacity(0.03),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar with unread indicator
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: conversation.unread 
                          ? CyberpunkTheme.neonCyan.withOpacity(0.5) 
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: CyberpunkTheme.cardDark,
                      backgroundImage: conversation.avatarUrl.isNotEmpty
                          ? CachedNetworkImageProvider(conversation.avatarUrl)
                          : null,
                      child: conversation.avatarUrl.isEmpty
                          ? const Icon(Icons.person, size: 24, color: CyberpunkTheme.textTertiary)
                          : null,
                    ),
                  ),
                ),
                if (conversation.unread)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: CyberpunkTheme.neonCyan,
                        shape: BoxShape.circle,
                        border: Border.all(color: CyberpunkTheme.backgroundBlack, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.displayName.isNotEmpty ? conversation.displayName : conversation.username,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: conversation.unread ? FontWeight.w600 : FontWeight.w500,
                      color: CyberpunkTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conversation.lastMessage.isNotEmpty ? conversation.lastMessage : 'No messages',
                    style: TextStyle(
                      fontSize: 13,
                      color: conversation.unread ? CyberpunkTheme.textWhite : CyberpunkTheme.textSecondary,
                      fontWeight: conversation.unread ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Time
            Text(
              timeago.format(conversation.lastMessageTime, locale: 'en_short'),
              style: const TextStyle(fontSize: 12, color: CyberpunkTheme.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
