import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/main.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fedispace/routes/settings/domain_blocks_page.dart';
import 'package:fedispace/routes/settings/content_filters_page.dart';
import 'package:fedispace/routes/profile/archived_posts_page.dart';
import 'package:fedispace/routes/profile/collections_page.dart';

class SettingsPage extends StatefulWidget {
  final ApiService apiService;

  const SettingsPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _privateAccount = false;

  // App language
  String _appLocaleCode = '';
  // Notification preferences
  bool _notifyMentions = true;
  bool _notifyLikes = true;
  bool _notifyBoosts = true;
  bool _notifyFollows = true;
  bool _notifyDMs = true;
  bool _notifyPolls = true;

  // Translation config
  String _libreTranslateUrl = 'https://libretranslate.com';
  String _libreTranslateApiKey = '';
  String _translateTargetLang = 'en';
  bool _autoTranslateEnabled = false;
  String _translateProvider = 'libretranslate'; // 'openai' | 'libretranslate'
  String _openaiTranslateEndpoint = 'https://api.openai.com/v1/chat/completions';
  String _openaiTranslateApiKey = '';

  static const _languageOptions = {
    'en': 'English',
    'fr': 'Français',
    'es': 'Español',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
    'ja': '日本語',
    'ko': '한국어',
    'zh': '中文',
    'ar': 'العربية',
    'ru': 'Русский',
    'nl': 'Nederlands',
  };

  // AI provider config
  String _defaultAiProvider = 'stability'; // stability | openai | nanobanano
  Map<String, String> _aiKeys = {
    'stability': '',
    'openai': '',
    'nanobanano': '',
  };

  static const _providerLabels = {
    'stability': 'Stability AI',
    'openai': 'ChatGPT / DALL-E',
    'nanobanano': 'Nano Banano Pro',
  };
  static const _providerIcons = {
    'stability': Icons.auto_awesome,
    'openai': Icons.smart_toy_rounded,
    'nanobanano': Icons.blur_on_rounded,
  };
  static const _providerColors = {
    'stability': CyberpunkTheme.neonPink,
    'openai': Color(0xFF10A37F),
    'nanobanano': Color(0xFFFFB800),
  };
  static const _providerSignupUrls = {
    'stability': 'https://platform.stability.ai/account/keys',
    'openai': 'https://platform.openai.com/api-keys',
    'nanobanano': 'https://kie.ai',
  };

  @override
  void initState() {
    super.initState();
    _loadAiConfig();
  }

  static const _secureStorage = FlutterSecureStorage();

  Future<void> _loadAiConfig() async {
    final prefs = await SharedPreferences.getInstance();
    // Load non-sensitive settings from SharedPreferences
    final appLocale = prefs.getString('app_locale') ?? '';
    final privateAccount = prefs.getBool('private_account') ?? false;
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    final notifyMentions = prefs.getBool('notify_mentions') ?? true;
    final notifyLikes = prefs.getBool('notify_likes') ?? true;
    final notifyBoosts = prefs.getBool('notify_boosts') ?? true;
    final notifyFollows = prefs.getBool('notify_follows') ?? true;
    final notifyDMs = prefs.getBool('notify_dms') ?? true;
    final notifyPolls = prefs.getBool('notify_polls') ?? true;
    final libreTranslateUrl = prefs.getString('libretranslate_url') ?? 'https://libretranslate.com';
    final translateTargetLang = prefs.getString('translate_target_lang') ?? 'en';
    final autoTranslateEnabled = prefs.getBool('auto_translate_enabled') ?? false;
    final translateProvider = prefs.getString('translate_provider') ?? 'libretranslate';
    final openaiTranslateEndpoint = prefs.getString('openai_translate_endpoint') ?? 'https://api.openai.com/v1/chat/completions';
    final defaultAiProvider = prefs.getString('ai_provider') ?? 'stability';

    // SECURITY: Load API keys from encrypted secure storage
    final libreTranslateApiKey = await _secureStorage.read(key: 'libretranslate_api_key') ?? '';
    final openaiTranslateApiKey = await _secureStorage.read(key: 'openai_translate_api_key') ?? '';
    final Map<String, String> aiKeys = {};
    for (final p in _aiKeys.keys) {
      aiKeys[p] = await _secureStorage.read(key: '${p}_api_key') ?? '';
    }

    // Migrate keys from SharedPreferences to secure storage (one-time)
    await _migrateApiKeysIfNeeded(prefs);

    setState(() {
      _appLocaleCode = appLocale;
      _privateAccount = privateAccount;
      _notificationsEnabled = notificationsEnabled;
      _notifyMentions = notifyMentions;
      _notifyLikes = notifyLikes;
      _notifyBoosts = notifyBoosts;
      _notifyFollows = notifyFollows;
      _notifyDMs = notifyDMs;
      _notifyPolls = notifyPolls;
      _libreTranslateUrl = libreTranslateUrl;
      _libreTranslateApiKey = libreTranslateApiKey;
      _translateTargetLang = translateTargetLang;
      _autoTranslateEnabled = autoTranslateEnabled;
      _translateProvider = translateProvider;
      _openaiTranslateEndpoint = openaiTranslateEndpoint;
      _openaiTranslateApiKey = openaiTranslateApiKey;
      _defaultAiProvider = defaultAiProvider;
      for (final p in aiKeys.keys) {
        _aiKeys[p] = aiKeys[p] ?? '';
      }
    });
  }

