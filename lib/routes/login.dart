// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fedispace/services/api.dart';
import 'package:fedispace/data/account.dart';
import 'package:fedispace/services/unifiedpush.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fedispace/routes/homepage/login.dart';

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
    //checkAuthStatus();
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
              gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.lightBlue,
              Colors.red.shade900,
              Colors.blue.shade800,
            ],
          )),
        ),
         Login(apiService: widget.apiService, unifiedPushService: widget.unifiedPushService,),
        Center(
          child: Container(
              margin: const EdgeInsets.fromLTRB(0, 50, 0, 0),
              width: 200,
              height: 160,
              decoration: const BoxDecoration(
                  image: DecorationImage(
                image: AssetImage("assets/images/logo/logo_color.png"),
                fit: BoxFit.fill,
              ))),
        ),
       Container(
           width: MediaQuery.of(context).size.width,
           height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisAlignment : MainAxisAlignment.end,
            mainAxisSize : MainAxisSize.max,
            crossAxisAlignment : CrossAxisAlignment.center,

            children:  [
               const Text(
                "For the community by the community.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black
                ),
              ),
              Text.rich(
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black),
                  TextSpan(
                      children: [
                        const TextSpan(
                            text: "Made With ❤️ by "
                        ),
                        TextSpan(
                            style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline
                            ),
                            text: "Nathan Skynet",
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                Uri url = Uri.parse(
                                    "https://me.echelon4.space");
                                var urlLaunchable = await canLaunchUrl(
                                    url); //canLaunch is from url_launcher package
                                if (urlLaunchable) {
                                  await launchUrl(
                                      url); //launch is from url_launcher package to launch URL
                                } else {
                                  debugPrint("URL can't be launched.");
                                }
                              }
                        ),
                        const TextSpan(
                            text: " and The community..."
                        ),
                      ]
                  ),
              ),
              Container(height: 10,)
          ],)
        ),
      ]),
    ));
  }
}
