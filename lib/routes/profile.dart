// Initial Import
import 'package:fedispace/services/api.dart';
import 'package:fedispace/widgets/header.dart';
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

  Account? account;
  AccountUsers? accountUsers;

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
    final arguments = (ModalRoute
        .of(context)
        ?.settings
        .arguments ??
        <String, dynamic>{}) as Map;
    if (arguments["id"] != null) {
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Object>(
        future: fetchAccount(),
        builder: (BuildContext context, AsyncSnapshot<Object> snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              appBar: HeaderWidget(apiService: widget.apiService),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            avatarUrl(),
                            width:
                            (MediaQuery
                                .of(context)
                                .size
                                .width - 2 * 15) *
                                0.3,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 15.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  UserAccount?.displayName ?? "none",
                                  overflow: TextOverflow.fade,
                                  style: const TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.bold),
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
                                                UserAccount?.statuses_count),
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
                                                UserAccount?.followers_count),
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
                                                UserAccount?.following_count),
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
                                      (UserAccount?.isLocked == false)
                                          ? const Icon(
                                        Icons
                                            .check_circle_outline_outlined,
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
                                      (UserAccount?.isBot == false)
                                          ? const Icon(
                                        Icons
                                            .check_circle_outline_outlined,
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
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Html(
                        data: UserAccount?.note ?? "",
                      ),
                    ),
                    const SizedBox(height: 10),

                    /// GRIDVIEW HERE

                  ],
                ),
              ),
            );
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
