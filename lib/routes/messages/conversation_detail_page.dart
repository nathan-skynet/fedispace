import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:timeago/timeago.dart' as timeago;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:image_picker/image_picker.dart';

/// Direct Messages conversation detail page
class ConversationDetailPage extends StatefulWidget {
  final ApiService apiService;
  final String conversationId;
  final String recipientName;
  final String recipientUsername;
  final String? recipientAvatar;
  final String? lastStatusId;
  final String recipientId;
  final String? threadId; // New: Conversation ID for fetching history

  const ConversationDetailPage({
    Key? key,
    required this.apiService,
    required this.conversationId,
    required this.recipientName,
    required this.recipientUsername,
    this.recipientAvatar,
    this.lastStatusId,
    required this.recipientId,
    this.threadId, // Optional because deep links/direct navigation might not have it yet
  }) : super(key: key);

  @override
  State<ConversationDetailPage> createState() => _ConversationDetailPageState();
}

class _ConversationDetailPageState extends State<ConversationDetailPage> {
  final List<_Message> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = true;
  bool _isSending = false;
  bool _isMuted = false;
  Timer? _refreshTimer;
  final Set<String> _knownMessageIds = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // Mark conversation as read on open
    if (widget.threadId != null) {
      widget.apiService.markConversationRead(widget.threadId!);
    }
    // Auto-refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshMessages();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  /// Refresh messages without showing loading spinner
  Future<void> _refreshMessages() async {
    if (_isLoading || !mounted) return;
    await _loadMessages(showLoading: false, detectNew: true);
  }

  /// Extract media attachment URLs from a message/status object
  List<String> _extractMediaUrls(Map<String, dynamic> data) {
    final List<String> urls = [];
    try {
      // Log available keys for debugging
      appLogger.debug('_extractMediaUrls keys: ${data.keys.toList()}');
      
      final attachments = data['media_attachments'];
      if (attachments is List) {
        appLogger.debug('Found ${attachments.length} media_attachments');
        for (var att in attachments) {
          if (att is Map) {
            appLogger.debug('Attachment keys: ${att.keys.toList()}, type: ${att['type']}');
            final url = att['url'] ?? att['preview_url'] ?? att['remote_url'];
            if (url != null && url.toString().isNotEmpty) {
              appLogger.debug('Found media URL: $url');
              urls.add(url.toString());
            }
          }
        }
      } else {
        appLogger.debug('No media_attachments found (value: $attachments)');
      }
      
      // Fallback: check for 'attachments' key (some Pixelfed versions use this)
      final altAttachments = data['attachments'];
      if (altAttachments is List && urls.isEmpty) {
        appLogger.debug('Checking fallback \'attachments\' key: ${altAttachments.length} items');
        for (var att in altAttachments) {
          if (att is Map) {
            final url = att['url'] ?? att['preview_url'] ?? att['remote_url'];
            if (url != null && url.toString().isNotEmpty) {
              urls.add(url.toString());
            }
          }
        }
      }
    } catch (e) {
      appLogger.error('Error extracting media URLs', e);
    }
    return urls;
  }

