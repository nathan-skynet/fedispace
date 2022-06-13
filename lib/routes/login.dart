// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:fedispace/delayed_animation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:fedispace/services/api.dart';
import 'package:fedispace/utils/messages.dart';
import 'package:fedispace/data/account.dart';
import 'package:fedispace/services/unifiedpush.dart';

class HomeScreen extends StatefulWidget {
/// Main instance of the API service to use in the widget.
final ApiService apiService;
final UnifiedPushService  unifiedPushService;

const HomeScreen({Key? key, required this.apiService, required this.unifiedPushService}) : super(key: key);
@override
State<HomeScreen> createState() => _HomeScreen();
}

/// The [_LoginState] wraps the logic and state for the [Login] screen.
class _HomeScreen extends State<HomeScreen> {
  Account? account;

  TextEditingController instanceController = TextEditingController();

  Future<void> onValidAuth() async {
    final account = await widget.apiService.logIn();
    //showSnackBar(
      //  context, "Successfully logged in. Welcome, ${account.username}!");
    await widget.unifiedPushService.InitUnifiedPush();
    await widget.unifiedPushService.StartUnifiedPush(context);
    Navigator.pushNamedAndRemoveUntil(context, '/TimeLine', (route) => false);
  }

  Future<void> checkAuthStatus() async {
    await widget.apiService.loadApiServiceFromStorage();
    if (widget.apiService.helper != null) {
      AccessTokenResponse? token = await widget.apiService.helper!.getTokenFromStorage();
      if (token != null) {
        return onValidAuth();
      }
    }
  }
  void reportLogInError(String message) {
    widget.apiService.resetApiServiceState();
    showSnackBar(
      context,
      message,
    );
  }

  Future<void> logInAction(String instanceUrl) async {
    try {
      widget.apiService.NodeInfo();
    }
      on ApiException {
        return reportLogInError(
          "We couldn't connect to $instanceUrl as a Pixelfed instance. Please check the URL and try again! or check Mobile_API=true on instance",
        );
      }
    try {
      await widget.apiService.registerApp(instanceUrl);
    } on ApiException {
      return reportLogInError(
        "We couldn't connect to $instanceUrl as a Pixelfed instance. Please check the URL and try again!",
      );
    }

    // We could register the app succesfully. Attempting to log in the user.
    try {
      return onValidAuth();
    } on ApiException {
      return reportLogInError(
        "We couldn't log you in with your specified credentials. Please try again!",
      );
    }
  }

  @override
  void initState() {
    checkAuthStatus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    return Scaffold(
      body: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height + 150,
                      decoration: const BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage(
                              "assets/images/background.jpg"),
                          fit: BoxFit.cover
                      )
                      ),
                      margin: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 0
                  ),
                      child: Column(
                        children: [
                          DelayedAnimation(
                            delay: 3500,
                            child: Container(
                              margin: const EdgeInsets.only(
                              top: 35,
                              bottom: 40
                              ),
                              child: const Text(
                                  'FEDI SPACE',
                                  style: TextStyle(
                                    fontFamily: 'glitch',
                                    fontSize: 45,
                                    color: Colors.grey,
                                    shadows: [
                                      Shadow(
                                          blurRadius: 12.0,
                                          color: Colors.black,
                                          offset: Offset(1.0, 5.0)
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center
                              ),
                            ),
                          ),
                          DelayedAnimation(
                          delay: 1500,
                          child: SvgPicture.asset(
                              "assets/images/logo/logo.svg",
                              color: Colors.redAccent[700],
                              semanticsLabel: 'Logo',
                              width: 180
                          )
                          ),
                          DelayedAnimation(
                              delay: 1500,
                              child: Container(
                                  margin: const EdgeInsets.only(
                                    top: 35,
                                  ),
                                  child: TextFormField(
                                      onTap: () {
                                        debugPrint("I'm here!!!");
                                        },
                                      controller: instanceController,
                                      autofocus: false,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                  ),
                                      decoration: const InputDecoration(
                                          labelText: 'Enter your instance',
                                          enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.blue,
                                              )
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.blue,
                                          )
                                      )
                                  )
                              )
                          )
                      ),
                          Expanded(
                              child:
                              Column(
                                children: [
                                  DelayedAnimation(
                                    delay: 3500,
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                        top: 120,
                                        bottom: 10,
                                      ),
                                      child: const Text(
                                        "For the community by the community.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey
                                        ),
                                      ),
                                    ),
                                  ),
                                  DelayedAnimation(
                                    delay: 3500,
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            primary: const Color(0xFFE9717D),
                                            shape: const StadiumBorder(),
                                            padding: const EdgeInsets.all(13)),
                                        child: const Text("Let's Go !"),
                                        onPressed: () {
                                          print(instanceController.text);
                                          logInAction(instanceController.text);
                                        },
                                      ),
                                    ),
                                  ),
                                  DelayedAnimation(
                                    delay: 4500,
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                        top: 10,
                                        bottom: 80,
                                      ),
                                      child:
                                      Text.rich(
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.grey),
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
                                          )
                                      ),
                                    ),
                                  ),
                              Container(
                                  margin: const EdgeInsets.only(
                                    top: 10,
                                    bottom: 80,
                                  ))
                          ]
                              )
                          )
                    ],
                  ),
                ),
              ])
          ),
    );
  }

}

