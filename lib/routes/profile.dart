// Initial Import
import 'dart:convert';

import 'package:fedispace/services/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../data/account.dart';
import '../data/accountUsers.dart';

var UserAccount;

class Profile extends StatefulWidget {
  final ApiService apiService;

  const Profile({Key? key, required this.apiService}) : super(key: key);

  @override
  State<Profile> createState() => _Profile();
}

class _Profile extends State<Profile> {
  final apiService = ApiService();
  final title = 'Fedi Space';
  int page = 0;
  Account? account;
  AccountUsers? accountUsers;

  late Object jsonData;

  String getFormattedNumber(int? inputNumber) {
    String result;
    if (inputNumber! >= 1000000) {
      result = "${(inputNumber / 1000000).toStringAsFixed(1)}M";
    } else if (inputNumber >= 10000) {
      result = "${(inputNumber / 1000).toStringAsFixed(1)}K";
    } else {
      result = inputNumber.toString();
    }
    return result;
  }

  Future<Object> fetchAccount() async {
    final arguments = (ModalRoute.of(context)?.settings.arguments ??
        <String, dynamic>{}) as Map;
    if (arguments["id"] != null) {
      print(arguments["id"]);
      AccountUsers currentAccount =
          (await widget.apiService.getUserAccount(arguments["id"].toString()));
      UserAccount = currentAccount;
      return accountUsers = currentAccount;
    } else {
      Account currentAccount = await widget.apiService.getAccount();
      UserAccount = currentAccount;
      return account = currentAccount;
    }
  }

  String avatarUrl() {
    var domain = widget.apiService.domainURL();
    if (UserAccount!.avatarUrl.contains("://")) {
      return UserAccount!.avatarUrl.toString();
    } else {
      return domain.toString() + UserAccount!.avatarUrl;
    }
  }

  Future getUserStatus(id, page) async {
    var jsonResult = await widget.apiService.getUserStatus(id, page);
    page++;
    return jsonResult;
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() async {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        getUserStatus(UserAccount.id, page);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Object>(
        future: fetchAccount(),
        builder: (BuildContext context, AsyncSnapshot<Object> snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
                body: Stack(
              children: [
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
                    ))),
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.3,
                  padding: const EdgeInsets.fromLTRB(15, 30, 0, 0),
                  color: Colors.black54,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          avatarUrl(),
                          width: (MediaQuery.of(context).size.width - 2 * 15) *
                              0.3,
                        ),
                      ),
                      Container(
                        width: 15,
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                UserAccount?.displayName ?? "none",
                                overflow: TextOverflow.fade,
                                style: const TextStyle(
                                    fontSize: 23, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          getFormattedNumber(
                                              UserAccount.statuses_count),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const Text('Posts')
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          getFormattedNumber(
                                              UserAccount.followers_count),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const Text('Followers')
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          getFormattedNumber(
                                              UserAccount.following_count),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const Text('Following')
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5.0),
                                child: Row(
                                  children: [
                                    const Text('Public: '),
                                    (UserAccount.isLocked == false)
                                        ? const Icon(
                                            Icons.check_circle_outline_outlined,
                                            color: Colors.green,
                                            size: 20,
                                          )
                                        : const Icon(
                                            Icons.cancel_outlined,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                    const SizedBox(
                                      width: 7,
                                    ),
                                    const Text('Bot: '),
                                    (UserAccount.isBot == false)
                                        ? const Icon(
                                            Icons.check_circle_outline_outlined,
                                            color: Colors.green,
                                            size: 20,
                                          )
                                        : const Icon(
                                            Icons.cancel_outlined,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )

                      /// GRIDVIEW HERE
                    ],
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.fromLTRB(
                      0, MediaQuery.of(context).size.height * 0.3, 0, 0),
                  color: Colors.black54,
                  child: Column(
                    children: [
                      Html(
                        data: UserAccount?.note ?? "",
                      ),
                      FutureBuilder(
                          future: getUserStatus(UserAccount.id, 0),
                          builder:
                              (BuildContext context, AsyncSnapshot snapshot) {
                            if (snapshot.data != null) {
                              var data = jsonDecode(snapshot.data);
                              //var data = snapshot.data;
                              print(snapshot.data.length);
                              return Container(
                                  height: 300,
                                  width: 300,
                                  child: GridView.builder(
                                    controller: _scrollController,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                    ),
                                    itemCount: data.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      //return Image.asset(images[index], fit: BoxFit.cover);
                                      return Image.network(data[index]
                                          ["media_attachments"][0]["url"]);
                                    },
                                  ));
                            } else if (snapshot.hasError) {
                              print("error");
                              print(snapshot.error);
                              return const Text("error");
                            }
                            return const CircularProgressIndicator();
                          }),
                    ],
                  ),
                )
              ],
            ));
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error dans la function profile"));
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        });
  }
}