  Future<void> _loadMessages({bool showLoading = true, bool detectNew = false}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      appLogger.debug('Loading messages for partner: ${widget.recipientId} (${widget.recipientUsername})');
      
      // Try Pixelfed-specific thread endpoint first (full history)
      List<dynamic> threadData = await widget.apiService.getDirectThread(widget.recipientId);
      
      appLogger.debug('getDirectThread returned ${threadData.length} items');
      
      final List<_Message> loadedMessages = [];
      
       if (threadData.isNotEmpty) {
        appLogger.debug('Parsing ${threadData.length} thread items');
        // Parse the thread data - could be messages, status objects, or conversation objects
        for (var item in threadData) {
          try {
            if (item is! Map) continue;
            var data = Map<String, dynamic>.from(item);
            
            appLogger.debug('Thread item keys: ${data.keys.toList()}');
            
            // If this is a conversation wrapper, unwrap to get the actual status
            if (data.containsKey('last_status') && data['last_status'] is Map) {
              appLogger.debug('Unwrapping last_status from conversation wrapper');
              data = Map<String, dynamic>.from(data['last_status']);
              appLogger.debug('Unwrapped status keys: ${data.keys.toList()}');
            }
            
            // Try to detect format: chat message vs status object
            String content = '';
            bool isMe = false;
            DateTime timestamp = DateTime.now();
            String id = data['id']?.toString() ?? '';
            List<String> mediaUrls = _extractMediaUrls(data);
            
            appLogger.debug('Message $id: found ${mediaUrls.length} media URLs');
            
            if (data.containsKey('text') || data.containsKey('body') || data.containsKey('message')) {
              // Chat message format: {id, body/text/message, created_at, is_author, type, ...}
              content = data['text'] ?? data['body'] ?? data['message'] ?? '';
              isMe = data['is_author'] == true || data['isAuthor'] == true || data['is_sender'] == true;
              if (data['created_at'] != null) {
                timestamp = DateTime.tryParse(data['created_at']) ?? DateTime.now();
              }
            } else if (data.containsKey('content') || mediaUrls.isNotEmpty) {
              // Status object format: {id, content, account, created_at, media_attachments, ...}
              content = data['content_text'] ?? data['content']?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '';
              final account = data['account'];
              if (account != null) {
                isMe = account['id']?.toString() != widget.recipientId;
              }
              if (data['created_at'] != null) {
                timestamp = DateTime.tryParse(data['created_at']) ?? DateTime.now();
              }
            }
            
            if (content.isNotEmpty || mediaUrls.isNotEmpty) {
              loadedMessages.add(_Message(
                id: id,
                content: content,
                timestamp: timestamp,
                isFromMe: isMe,
                mediaUrls: mediaUrls,
              ));
            }
          } catch (e) {
            appLogger.error('Error parsing thread message', e);
          }
        }
      }
      
      // If thread endpoint returned nothing useful, fallback to merged inbox/sent
      if (loadedMessages.isEmpty) {
        appLogger.debug('Thread endpoint empty, falling back to merged inbox/sent');
        final mergedMessages = await widget.apiService.getAllConversationMessages(widget.recipientId);
        
        for (var msgData in mergedMessages) {
          try {
            final String content = msgData['content_text'] ?? 
                msgData['content']?.replaceAll(RegExp(r'<[^>]*>'), '') ?? 
                msgData['body'] ?? '';
            
            List<String> mediaUrls = _extractMediaUrls(msgData);
            
            bool isMe = false;
            if (msgData['_direction'] == 'sent') {
              final account = msgData['account'];
              isMe = account != null ? account['id']?.toString() != widget.recipientId : true;
            } else {
              final account = msgData['account'];
              if (account != null) {
                isMe = account['id']?.toString() != widget.recipientId;
              }
            }
            
            final DateTime timestamp = msgData['created_at'] != null 
                ? DateTime.tryParse(msgData['created_at']) ?? DateTime.now()
                : DateTime.now();
            
            if (content.isNotEmpty || mediaUrls.isNotEmpty) {
              loadedMessages.add(_Message(
                id: msgData['id']?.toString() ?? '',
                content: content,
                timestamp: timestamp,
                isFromMe: isMe,
                mediaUrls: mediaUrls,
              ));
            }
          } catch (e) {
            appLogger.error('Error parsing message item', e);
          }
        }
      }
      
      // Sort newest first (for reverse ListView)
      loadedMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Detect new messages from the other person
      if (detectNew && _knownMessageIds.isNotEmpty) {
        for (var msg in loadedMessages) {
          if (!msg.isFromMe && !_knownMessageIds.contains(msg.id)) {
            msg.isNew = true;
            // Send notification
            _sendNewMessageNotification(msg);
          }
        }
      }
      
      // Track all known message IDs
      _knownMessageIds.clear();
      for (var msg in loadedMessages) {
        _knownMessageIds.add(msg.id);
      }
      
      setState(() {
          _messages.clear();
          _messages.addAll(loadedMessages);
          _isLoading = false;
      });
      
      // Clear highlight after 3 seconds
      if (detectNew) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              for (var msg in _messages) {
                msg.isNew = false;
              }
            });
          }
        });
      }

    } catch (error, stackTrace) {
      appLogger.error('Error loading messages', error, stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Send a local notification for a new message
  void _sendNewMessageNotification(_Message msg) {
    try {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          channelKey: 'mention', // Reuse existing channel
          title: 'New message from ${widget.recipientName}',
          body: msg.content.length > 100 ? '${msg.content.substring(0, 100)}...' : msg.content,
          bigPicture: widget.recipientAvatar,
          notificationLayout: widget.recipientAvatar != null ? NotificationLayout.BigPicture : NotificationLayout.Default,
          category: NotificationCategory.Message,
        ),
      );
    } catch (e) {
      appLogger.error('Error sending DM notification', e);
    }
  }

  _Message _parseMessage(Map<String, dynamic> data) {
    // Handle Chat API response (Pixelfed specific)
    // { "id": 123, "body": "Hello", "created_at": "...", "sender_id": 456, "is_sender": true/false, "type": "text|photo|photos", "media": "url" }
    
    if (data.containsKey('body') || data.containsKey('message')) {
        final String msgType = (data['type'] ?? 'text').toString();
        String content = data['body'] ?? data['message'] ?? data['text'] ?? '';
        final bool isMe = data['is_sender'] == true || 
            data['isAuthor'] == true ||
            (data['sender_id'] != null && data['sender_id'].toString() != widget.recipientId);
        
        // Extract media URLs from photo messages (matching pixelfed-rn behavior)
        List<String> mediaUrls = [];
        if (['photo', 'photos'].contains(msgType)) {
          final media = data['media'];
          if (media is String && media.isNotEmpty) {
            mediaUrls.add(media);
          } else if (media is List) {
            for (var m in media) {
              if (m is String && m.isNotEmpty) mediaUrls.add(m);
              if (m is Map) {
                final url = m['url'] ?? m['preview_url'];
                if (url != null) mediaUrls.add(url.toString());
              }
            }
          }
        }
        
        // Also check media_attachments if present
        if (mediaUrls.isEmpty) {
          mediaUrls.addAll(_extractMediaUrls(data));
        }

        // For story replies/reactions, prefix the content
        if (['story:reply', 'story:comment', 'story:react'].contains(msgType)) {
          content = 'Story reply: "$content"';
        }
         
        return _Message(
          id: data['id']?.toString() ?? '',
          content: content,
          timestamp: data['created_at'] != null ? DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
          isFromMe: isMe,
          mediaUrls: mediaUrls,
        );
    }

    // Fallback for Status objects (if any)
    final account = data['account'];
    final String content = data['content']?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '';
    final DateTime timestamp = data['created_at'] != null 
        ? DateTime.parse(data['created_at']) 
        : DateTime.now();
    
    bool isMe = false;
    if (account != null) {
      if (account['username'] != widget.recipientUsername) {
         isMe = true;
      }
    }
    
    return _Message(
      id: data['id'] ?? '',
      content: content,
      timestamp: timestamp,
      isFromMe: isMe,
      mediaUrls: _extractMediaUrls(data),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    // Debug feedback removed

    try {
      appLogger.debug('Sending message: $text');
      // Use new Chat API
      final result = await widget.apiService.sendChatDirectMessage(
        recipientId: widget.recipientId,
        content: text,
      );
      
      if (result != null) {
        final sentText = _messageController.text.trim();
        _messageController.clear();
        
        // Check for API error
        if (result is Map<String, dynamic> && result.containsKey('error')) {
          appLogger.error('API Error: ${result['error']}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${result['error']}'), backgroundColor: Colors.red),
            );
          }
        } else {
          // Add message locally for instant feedback
          setState(() {
            _messages.insert(0, _Message(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content: sentText,
              timestamp: DateTime.now(),
              isFromMe: true,
            ));
          });
        }
        
        // Optionally reload to sync
        // _loadMessages(); 
      }
      
      setState(() {
        _isSending = false;
      });
    } catch (error, stackTrace) {
      appLogger.error('Error sending message', error, stackTrace);
      setState(() {
        _isSending = false;
      });
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Send failed: $error'),
              backgroundColor: Colors.red,
            ),
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
        title: Row(
          children: [
            if (widget.recipientAvatar != null)
              CircleAvatar(
                radius: 16,
                backgroundColor: CyberpunkTheme.cardDark,
                backgroundImage: CachedNetworkImageProvider(widget.recipientAvatar!),
              )
            else
              const CircleAvatar(
                radius: 16,
                backgroundColor: CyberpunkTheme.cardDark,
                child: Icon(Icons.person, size: 16, color: CyberpunkTheme.textTertiary),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.recipientName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CyberpunkTheme.textWhite),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${widget.recipientUsername}',
                    style: const TextStyle(fontSize: 12, color: CyberpunkTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isMuted ? Icons.notifications_off_outlined : Icons.notifications_outlined,
              size: 22,
              color: _isMuted ? CyberpunkTheme.neonPink : CyberpunkTheme.textSecondary,
            ),
            tooltip: _isMuted ? 'Unmute' : 'Mute',
            onPressed: () async {
              if (widget.threadId == null) return;
              final ok = _isMuted
                  ? await widget.apiService.unmuteConversation(widget.threadId!)
                  : await widget.apiService.muteConversation(widget.threadId!);
              if (ok && mounted) setState(() => _isMuted = !_isMuted);
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 22, color: CyberpunkTheme.textSecondary),
            onPressed: () {
              Navigator.pushNamed(context, '/UserProfile', arguments: {'userId': widget.recipientId});
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: CyberpunkTheme.borderDark),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: InstagramLoadingIndicator(size: 28))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.waving_hand_outlined, size: 56, color: CyberpunkTheme.neonCyan.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(
                              'Say hi to ${widget.recipientName}!',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CyberpunkTheme.textWhite),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: CyberpunkTheme.neonCyan,
                        backgroundColor: CyberpunkTheme.cardDark,
                        onRefresh: _refreshMessages,
                        child: ListView.builder(
                          reverse: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return GestureDetector(
                              onLongPress: message.isFromMe ? () => _showDeleteDialog(message) : null,
                              child: _MessageBubble(message: message),
                            );
                          },
                        ),
                      ),
          ),
          Container(height: 0.5, color: CyberpunkTheme.borderDark),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      color: CyberpunkTheme.backgroundBlack,
      child: SafeArea(
        child: Row(
          children: [
            // Photo attach button
            IconButton(
              icon: Icon(
                Icons.photo_camera_rounded,
                color: CyberpunkTheme.neonCyan.withOpacity(0.7),
                size: 22,
              ),
              onPressed: _pickAndSendMedia,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: CyberpunkTheme.textWhite, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: const TextStyle(color: CyberpunkTheme.textTertiary),
                  filled: true,
                  fillColor: CyberpunkTheme.cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(color: CyberpunkTheme.borderDark),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(color: CyberpunkTheme.neonCyan.withOpacity(0.4)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onChanged: (value) => setState(() {}),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.send_rounded,
                color: _messageController.text.trim().isEmpty
                    ? CyberpunkTheme.textTertiary
                    : CyberpunkTheme.neonCyan,
              ),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendMedia() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final result = await widget.apiService.uploadDirectMessageMedia(image.path);
      if (result != null) {
        appLogger.debug('DM media uploaded: $result');
        // The upload usually triggers a message in the thread, so refresh
        await _refreshMessages();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send photo'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e, s) {
      appLogger.error('Error picking/sending media', e, s);
    }
  }

  void _showDeleteDialog(_Message message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: CyberpunkTheme.borderDark),
        ),
        title: Text(S.of(context).deleteMessage, style: const TextStyle(color: CyberpunkTheme.textWhite, fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('This action cannot be undone.', style: TextStyle(color: CyberpunkTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.of(context).cancel, style: const TextStyle(color: CyberpunkTheme.textTertiary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await widget.apiService.deleteDirectMessage(message.id);
              if (ok) {
                setState(() => _messages.removeWhere((m) => m.id == message.id));
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: CyberpunkTheme.neonPink.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(S.of(context).delete, style: const TextStyle(color: CyberpunkTheme.neonPink, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// Placeholder message model
class _Message {
  final String id;
  final String content;
  final DateTime timestamp;
  final bool isFromMe;
  final List<String> mediaUrls;
  bool isNew;

  _Message({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.isFromMe,
    this.mediaUrls = const [],
    this.isNew = false,
  });
}

class _MessageBubble extends StatelessWidget {
  final _Message message;

  const _MessageBubble({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bubbleColor = message.isFromMe
        ? CyberpunkTheme.neonCyan.withOpacity(0.15)
        : CyberpunkTheme.cardDark;
    
    final hasMedia = message.mediaUrls.isNotEmpty;
    final hasText = message.content.isNotEmpty;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            message.isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: hasMedia && !hasText ? Colors.transparent : bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(message.isFromMe ? 18 : 4),
                bottomRight: Radius.circular(message.isFromMe ? 4 : 18),
              ),
              border: message.isFromMe
                  ? Border.all(color: CyberpunkTheme.neonCyan.withOpacity(0.2), width: 0.5)
                  : Border.all(color: CyberpunkTheme.borderDark, width: 0.5),
              boxShadow: message.isNew
                  ? [
                      BoxShadow(
                        color: CyberpunkTheme.neonCyan.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasMedia)
                  ...message.mediaUrls.map((url) => ClipRRect(
                    borderRadius: hasText 
                        ? const BorderRadius.vertical(top: Radius.circular(18))
                        : BorderRadius.circular(18),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 150,
                        color: CyberpunkTheme.cardDark,
                        child: const Center(child: InstagramLoadingIndicator(size: 16)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 80,
                        color: CyberpunkTheme.cardDark,
                        child: const Icon(Icons.broken_image_outlined, size: 24, color: CyberpunkTheme.textTertiary),
                      ),
                    ),
                  )),
                if (hasText)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Text(
                      message.content,
                      style: const TextStyle(
                        color: CyberpunkTheme.textWhite,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
