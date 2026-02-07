// Initial Import
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/models/account.dart';
import 'package:fedispace/models/accountUsers.dart';
import 'package:fedispace/widgets/glitch_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' as html;
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
              backgroundColor: const Color(0xFF050505),
              body: Stack(
                children: [
                  // Background with Carbon/Hex pattern
                  Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      decoration: const BoxDecoration(
                          color: Color(0xFF050505),
                          image: DecorationImage(
                            image: NetworkImage("https://img.freepik.com/free-vector/dark-hexagonal-background-with-gradient-color_79603-1409.jpg"),
                            fit: BoxFit.cover,
                            opacity: 0.2,
                          ))),
                  
                  // Header Section (Profile Info)
                  Container(
                    width: MediaQuery.of(context).size.width,
                    // height: MediaQuery.of(context).size.height * 0.35, // Increased height slightly
                    padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101010).withOpacity(0.8),
                      border: Border(bottom: BorderSide(color: const Color(0xFF00F3FF).withOpacity(0.5), width: 1)),
                      boxShadow: [BoxShadow(color: const Color(0xFF00F3FF).withOpacity(0.1), blurRadius: 20)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar with Neon Border
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF00F3FF), width: 2),
                                boxShadow: [BoxShadow(color: const Color(0xFF00F3FF).withOpacity(0.5), blurRadius: 10)],
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  avatarUrl(),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            // User Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GlitchEffect(
                                    child: Text(
                                      UserAccount?.displayName ?? "UNKNOWN IDENTIFIER",
                                      style: const TextStyle(
                                          fontFamily: 'Orbitron',
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [Shadow(color: Color(0xFF00F3FF), blurRadius: 5)]
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Unit ID: ${UserAccount?.id ?? "N/A"}",
                                    style: TextStyle(fontFamily: 'Rajdhani', color: Colors.grey.withOpacity(0.7), fontSize: 14),
                                  ),
                                  const SizedBox(height: 15),
                                  // Stats Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildStatItem("POSTS", UserAccount.statuses_count),
                                      _buildStatItem("FOLLOWERS", UserAccount.followers_count),
                                      _buildStatItem("FOLLOWING", UserAccount.following_count),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // Status Indicators
                        Row(
                          children: [
                            _buildStatusBagde("PUBLIC", UserAccount.isLocked == false),
                            const SizedBox(width: 10),
                            _buildStatusBagde("BOT", UserAccount.isBot == true), // logic was UserAccount.isBot == false ? check : cancel. So if isBot is true, it should show check? The original logic was convoluted. Let's assume isBot true means it IS a bot.
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Body (Bio + Grid)
                  Container(
                    margin: EdgeInsets.only(top: 240), // Shifted down below header
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bio / Note
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: html.Html(
                              data: UserAccount?.note ?? "",
                              style: {
                                "body": html.Style(
                                  fontFamily: 'Rajdhani',
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: html.FontSize(16),
                                ),
                                "a": html.Style(color: const Color(0xFFFF00FF)),
                              },
                            ),
                          ),
                          
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Divider(color: Color(0xFF00F3FF), height: 30),
                          ),

                          // Grid
                          FutureBuilder(
                            future: _callAPIToGetListOfData(),
                            builder: (BuildContext context, AsyncSnapshot snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero, // Zero padding for full width
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 1, // Minimal spacing line
                                    mainAxisSpacing: 1,
                                    childAspectRatio: 1, // Square photos
                                  ),
                                  itemCount: snapshot.data.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    return GestureDetector(
                                      onTap: () {
                                         // Navigate to post detail
                                         Navigator.pushNamed(
                                           context,
                                           '/statusDetail',
                                           arguments: {
                                             'statusId': snapshot.data[index]["id"],
                                             'apiService': widget.apiService,
                                           },
                                         );
                                       },
                                      child: Container(
                                        color: Colors.black, // Background for loading
                                        child: CachedNetworkImage(
                                          imageUrl: snapshot.data[index]["media_attachments"][0]["url"],
                                          placeholder: (context, url) => Container(
                                              color: const Color(0xFF101010),
                                              child: const Center(child: CircularProgressIndicator(color: Color(0xFF00F3FF), strokeWidth: 2))
                                          ),
                                          errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              } else if (snapshot.hasError) {
                                return const Center(child: Text("DATA CORRUPTED", style: TextStyle(color: Colors.red)));
                              }
                              return const Center(child: CircularProgressIndicator(color: Color(0xFF00F3FF)));
                            }
                          ),
                          const SizedBox(height: 100), // Bottom padding
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return const Center(child: Text("SYSTEM ERROR", style: TextStyle(color: Colors.red)));
          }
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00F3FF)),
          );
        });
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          getFormattedNumber(value),
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF00FF), // Neon Pink
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBagde(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF00F3FF).withOpacity(0.1) : Colors.red.withOpacity(0.1),
        border: Border.all(color: isActive ? const Color(0xFF00F3FF) : Colors.red),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? label : "NOT $label",
        style: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 10,
          color: isActive ? const Color(0xFF00F3FF) : Colors.red,
        ),
      ),
    );
  }
}
