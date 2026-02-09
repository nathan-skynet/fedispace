import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:fedispace/utils/social_actions.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import 'package:fedispace/widgets/simple_video_player.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modern post card with cyberpunk accents
class InstagramPostCard extends StatefulWidget {
  final Status status;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;
  final VoidCallback? onProfileTap;

  const InstagramPostCard({
    Key? key,
    required this.status,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onBookmark,
    this.onProfileTap,
  }) : super(key: key);

  @override
  State<InstagramPostCard> createState() => _InstagramPostCardState();
}

class _InstagramPostCardState extends State<InstagramPostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;

  
  late bool _isFavorited;
  late int _favouritesCount;
  late bool _isBookmarked;

  // Translation state
  String? _translatedContent;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.status.favorited;
    _favouritesCount = widget.status.favourites_count;
    _isBookmarked = widget.status.reblogged;

    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.easeOut,
      ),
    );

  }
  
  @override
  void didUpdateWidget(InstagramPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
       _isFavorited = widget.status.favorited;
       _favouritesCount = widget.status.favourites_count;
       _isBookmarked = widget.status.reblogged;
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (!_isFavorited) {
      _likeAnimationController.forward(from: 0.0);
      widget.onLike?.call();
      setState(() {
         _isFavorited = true;
         _favouritesCount++;
      });
    }
  }

  void _handleTap() {
    Navigator.pushNamed(
      context,
      '/statusDetail',
      arguments: {
        'statusId': widget.status.id,
      },
    );
  }

  Future<void> _translateContent() async {
    if (_isTranslating) return;
    
    // Toggle off if already translated
    if (_translatedContent != null) {
      setState(() => _translatedContent = null);
      return;
    }

    setState(() => _isTranslating = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final provider = prefs.getString('translate_provider') ?? 'libretranslate';
      final targetLang = prefs.getString('translate_target_lang') ?? 'en';

      // Strip HTML tags for translation
      final plainText = widget.status.content
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .trim();

      if (plainText.isEmpty) {
        setState(() => _isTranslating = false);
        return;
      }

      String? translated;

      if (provider == 'openai') {
        // ── OpenAI translation ──
        final endpoint = prefs.getString('openai_translate_endpoint') ?? 'https://api.openai.com/v1/chat/completions';
        // SECURITY: Read API keys from encrypted secure storage
        const secureStorage = FlutterSecureStorage();
        final apiKey = await secureStorage.read(key: 'openai_translate_api_key') ?? '';
        if (apiKey.isEmpty) {
          setState(() => _isTranslating = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('OpenAI API key not set. Go to Settings → Translation.'), backgroundColor: Colors.red.shade800, behavior: SnackBarBehavior.floating),
            );
          }
          return;
        }

        // Map lang code to full name for better LLM understanding
        const langNames = {
          'en': 'English', 'fr': 'French', 'es': 'Spanish', 'de': 'German',
          'it': 'Italian', 'pt': 'Portuguese', 'nl': 'Dutch', 'ru': 'Russian',
          'zh': 'Chinese', 'ja': 'Japanese', 'ko': 'Korean', 'ar': 'Arabic',
          'hi': 'Hindi', 'tr': 'Turkish', 'pl': 'Polish', 'sv': 'Swedish',
          'da': 'Danish', 'fi': 'Finnish', 'no': 'Norwegian', 'uk': 'Ukrainian',
        };
        final langName = langNames[targetLang] ?? targetLang;

        final response = await http.post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': 'gpt-4o-mini',
            'messages': [
              {'role': 'system', 'content': 'You are a translator. Translate the following text to $langName. Return ONLY the translated text, nothing else.'},
              {'role': 'user', 'content': plainText},
            ],
            'max_tokens': 1000,
            'temperature': 0.3,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          translated = data['choices']?[0]?['message']?['content']?.toString().trim();
        } else {
          String errMsg = 'OpenAI translation failed (${response.statusCode})';
          try {
            final errData = jsonDecode(response.body);
            errMsg = errData['error']?['message'] ?? errMsg;
          } catch (_) {}
          throw Exception(errMsg);
        }
      } else {
        // ── LibreTranslate ──
        final baseUrl = prefs.getString('libretranslate_url') ?? 'https://libretranslate.com';
        // SECURITY: Read API keys from encrypted secure storage
        const secureStorage = FlutterSecureStorage();
        final apiKey = await secureStorage.read(key: 'libretranslate_api_key') ?? '';

        final body = <String, dynamic>{
          'q': plainText,
          'source': 'auto',
          'target': targetLang,
          'format': 'text',
        };
        if (apiKey.isNotEmpty) {
          body['api_key'] = apiKey;
        }

        final response = await http.post(
          Uri.parse('$baseUrl/translate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          translated = data['translatedText'];
        } else {
          String errMsg = 'LibreTranslate failed (${response.statusCode})';
          try {
            final errData = jsonDecode(response.body);
            errMsg = errData['error'] ?? errMsg;
          } catch (_) {}
          throw Exception(errMsg);
        }
      }

      setState(() {
        _translatedContent = translated ?? 'Translation failed';
        _isTranslating = false;
      });
    } catch (e) {
      setState(() => _isTranslating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Translation error: $e'), backgroundColor: Colors.red.shade800, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CyberpunkTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: CyberpunkTheme.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _sheetTile(Icons.share_outlined, 'Share', () {
              Navigator.pop(ctx);
              SocialActions.shareStatus(widget.status);
            }),
            _sheetTile(Icons.open_in_browser_rounded, S.of(context).openInBrowser, () {
              Navigator.pop(ctx);
              final url = widget.status.url;
              if (url.isNotEmpty) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            }),
            _sheetTile(Icons.link_rounded, S.of(context).copyLink, () {
              Navigator.pop(ctx);
              final url = widget.status.url;
              if (url.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(S.of(context).linkCopied),
                    backgroundColor: CyberpunkTheme.cardDark,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sheetTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: CyberpunkTheme.textWhite, size: 22),
      title: Text(label, style: const TextStyle(color: CyberpunkTheme.textWhite, fontSize: 15)),
      onTap: onTap,
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      color: CyberpunkTheme.backgroundBlack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          if (widget.status.hasMediaAttachments) _buildMedia(context),
          _buildActions(context),
          if (_favouritesCount > 0) _buildLikesCount(context),
          _buildCaption(context),
          if (widget.status.replies_count > 0) _buildViewComments(context),
          _buildTimeAgo(context),
          const SizedBox(height: 8),
          Container(height: 0.5, color: CyberpunkTheme.borderDark),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onProfileTap,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: CyberpunkTheme.neonCyan.withOpacity(0.3), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: CyberpunkTheme.cardDark,
                  backgroundImage: widget.status.avatar.isNotEmpty
                      ? CachedNetworkImageProvider(widget.status.avatar)
                      : null,
                  child: widget.status.avatar.isEmpty
                      ? const Icon(Icons.person, size: 16, color: CyberpunkTheme.textTertiary)
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: widget.onProfileTap,
              child: Text(
                widget.status.acct,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CyberpunkTheme.textWhite,
                ),
              ),
            ),
          ),
          GestureDetector(
          onTap: () => _showMoreSheet(context),
          child: const Icon(Icons.more_horiz_rounded, size: 20, color: CyberpunkTheme.textSecondary),
        ),
        ],
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    final firstMedia = widget.status.getFirstMedia();
    final isVideoType = firstMedia != null && (firstMedia['type'] == 'video' || firstMedia['type'] == 'gifv');
    final isVideoExtension = widget.status.attach.toLowerCase().contains('.mp4') || widget.status.attach.toLowerCase().contains('.mov');
    final isVideo = isVideoType || isVideoExtension;

    if (isVideo) {
      return SizedBox(
        width: double.infinity,
        height: 400,
        child: SimpleVideoPlayer(url: widget.status.attach),
      );
    }

    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      onTap: _handleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: CachedNetworkImage(
              imageUrl: widget.status.attach,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: CyberpunkTheme.cardDark,
                child: const Center(child: InstagramLoadingIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: CyberpunkTheme.cardDark,
                child: const Icon(Icons.broken_image_outlined, color: CyberpunkTheme.textTertiary, size: 32),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _likeAnimation,
            builder: (context, child) {
              return _likeAnimation.value > 0
                  ? Opacity(
                      opacity: 1.0 - _likeAnimation.value,
                      child: Transform.scale(
                        scale: 0.5 + (_likeAnimation.value * 1.5),
                        child: Icon(
                          Icons.favorite,
                          color: CyberpunkTheme.neonPink.withOpacity(0.9),
                          size: 100,
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          _ActionIcon(
            icon: _isFavorited ? Icons.favorite : Icons.favorite_border_rounded,
            color: _isFavorited ? CyberpunkTheme.neonPink : CyberpunkTheme.textWhite,
            onTap: () {
              widget.onLike?.call();
              setState(() {
                _isFavorited = !_isFavorited;
                if (_isFavorited) {
                  _favouritesCount++;
                  _likeAnimationController.forward(from: 0.0);
                } else {
                  _favouritesCount--;
                }
              });
            },
          ),
          const SizedBox(width: 14),
          _ActionIcon(
            icon: Icons.mode_comment_outlined,
            onTap: () => widget.onComment?.call(),
          ),
          const SizedBox(width: 14),
          _ActionIcon(
            icon: Icons.send_outlined,
            onTap: () => widget.onShare?.call(),
          ),
          const Spacer(),
          _ActionIcon(
            icon: _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: _isBookmarked ? CyberpunkTheme.neonCyan : null,
            onTap: () {
              widget.onBookmark?.call();
              setState(() {
                _isBookmarked = !_isBookmarked;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLikesCount(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Text(
        '$_favouritesCount ${_favouritesCount == 1 ? S.of(context).like : S.of(context).likes}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: CyberpunkTheme.textWhite,
        ),
      ),
    );
  }

  Widget _buildCaption(BuildContext context) {
    if (widget.status.content.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
             widget.status.acct,
             style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: CyberpunkTheme.textWhite),
           ),
           Html(
             data: widget.status.content,
             style: {
               "body": Style(
                 margin: Margins.zero,
                 padding: HtmlPaddings.zero,
                 fontSize: FontSize(14),
                 color: CyberpunkTheme.textWhite,
                 lineHeight: LineHeight(1.4),
               ),
               "a": Style(
                 color: CyberpunkTheme.neonCyan,
                 textDecoration: TextDecoration.none,
                 fontWeight: FontWeight.w500,
               ),
             },
             onLinkTap: (url, attributes, element) async {
                if (url == null) return;
                
                if (url.contains('/tags/')) {
                  try {
                    final uri = Uri.parse(url);
                    final segments = uri.pathSegments;
                    final tagIndex = segments.indexOf('tags');
                    if (tagIndex != -1 && tagIndex + 1 < segments.length) {
                      final tag = segments[tagIndex + 1];
                      Navigator.pushNamed(context, '/TagTimeline', arguments: {'tag': tag});
                      return;
                    }
                  } catch (e) {
                    // ignore
                  }
                }
                
                try {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  // ignore
                }
             },
           ),
           // Translated content
           if (_translatedContent != null)
             Container(
               margin: const EdgeInsets.only(top: 6),
               padding: const EdgeInsets.all(10),
               decoration: BoxDecoration(
                 color: CyberpunkTheme.neonCyan.withOpacity(0.06),
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: CyberpunkTheme.neonCyan.withOpacity(0.15)),
               ),
               child: Text(
                 _translatedContent!,
                 style: const TextStyle(color: CyberpunkTheme.textWhite, fontSize: 14, height: 1.4),
               ),
             ),
           // Translate button
           GestureDetector(
             onTap: _translateContent,
             child: Padding(
               padding: const EdgeInsets.only(top: 4),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   if (_isTranslating)
                     const SizedBox(
                       width: 12, height: 12,
                       child: CircularProgressIndicator(strokeWidth: 1.5, color: CyberpunkTheme.neonCyan),
                     )
                   else
                     Icon(
                       _translatedContent != null ? Icons.undo_rounded : Icons.translate_rounded,
                       size: 14,
                       color: CyberpunkTheme.neonCyan.withOpacity(0.7),
                     ),
                   const SizedBox(width: 4),
                   Text(
                     _translatedContent != null ? S.of(context).showOriginal : S.of(context).translate,
                     style: TextStyle(
                       color: CyberpunkTheme.neonCyan.withOpacity(0.7),
                       fontSize: 13,
                       fontWeight: FontWeight.w500,
                     ),
                   ),
                 ],
               ),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildViewComments(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: GestureDetector(
        onTap: widget.onComment,
        child: Text(
          '${S.of(context).viewAllComments} (${widget.status.replies_count})',
          style: const TextStyle(fontSize: 14, color: CyberpunkTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildTimeAgo(BuildContext context) {
    DateTime? createdAt;
    try {
      if (widget.status.created_at.isNotEmpty) {
        createdAt = DateTime.parse(widget.status.created_at);
      }
    } catch (_) {}

    if (createdAt == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Text(
        timeago.format(createdAt, locale: 'en_short'),
        style: const TextStyle(fontSize: 12, color: CyberpunkTheme.textTertiary),
      ),
    );
  }
}

/// Small action icon with consistent sizing
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _ActionIcon({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 24, color: color ?? CyberpunkTheme.textWhite),
      ),
    );
  }
}
