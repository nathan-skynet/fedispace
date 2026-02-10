// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously
import 'package:fedispace/core/api.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/core/unifiedpush.dart';
import 'package:fedispace/models/account.dart';
import 'package:fedispace/routes/homepage/homepage2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  /// Main instance of the API service to use in the widget.
  final ApiService apiService;
  final UnifiedPushService unifiedPushService;

  const HomeScreen(
      {Key? key, required this.apiService, required this.unifiedPushService})
      : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

/// The [_LoginState] wraps the logic and state for the [Login] screen.
class _HomeScreen extends State<HomeScreen> with TickerProviderStateMixin {
  Account? account;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _heartScale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    return Scaffold(
        body: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Stack(children: [
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            image: const DecorationImage(
              image: NetworkImage("https://img.freepik.com/free-vector/dark-hexagonal-background-with-gradient-color_79603-1409.jpg"), // Hex grid pattern
              fit: BoxFit.cover,
              opacity: 0.2, // Subtle background texture
            ),
          ),
        ),
        Login(
          apiService: widget.apiService,
          unifiedPushService: widget.unifiedPushService,
        ),
        Center(
          child: Container(
              margin: const EdgeInsets.fromLTRB(0, 60, 0, 0),
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F3FF).withValues(alpha: 0.25),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: const Color(0xFFFF2D78).withValues(alpha: 0.15),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
                image: const DecorationImage(
                  image: AssetImage("assets/icon/app_icon.png"),
                  fit: BoxFit.cover,
                ),
              )),
        ),
        SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  S.of(context).loginCommunityTagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.white70,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      S.of(context).loginMadeWith,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    // Animated pulsing heart with glow
                    ScaleTransition(
                      scale: _heartScale,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2D55).withValues(alpha: 0.6),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: const Color(0xFF00F3FF).withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFFFF2D55),
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () async {
                        Uri url = Uri.parse("https://me.echelon4.space");
                        var urlLaunchable = await canLaunchUrl(url);
                        if (urlLaunchable) {
                          await launchUrl(url);
                        } else {
                          debugPrint("URL can't be launched.");
                        }
                      },
                      child: const Text(
                        "Sk7n4k3d",
                        style: TextStyle(
                          color: Color(0xFF00F3FF),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF00F3FF),
                        ),
                      ),
                    ),
                    Text(
                      S.of(context).loginAndCommunity,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                Container(
                  height: 10,
                )
              ],
            )),
      ]),
    ));
  }
}
