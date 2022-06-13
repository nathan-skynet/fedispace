import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import '../services/api.dart';

class Notif extends StatefulWidget implements PreferredSizeWidget {
  final ApiService apiService;

  /// Main instance of the API service to use in the widget.
  Notif({Key? key, required this.apiService}) : super(key: key);
  @override
  State<Notif> createState() => _Notification();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _Notification extends State<Notif> with TickerProviderStateMixin {
  List notificationState = [];
  @override
  void initState() {
    super.initState();
  }

  late final Notif notif;

  Future<bool> _onWillPop() async {
    Navigator.pushReplacementNamed(context, "/TimeLine");
    return false;
  }

  Future getData() async {
    try {
      var json = jsonDecode(await widget.apiService.getNotification());
      List data = json;
      List notifications = [];
      data.forEach((element) {
        notifications.add(element);
      });
      return notificationState = notifications;
    } catch (e) {
      return e;
    }
  }

  @override
  Widget build(BuildContext context) {
    final domain = widget.apiService.domainURL();
    return WillPopScope(
        onWillPop: _onWillPop,
        child: FutureBuilder(
            future: getData(),
            builder: (ctx, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                    child: Text(
                        "Erreur dans la fonction getNotification builder"));
              } else if (snapshot.hasData) {
                return RefreshIndicator(
                  displacement: 100,
                  strokeWidth: 3,
                  triggerMode: RefreshIndicatorTriggerMode.onEdge,
                  onRefresh: () async {
                    var test = await getData();
                    setState(() {
                      notificationState = test;
                    });
                  },
                  child: Scaffold(
                    appBar: AppBar(
                      title: const Center(child: Text('Notifications')),
                    ),
                    body: _body2(domain, notificationState),
                  ),
                );
              }
              return const Center(
                child: CircularProgressIndicator(),
              );
            }));
  }
}

void onTap(context, id) {
  Navigator.of(context).pushNamed('/Profile', arguments: {'id': id});
}

String convertToAgo(DateTime input) {
  Duration diff = DateTime.now().difference(input);

  if (diff.inDays >= 1) {
    return '${diff.inDays} day(s) ago';
  } else if (diff.inHours >= 1) {
    return '${diff.inHours} hour(s) ago';
  } else if (diff.inMinutes >= 1) {
    return '${diff.inMinutes} minute(s) ago';
  } else if (diff.inSeconds > 1) {
    return '${diff.inSeconds} second(s) ago';
  } else {
    return 'just now';
  }
}

Widget _body2(domain, data) {
  return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Container(
            margin: const EdgeInsets.all(3),
            height: 100,
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: BorderRadius.all(Radius.circular(10))),
            child: Container(
              //color: Colors.pinkAccent,
              padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
              child: Row(
                //  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      onTap(context, data[index]["account"]["id"]);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.network(
                        data[index]["account"]["avatar_static"]
                                .toString()
                                .contains("://")
                            ? data[index]["account"]["avatar_static"]
                            : domain + data[index]["account"]["avatar_static"],
                        height: 95.0,
                        width: 80.0,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  //SizedBox(width: 20,),
                  Container(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          data[index]["account"]["display_name"] != ""
                              ? data[index]["account"]["display_name"]
                              : data[index]["account"]["username"],
                          style: const TextStyle(
                              // color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        if (data[index]["type"] == "favourite") ...[
                          Container(
                            padding: const EdgeInsets.only(top: 5),
                            child: const Text(
                              "As liked your post",
                              style:
                                  TextStyle(color: Colors.black, fontSize: 15),
                            ),
                          ),
                        ],
                        if (data[index]["type"] == "follow") ...[
                          Container(
                            padding: const EdgeInsets.only(top: 5),
                            child: const Text(
                              "Following you",
                              style:
                                  TextStyle(color: Colors.black, fontSize: 15),
                            ),
                          ),
                        ],
                        if (data[index]["type"] == "follow_request") ...[
                          Container(
                            padding: const EdgeInsets.only(top: 5),
                            child: const Text(
                              "Requested to follow you",
                              style:
                              TextStyle(color: Colors.black, fontSize: 15),
                            ),
                          ),
                        ],
                        if (data[index]["type"] == "mention") ...[
                          Container(
                            padding: const EdgeInsets.only(top: 5),
                            child: const Text(
                              "Mentioned you in their status",
                              style:
                              TextStyle(color: Colors.black, fontSize: 15),
                            ),
                          ),
                        ],
                         //   Container(
                        //  padding: const EdgeInsets.only(top: 5),
                        // child: const Text(
                        //    "Dev, do you have a moment?We'd love",
                        //    style: TextStyle(
                                // color: Colors.black,
                        //        fontSize: 11),
                       //   ),
                        //),
                      ],
                    ),
                  ),
                  Expanded(
                     flex : 50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(convertToAgo(DateTime.parse(data[index]["created_at"])),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade400),
                        ),
                        const SizedBox(
                          height: 22,
                        ),
                        Container(
                          // height: 20,
                          // width: 20,
                          margin: const EdgeInsets.only(left: 10),
                          //color: Colors.pinkAccent,
                          child: const Icon(
                            Icons.star,
                            color: Colors.grey,
                          ),
                        )
                      ],
                    ),
                  )

                ],
              ),
            ),
          ),
        );
      });
}

//data[index]["type"].toString()
