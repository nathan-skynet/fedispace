import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Instagram-style direct messages page
class DirectMessagesPage extends StatefulWidget {
  final ApiService apiService;

  const DirectMessagesPage({Key? key, required this.apiService})
      : super(key: key);

  @override
  State<DirectMessagesPage> createState() => _DirectMessagesPageState();
}

class _DirectMessagesPageState extends State<DirectMessagesPage> {
  // Placeholder for conversations
  final List<_Conversation> _conversations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      appLogger.debug('Loading direct messages');
      // TODO: Implement DM API when available
      // For now, show empty state
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      appLogger.error('Error loading DMs', error, stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // TODO: New message
              appLogger.debug('New message tapped');
            },
          ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: InstagramLoadingIndicator(size: 32));
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_outlined,
              size: 80,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            const SizedBox(height: 16),
            Text(
              'Send Direct Messages',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Text(
                'Share photos and messages with friends privately',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: New message
                appLogger.debug('Send message tapped');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0095F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Send Message',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _conversations.length,
      separatorBuilder: (context, index) => const InstagramDivider(),
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        return _ConversationItem(
          conversation: conversation,
          isDark: isDark,
          onTap: () {
            // TODO: Open conversation
            appLogger.debug('Conversation tapped: ${conversation.username}');
          },
        );
      },
    );
  }
}

// Placeholder conversation model
class _Conversation {
  final String username;
  final String displayName;
  final String avatarUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool unread;

  _Conversation({
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unread = false,
  });
}

class _ConversationItem extends StatelessWidget {
  final _Conversation conversation;
  final bool isDark;
  final VoidCallback onTap;

  const _ConversationItem({
    Key? key,
    required this.conversation,
    required this.isDark,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: conversation.avatarUrl.isNotEmpty
                ? CachedNetworkImageProvider(conversation.avatarUrl)
                : null,
            child: conversation.avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 28)
                : null,
          ),
          if (conversation.unread)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF0095F6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.black : Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        conversation.username,
        style: TextStyle(
          fontSize: 14,
          fontWeight: conversation.unread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        conversation.lastMessage,
        style: TextStyle(
          fontSize: 14,
          fontWeight: conversation.unread ? FontWeight.w600 : FontWeight.normal,
          color: conversation.unread
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? const Color(0xFFA8A8A8) : const Color(0xFF8E8E8E)),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        timeago.format(conversation.lastMessageTime, locale: 'en_short'),
        style: TextStyle(
          fontSize: 12,
          color: isDark ? const Color(0xFFA8A8A8) : const Color(0xFF8E8E8E),
        ),
      ),
      onTap: onTap,
    );
  }
}
