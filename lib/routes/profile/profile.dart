// Initial Import
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/models/account.dart';
import 'package:fedispace/models/accountUsers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';


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
  int page = 1;
  Account? account;
  AccountUsers? accountUsers;

  late Object jsonData;
   List<Map<String, dynamic>> arrayOfProducts = [];
  bool isPageLoading = false;


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

  void makeRebuild(){
    setState(() {
      print("rebuild");
    });
  }

  Future <List<Map<String, dynamic>>> _callAPIToGetListOfData() async {
    if (isPageLoading == true || (isPageLoading == false && page == 1 )){
      final responseDic ;
      if(arrayOfProducts.length == 0 ){
        responseDic = await widget.apiService.getUserStatus(UserAccount.id, page, "0");
      }else{
        responseDic = await widget.apiService.getUserStatus(UserAccount.id, page, arrayOfProducts[arrayOfProducts.length-1]["id"]);
      }
      List<Map<String, dynamic>> temArr = List<Map<String, dynamic>>.from(responseDic);
      print("_callAPIToGetListOfData");
      print("page : ${page}");
      print("length : ${arrayOfProducts.length}");
      if (page == 1) {
        print(responseDic[0]);
        arrayOfProducts = temArr;
      }
      else {

        print(responseDic[0]);
        arrayOfProducts.addAll(temArr);
      }
      responseDic.forEach((element) {
        print(element["id"]);
      });
      print(arrayOfProducts[arrayOfProducts.length -1]["id"]);
      return arrayOfProducts;
    }
     return arrayOfProducts;
  }


    String avatarUrl() {
    var domain = widget.apiService.domainURL();
    if (UserAccount!.avatarUrl.contains("://")) {
      return UserAccount!.avatarUrl.toString();
    } else {
      return domain.toString() + UserAccount!.avatarUrl;
    }
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() async {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (arrayOfProducts.length >= (16 * page)  ) {
          page++;
          print("PAGE NUMBER $page");
          print("getting data");
          isPageLoading = true;
          await _callAPIToGetListOfData();
          isPageLoading = false;
          makeRebuild();
        }

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
                          future: _callAPIToGetListOfData(),
                          builder:
                              (BuildContext context, AsyncSnapshot snapshot) {
                            if (snapshot.data != null) {
                              return Container(
                                  height: 400,
                                  width: 400,
                                  child: GridView.builder(
                                    addAutomaticKeepAlives : true,
                                    addRepaintBoundaries :  true,
                                    addSemanticIndexes : true,
                                    reverse : false,
                                    controller: _scrollController,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                    ),
                                    itemCount: snapshot.data.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      //return Image.asset(images[index], fit: BoxFit.cover);
                                      return Container(
                                        child: CachedNetworkImage(
                                            imageUrl: snapshot.data[index]
                                            ["media_attachments"][0]["url"],
                                            placeholder: (context, url) => BlurHash(
                                                hash: snapshot.data[index]
                                                ["media_attachments"][0]
                                                ["blurhash"]),
                                            errorWidget: (context, url, error) =>
                                            const Icon(Icons.error),
                                            imageBuilder: (context, imageProvider) =>
                                                Container(
                                                    margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 3,
                                                        vertical: 3),
                                                    //apply padding horizontal or vertical only
                                                    width: 490,
                                                    height: 290,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                          width: 1,
                                                          color: Colors.black54,
                                                        ),
                                                        // Make rounded corners
                                                        borderRadius: BorderRadius.circular(15),
                                                      image: DecorationImage(
                                                        image: imageProvider,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    )))
                                      );
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