  /// One-time migration of API keys from SharedPreferences to FlutterSecureStorage
  Future<void> _migrateApiKeysIfNeeded(SharedPreferences prefs) async {
    if (prefs.getBool('api_keys_migrated') == true) return;

    final keysToMigrate = [
      'libretranslate_api_key',
      'openai_translate_api_key',
      ...(_aiKeys.keys.map((p) => '${p}_api_key')),
    ];

    for (final key in keysToMigrate) {
      final value = prefs.getString(key);
      if (value != null && value.isNotEmpty) {
        await _secureStorage.write(key: key, value: value);
        await prefs.remove(key); // Remove from insecure storage
      }
    }

    await prefs.setBool('api_keys_migrated', true);
    appLogger.info('API keys migrated to secure storage');
  }

  Future<void> _saveAiKey(String provider, String key) async {
    // SECURITY: Save API keys to encrypted secure storage
    await _secureStorage.write(key: '${provider}_api_key', value: key);
    setState(() => _aiKeys[provider] = key);
  }

  Future<void> _setDefaultProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_default_provider', provider);
    setState(() => _defaultAiProvider = provider);
  }

  void _showApiKeyDialog(String provider) {
    final controller = TextEditingController(text: _aiKeys[provider] ?? '');
    final label = _providerLabels[provider] ?? provider;
    final color = _providerColors[provider] ?? CyberpunkTheme.neonPink;
    final signupUrl = _providerSignupUrls[provider] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_providerIcons[provider] ?? Icons.key, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: CyberpunkTheme.textWhite, fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your $label API key:',
              style: const TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: CyberpunkTheme.textWhite, fontSize: 14, fontFamily: 'monospace'),
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'sk-xxxxxxxxxxxxxxx',
                hintStyle: TextStyle(color: CyberpunkTheme.textTertiary.withOpacity(0.4), fontSize: 13),
                filled: true,
                fillColor: CyberpunkTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: CyberpunkTheme.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: CyberpunkTheme.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: color),
                ),
              ),
            ),
            if (signupUrl.isNotEmpty) ...[            
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => launchUrl(Uri.parse(signupUrl), mode: LaunchMode.externalApplication),
                child: Row(
                  children: [
                    Icon(Icons.open_in_new, size: 14, color: CyberpunkTheme.neonCyan.withOpacity(0.8)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Sign up & get API key',
                        style: TextStyle(
                          fontSize: 13,
                          color: CyberpunkTheme.neonCyan.withOpacity(0.8),
                          decoration: TextDecoration.underline,
                          decorationColor: CyberpunkTheme.neonCyan.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: CyberpunkTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              _saveAiKey(provider, controller.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label key saved'),
                  backgroundColor: CyberpunkTheme.surfaceDark,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showProviderPicker() {
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
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Default AI Provider',
                style: TextStyle(color: CyberpunkTheme.textWhite, fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            ..._providerLabels.entries.map((entry) {
              final id = entry.key;
              final label = entry.value;
              final isSelected = _defaultAiProvider == id;
              final color = _providerColors[id] ?? CyberpunkTheme.neonCyan;
              return ListTile(
                leading: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(isSelected ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected ? Border.all(color: color.withOpacity(0.4)) : null,
                  ),
                  child: Icon(_providerIcons[id], color: color, size: 22),
                ),
                title: Text(label, style: TextStyle(
                  color: isSelected ? CyberpunkTheme.textWhite : CyberpunkTheme.textSecondary,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                )),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded, color: color, size: 22)
                    : null,
                onTap: () {
                  _setDefaultProvider(id);
                  Navigator.pop(ctx);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberpunkTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(color: CyberpunkTheme.textWhite, fontWeight: FontWeight.w600)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: CyberpunkTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: CyberpunkTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: CyberpunkTheme.neonPink, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        appLogger.info('User logging out');
        await widget.apiService.resetApiServiceState();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/Login', (route) => false);
        }
      } catch (error, stackTrace) {
        appLogger.error('Error during logout', error, stackTrace);
      }
    }
  }

  void _showTranslateUrlDialog() {
    final controller = TextEditingController(text: _libreTranslateUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('LibreTranslate Server', style: TextStyle(color: CyberpunkTheme.textWhite, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the URL of your LibreTranslate instance', style: TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: CyberpunkTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'https://libretranslate.com',
                hintStyle: TextStyle(color: CyberpunkTheme.textTertiary),
                filled: true,
                fillColor: CyberpunkTheme.cardDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CyberpunkTheme.neonCyan, width: 1)),
                prefixIcon: const Icon(Icons.link_rounded, color: CyberpunkTheme.neonCyan, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: CyberpunkTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('libretranslate_url', url);
                setState(() => _libreTranslateUrl = url);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: CyberpunkTheme.neonCyan, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showTranslateApiKeyDialog() {
    final controller = TextEditingController(text: _libreTranslateApiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('LibreTranslate API Key', style: TextStyle(color: CyberpunkTheme.textWhite, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your LibreTranslate API key (leave empty if not required)', style: TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: CyberpunkTheme.textWhite),
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'API key',
                hintStyle: TextStyle(color: CyberpunkTheme.textTertiary),
                filled: true,
                fillColor: CyberpunkTheme.cardDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CyberpunkTheme.neonCyan, width: 1)),
                prefixIcon: const Icon(Icons.vpn_key_rounded, color: CyberpunkTheme.neonCyan, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: CyberpunkTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final key = controller.text.trim();
              // SECURITY: Save to encrypted secure storage
              await _secureStorage.write(key: 'libretranslate_api_key', value: key);
              setState(() => _libreTranslateApiKey = key);
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: CyberpunkTheme.neonCyan, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showOpenaiEndpointDialog() {
    final controller = TextEditingController(text: _openaiTranslateEndpoint);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('OpenAI Endpoint', style: TextStyle(color: CyberpunkTheme.textWhite, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the URL of your OpenAI-compatible API endpoint', style: TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: CyberpunkTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'https://api.openai.com/v1/chat/completions',
                hintStyle: TextStyle(color: CyberpunkTheme.textTertiary),
                filled: true,
                fillColor: CyberpunkTheme.cardDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF10A37F), width: 1)),
                prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF10A37F), size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: CyberpunkTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final url = controller.text.trim();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('openai_translate_endpoint', url);
              setState(() => _openaiTranslateEndpoint = url);
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF10A37F), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showOpenaiTranslateKeyDialog() {
    final controller = TextEditingController(text: _openaiTranslateApiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('OpenAI API Key', style: TextStyle(color: CyberpunkTheme.textWhite, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your OpenAI API key for translation', style: TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: CyberpunkTheme.textWhite),
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'sk-...',
                hintStyle: TextStyle(color: CyberpunkTheme.textTertiary),
                filled: true,
                fillColor: CyberpunkTheme.cardDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF10A37F), width: 1)),
                prefixIcon: const Icon(Icons.vpn_key_rounded, color: Color(0xFF10A37F), size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: CyberpunkTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final key = controller.text.trim();
              // SECURITY: Save to encrypted secure storage
              await _secureStorage.write(key: 'openai_translate_api_key', value: key);
              setState(() => _openaiTranslateApiKey = key);
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF10A37F), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  static const _appLanguageOptions = {
    '': 'System Default',
    'en': 'English',
    'fr': 'Français',
    'es': 'Español',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
    'nl': 'Nederlands',
    'ru': 'Русский',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
    'ar': 'العربية',
    'hi': 'हिन्दी',
    'tr': 'Türkçe',
    'pl': 'Polski',
    'uk': 'Українська',
  };

  void _showAppLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CyberpunkTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: CyberpunkTheme.borderDark, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('App Language', style: TextStyle(color: CyberpunkTheme.textWhite, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: _appLanguageOptions.entries.map((entry) {
                final isSelected = _appLocaleCode == entry.key;
                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: isSelected ? CyberpunkTheme.neonCyan : CyberpunkTheme.textTertiary,
                    size: 22,
                  ),
                  title: Text(entry.value, style: TextStyle(color: isSelected ? CyberpunkTheme.neonCyan : CyberpunkTheme.textWhite, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                  trailing: entry.key.isNotEmpty ? Text(entry.key.toUpperCase(), style: const TextStyle(color: CyberpunkTheme.textTertiary, fontSize: 12, letterSpacing: 1)) : null,
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('app_locale', entry.key);
                    setState(() => _appLocaleCode = entry.key);
                    // Update the app locale via MyAppState
                    final state = context.findAncestorStateOfType<MyAppState>();
                    if (entry.key.isEmpty) {
                      state?.setLocale(WidgetsBinding.instance.platformDispatcher.locale);
                    } else {
                      state?.setLocale(Locale(entry.key));
                    }
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CyberpunkTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: CyberpunkTheme.borderDark, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Target Language', style: TextStyle(color: CyberpunkTheme.textWhite, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ..._languageOptions.entries.map((entry) {
            final isSelected = _translateTargetLang == entry.key;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected ? CyberpunkTheme.neonCyan : CyberpunkTheme.textTertiary,
                size: 22,
              ),
              title: Text(entry.value, style: TextStyle(color: isSelected ? CyberpunkTheme.neonCyan : CyberpunkTheme.textWhite, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
              trailing: Text(entry.key.toUpperCase(), style: TextStyle(color: CyberpunkTheme.textTertiary, fontSize: 12, letterSpacing: 1)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('translate_target_lang', entry.key);
                setState(() => _translateTargetLang = entry.key);
                Navigator.pop(ctx);
              },
            );
          }),
          const SizedBox(height: 16),
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
        title: Text(
           S.of(context).settings,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: CyberpunkTheme.textWhite),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: CyberpunkTheme.borderDark),
        ),
      ),
      body: ListView(
        children: [
           _sectionHeader(S.of(context).editProfile.split(' ').first),
          _settingsItem(
            icon: Icons.person_outline_rounded,
             title: S.of(context).editProfile,
            onTap: () => Navigator.pushNamed(context, '/EditProfile'),
          ),
          _settingsItem(
            icon: Icons.lock_outline_rounded,
             title: S.of(context).settings,
            trailing: Switch(
              value: _privateAccount,
              onChanged: (value) {
                setState(() => _privateAccount = value);
                appLogger.info('Updating privacy to: $value');
              },
            ),
          ),
          _settingsItem(
            icon: Icons.block_rounded,
             title: S.of(context).mutedBlocked,
             subtitle: S.of(context).mutedBlocked,
            onTap: () => Navigator.pushNamed(context, '/MutedBlocked'),
          ),
          _divider(),

           _sectionHeader(S.of(context).notificationSettings),
          _settingsItem(
            icon: Icons.notifications_none_rounded,
            title: 'Push Notifications',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                appLogger.info('Updating notifications to: $value');
              },
            ),
          ),
          // Granular notification preferences
          _notifToggle(Icons.alternate_email_rounded, 'Mentions', _notifyMentions, 'notify_mentions', (v) => setState(() => _notifyMentions = v)),
          _notifToggle(Icons.favorite_rounded, 'Likes', _notifyLikes, 'notify_likes', (v) => setState(() => _notifyLikes = v)),
          _notifToggle(Icons.repeat_rounded, 'Boosts / Reblogs', _notifyBoosts, 'notify_boosts', (v) => setState(() => _notifyBoosts = v)),
          _notifToggle(Icons.person_add_rounded, 'New Followers', _notifyFollows, 'notify_follows', (v) => setState(() => _notifyFollows = v)),
          _notifToggle(Icons.mail_rounded, 'Direct Messages', _notifyDMs, 'notify_dms', (v) => setState(() => _notifyDMs = v)),
          _notifToggle(Icons.poll_rounded, 'Polls', _notifyPolls, 'notify_polls', (v) => setState(() => _notifyPolls = v)),
          _settingsItem(
            icon: Icons.notification_important_outlined,
            title: 'Test Notification',
            onTap: () async {
              try {
                await AwesomeNotifications().createNotification(
                  content: NotificationContent(
                    id: 888,
                    channelKey: 'internal',
                    title: 'Test Notification',
                    body: 'Notifications are working! 🚀',
                  ),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Test notification sent!'),
                      backgroundColor: CyberpunkTheme.cardDark,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFFF4757)),
                  );
                }
              }
            },
          ),
          _divider(),

           _sectionHeader(S.of(context).aiCreativity),
          _settingsItem(
            icon: Icons.swap_horiz_rounded,
            title: 'Default AI Provider',
            subtitle: _providerLabels[_defaultAiProvider] ?? 'Stability AI',
            onTap: _showProviderPicker,
          ),
          ..._providerLabels.entries.map((entry) {
            final id = entry.key;
            final key = _aiKeys[id] ?? '';
            final color = _providerColors[id] ?? CyberpunkTheme.neonPink;
            return _settingsItem(
              icon: _providerIcons[id] ?? Icons.key,
              title: '${entry.value} Key',
              subtitle: key.isNotEmpty ? '••••${key.substring(key.length > 4 ? key.length - 4 : 0)}' : 'Not configured',
              onTap: () => _showApiKeyDialog(id),
            );
          }),
          _divider(),

           _sectionHeader(S.of(context).translation),
          // Auto-translate toggle
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: CyberpunkTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _autoTranslateEnabled ? CyberpunkTheme.neonCyan.withOpacity(0.3) : CyberpunkTheme.borderDark),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CyberpunkTheme.neonCyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.translate_rounded, color: CyberpunkTheme.neonCyan, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(S.of(context).autoTranslateAll, style: TextStyle(color: CyberpunkTheme.textWhite, fontSize: 15, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('Automatically translate every post on display', style: TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Switch(
                  value: _autoTranslateEnabled,
                  activeColor: CyberpunkTheme.neonCyan,
                  onChanged: (v) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('auto_translate_enabled', v);
                    setState(() => _autoTranslateEnabled = v);
                  },
                ),
              ],
            ),
          ),
          if (_autoTranslateEnabled) ...[
            const SizedBox(height: 8),
            // Provider picker
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // OpenAI option
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('translate_provider', 'openai');
                        setState(() => _translateProvider = 'openai');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _translateProvider == 'openai'
                              ? const Color(0xFF10A37F).withOpacity(0.15)
                              : CyberpunkTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _translateProvider == 'openai'
                                ? const Color(0xFF10A37F).withOpacity(0.5)
                                : CyberpunkTheme.borderDark,
                            width: _translateProvider == 'openai' ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.smart_toy_rounded,
                                color: _translateProvider == 'openai'
                                    ? const Color(0xFF10A37F)
                                    : CyberpunkTheme.textTertiary,
                                size: 24),
                            const SizedBox(height: 6),
                            Text('OpenAI',
                                style: TextStyle(
                                  color: _translateProvider == 'openai'
                                      ? const Color(0xFF10A37F)
                                      : CyberpunkTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: _translateProvider == 'openai'
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // LibreTranslate option
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('translate_provider', 'libretranslate');
                        setState(() => _translateProvider = 'libretranslate');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _translateProvider == 'libretranslate'
                              ? CyberpunkTheme.neonCyan.withOpacity(0.12)
                              : CyberpunkTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _translateProvider == 'libretranslate'
                                ? CyberpunkTheme.neonCyan.withOpacity(0.5)
                                : CyberpunkTheme.borderDark,
                            width: _translateProvider == 'libretranslate' ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.translate_rounded,
                                color: _translateProvider == 'libretranslate'
                                    ? CyberpunkTheme.neonCyan
                                    : CyberpunkTheme.textTertiary,
                                size: 24),
                            const SizedBox(height: 6),
                            Text('LibreTranslate',
                                style: TextStyle(
                                  color: _translateProvider == 'libretranslate'
                                      ? CyberpunkTheme.neonCyan
                                      : CyberpunkTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: _translateProvider == 'libretranslate'
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Provider-specific config
            if (_translateProvider == 'openai') ...[
              _settingsItem(
                icon: Icons.link_rounded,
                title: 'OpenAI Endpoint',
                subtitle: _openaiTranslateEndpoint,
                onTap: () => _showOpenaiEndpointDialog(),
              ),
              _settingsItem(
                icon: Icons.vpn_key_rounded,
                title: 'OpenAI API Key',
                subtitle: _openaiTranslateApiKey.isEmpty ? 'Not set (required)' : '••••••••',
                onTap: () => _showOpenaiTranslateKeyDialog(),
              ),
            ],
            if (_translateProvider == 'libretranslate') ...[
              _settingsItem(
                icon: Icons.dns_rounded,
                title: 'LibreTranslate Server',
                subtitle: _libreTranslateUrl,
                onTap: () => _showTranslateUrlDialog(),
              ),
              _settingsItem(
                icon: Icons.vpn_key_rounded,
                title: 'LibreTranslate API Key',
                subtitle: _libreTranslateApiKey.isEmpty ? 'Not set' : '••••••••',
                onTap: () => _showTranslateApiKeyDialog(),
              ),
            ],
          ],
          _settingsItem(
            icon: Icons.language_rounded,
             title: S.of(context).targetLanguage,
            subtitle: _languageOptions[_translateTargetLang] ?? _translateTargetLang,
            onTap: () => _showLanguagePicker(),
          ),
          _divider(),

           _sectionHeader(S.of(context).bookmarks.split(' ').first),
          _settingsItem(
            icon: Icons.bookmark_outline_rounded,
             title: S.of(context).bookmarks,
            onTap: () => Navigator.pushNamed(context, '/Bookmarks'),
          ),
          _settingsItem(
            icon: Icons.favorite_outline_rounded,
             title: S.of(context).likedPosts,
            onTap: () => Navigator.pushNamed(context, '/LikedPosts'),
          ),
          _settingsItem(
            icon: Icons.history_rounded,
             title: S.of(context).archivedPosts,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ArchivedPostsPage(apiService: widget.apiService)));
            },
          ),
          _settingsItem(
            icon: Icons.collections_outlined,
             title: S.of(context).collections,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => CollectionsPage(apiService: widget.apiService)));
            },
          ),
          _divider(),

          _sectionHeader('Privacy & Safety'),
          _settingsItem(
            icon: Icons.block_outlined,
             title: S.of(context).domainBlocks,
             subtitle: S.of(context).domainBlocks,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => DomainBlocksPage(apiService: widget.apiService)));
            },
          ),
          _settingsItem(
            icon: Icons.filter_alt_outlined,
             title: S.of(context).contentFilters,
             subtitle: S.of(context).contentFilters,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ContentFiltersPage(apiService: widget.apiService)));
            },
          ),
          _divider(),

           _sectionHeader(S.of(context).appLanguage),
          _settingsItem(
            icon: Icons.language_rounded,
             title: S.of(context).appLanguage,
             subtitle: _appLocaleCode.isEmpty ? S.of(context).systemDefault : (_appLanguageOptions[_appLocaleCode] ?? _appLocaleCode),
            onTap: _showAppLanguagePicker,
          ),
          _divider(),

           _sectionHeader(S.of(context).about),
          _settingsItem(
            icon: Icons.info_outline_rounded,
            title: 'About FediSpace',
            subtitle: 'Version 2.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'FediSpace',
                applicationVersion: '2.0.0',
                applicationLegalese: '© 2024 FediSpace',
                children: [
                  const SizedBox(height: 16),
                  const Text('A modern Pixelfed client'),
                ],
              );
            },
          ),
          _settingsItem(
            icon: Icons.dns_outlined,
            title: 'Instance',
            subtitle: widget.apiService.getInstanceUrl() ?? 'Not connected',
          ),
          _divider(),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                foregroundColor: CyberpunkTheme.neonPink,
                side: BorderSide(color: CyberpunkTheme.neonPink.withOpacity(0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
               child: Text(S.of(context).logout, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: CyberpunkTheme.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _notifToggle(IconData icon, String title, bool value, String prefKey, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: CyberpunkTheme.textSecondary),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14, color: CyberpunkTheme.textWhite))),
          SizedBox(
            height: 28, width: 44,
            child: FittedBox(
              child: Switch(
                value: value,
                activeColor: CyberpunkTheme.neonCyan,
                onChanged: (v) async {
                  onChanged(v);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(prefKey, v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: CyberpunkTheme.neonCyan.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: CyberpunkTheme.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, color: CyberpunkTheme.textWhite)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle, style: const TextStyle(fontSize: 13, color: CyberpunkTheme.textTertiary)),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              const Icon(Icons.chevron_right_rounded, size: 20, color: CyberpunkTheme.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 0.5,
      color: CyberpunkTheme.borderDark,
    );
  }
}
