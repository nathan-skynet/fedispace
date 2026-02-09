// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously
import 'package:fedispace/core/api.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/core/unifiedpush.dart';
import 'package:fedispace/models/account.dart';
import 'package:fedispace/routes/homepage/homepage2.dart';
import 'package:flutter/gestures.dart';
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
class _HomeScreen extends State<HomeScreen> {
  Account? account;

  @override
  void initState() {
    super.initState();
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
                    color: const Color(0xFF00F3FF).withOpacity(0.25),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: const Color(0xFFFF2D78).withOpacity(0.15),
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
                Text.rich(
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                  TextSpan(children: [
                    TextSpan(text: S.of(context).loginMadeWith),
                    TextSpan(
                        style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline),
                        text: "Nathan Skynet",
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            Uri url = Uri.parse("https://me.echelon4.space");
                            var urlLaunchable = await canLaunchUrl(
                                url); //canLaunch is from url_launcher package
                            if (urlLaunchable) {
                              await launchUrl(
                                  url); //launch is from url_launcher package to launch URL
                            } else {
                              debugPrint("URL can't be launched.");
                            }
                          }),
                    TextSpan(text: S.of(context).loginAndCommunity),
                  ]),
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
