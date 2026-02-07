import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/error_handler.dart';
import 'package:fedispace/core/unifiedpush.dart';
import 'package:fedispace/routes/homepage/inputWidget.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

String os = Platform.operatingSystem;

class Login extends StatefulWidget {
  /// Main instance of the API service to use in the widget.
  final ApiService apiService;
  final UnifiedPushService unifiedPushService;

  const Login(
      {Key? key, required this.apiService, required this.unifiedPushService})
      : super(key: key);

  @override
  State<Login> createState() => _Login();
}

/// The [_LoginState] wraps the logic and state for the [Login] screen.
class _Login extends State<Login> {
  Future<void> onValidAuth() async {
    final account = await widget.apiService.logIn();

    /// TODO REVOIR UNIFIEDPUSH ENCORE UNE FOIS ET NOTIFICATION SERVICE
    ///
    if (Platform.isAndroid){
      await widget.unifiedPushService.initUnifiedPush();
      await widget.unifiedPushService.startUnifiedPush(context, widget.apiService);
    }

    Fluttertoast.showToast(
        msg: "Successfully logged in. Welcome, ${account.username}!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.green,
        textColor: Colors.black,
        fontSize: 16.0);
    Navigator.pushNamedAndRemoveUntil(context, '/TimeLine', (route) => false);
  }

  Future<void> logInAction(String instanceUrl) async {
    try {
      await widget.apiService.registerApp(instanceUrl);
    } on ApiException {
      Fluttertoast.showToast(
          msg: "Your instance has activated Mobile API ?",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.red,
          textColor: Colors.black,
          fontSize: 16.0);
    }

    // We could register the app succesfully. Attempting to log in the user.
    try {
      return onValidAuth();
    } on ApiException {
      Fluttertoast.showToast(
          msg: "Error in function onValidAuth !",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.red,
          textColor: Colors.black,
          fontSize: 16.0);
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
  void initState() {
    checkAuthStatus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding:
              EdgeInsets.only(top: MediaQuery.of(context).size.height / 2.3),
        ),
        Column(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(left: 40, bottom: 10),
                  child: Text(
                    "Domain Instance",
                    style: TextStyle(fontSize: 16, color: Color(0xFF999A9A)),
                  ),
                ),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: <Widget>[
                    InputWidget(30.0, 0.0),
                    Padding(
                        padding: const EdgeInsets.only(right: 50),
                        child: Row(
                          children: <Widget>[
                            const Expanded(
                                child: Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Text(
                                'Enter your instance to continue...',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                    color: Color(0xFFA0A0A0), fontSize: 12),
                              ),
                            )),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const ShapeDecoration(
                                shape: CircleBorder(),
                                gradient: LinearGradient(
                                    colors: signInGradients,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  FontAwesomeIcons.arrowRight,
                                  size: 30,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  String urlDomain = await randomFun();
                                  //print(urlDomain);
                                  /// TODO Make Condition is Instance Pixelfed or not...
                                  ///   bool resp = await widget.apiService
                                  //    widget.apiService.NodeInfo(urlDomain);
                                  await logInAction(urlDomain);
                                },
                              ),
                            ),
                          ],
                        ))
                  ],
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 50),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/presentation');
              },
              child: roundedRectButton(
                  "What is Pixelfed", signInGradients, false, 0),
            ),
            GestureDetector(
              onTap: () async {
                Uri url = Uri.parse("https://pix.echelon4.space/register");
                var urlLaunchable = await canLaunchUrl(
                    url); //canLaunch is from url_launcher package
                if (urlLaunchable) {
                  await launchUrl(
                      url); //launch is from url_launcher package to launch URL
                } else {
                  debugPrint("URL can't be launched.");
                }
              },
              child: roundedRectButton(
                  "Create an Account", signUpGradients, false, 0),
            )
          ],
        )
      ],
    );
  }
}

Widget roundedRectButton(
    String title, List<Color> gradient, bool isEndIconVisible, list) {
  return Builder(builder: (BuildContext mContext) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Stack(
        alignment: const Alignment(1.0, 0.0),
        children: <Widget>[
          Container(
            alignment: Alignment.center,
            width: MediaQuery.of(mContext).size.width / 1.7,
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0)),
              gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500)),
          ),
          Visibility(
            visible: isEndIconVisible,
            child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  icon: const Icon(
                    FontAwesomeIcons.forward,
                    size: 30,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (list == 0) {
                    } else {}
                  },
                )),
          ),
        ],
      ),
    );
  });
}

const List<Color> signInGradients = [
  Color(0xFF00F3FF), // Neon Cyan
  Color(0xFF0099CC),
];

const List<Color> signUpGradients = [
  Color(0xFFFF00FF), // Neon Pink
  Color(0xFFCC00CC),
];
