import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/error_handler.dart';
import 'package:fedispace/core/unifiedpush.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

String os = Platform.operatingSystem;

// Global controller for instance URL
final TextEditingController _instanceController = TextEditingController();

Future<String> randomFun() async {
  return _instanceController.text.trim();
}

class Login extends StatefulWidget {
  final ApiService apiService;
  final UnifiedPushService unifiedPushService;

  const Login(
      {Key? key, required this.apiService, required this.unifiedPushService})
      : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
    checkAuthStatus();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> onValidAuth() async {
    final account = await widget.apiService.logIn();

    if (Platform.isAndroid) {
      await widget.unifiedPushService.initUnifiedPush();
      await widget.unifiedPushService
          .startUnifiedPush(context, widget.apiService);
    }

    Navigator.pushNamedAndRemoveUntil(context, '/MainScreen', (route) => false);
  }

  Future<void> logInAction(String instanceUrl) async {
    if (instanceUrl.isEmpty) {
      Fluttertoast.showToast(
          msg: S.of(context).loginEnterInstance,
          backgroundColor: Colors.orange,
          textColor: Colors.black);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.apiService.registerApp(instanceUrl);
    } on ApiException {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(
          msg: S.of(context).loginConnectError,
          backgroundColor: Colors.red,
          textColor: Colors.white);
      return;
    }

    try {
      return onValidAuth();
    } on ApiException {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(
          msg: S.of(context).loginAuthError,
          backgroundColor: Colors.red,
          textColor: Colors.white);
    }
  }

  Future<void> checkAuthStatus() async {
    await widget.apiService.loadApiServiceFromStorage();
    if (widget.apiService.helper != null) {
      AccessTokenResponse? token =
          await widget.apiService.helper!.getTokenFromStorage();
      if (token != null) {
        return onValidAuth();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.38),

            // Instance URL Input
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.04),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.08),
                ),
              ),
              child: TextField(
                controller: _instanceController,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  hintText: 'pixelfed.social',
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.3),
                    fontSize: 16,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Icon(
                      Icons.language_rounded,
                      color: const Color(0xFF00F3FF).withOpacity(0.8),
                      size: 22,
                    ),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  suffixIcon: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00F3FF),
                            ),
                          ),
                        )
                      : null,
                ),
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _handleLogin(),
              ),
            ),

            const SizedBox(height: 20),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00F3FF), Color(0xFF0077CC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F3FF).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isLoading ? null : _handleLogin,
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  S.of(context).loginSignIn,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 20),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Secondary buttons row
            Row(
              children: [
                Expanded(
                  child: _SecondaryButton(
                    label: S.of(context).loginWhatIsPixelfed,
                    onTap: () =>
                        Navigator.pushNamed(context, '/presentation'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SecondaryButton(
                    label: S.of(context).loginCreateAccount,
                    onTap: () async {
                      Uri url =
                          Uri.parse("https://pix.echelon4.space/register");
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogin() async {
    String url = _instanceController.text.trim();
    if (url.isNotEmpty) {
      await logInAction(url);
    }
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.black.withOpacity(0.1),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black.withOpacity(0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
