import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../data/account.dart';
import '../services/api.dart';

Account? account;

class NavBar extends StatelessWidget {
  final ApiService apiService;

  const NavBar({required this.apiService, Key? key}) : super(key: key);

  String avatarurl() {
    var domain = apiService.domainURL();
    if (account!.avatarUrl.contains("://")) {
      return account!.avatarUrl.toString();
    } else {
      return domain.toString() + account!.avatarUrl;
    }
  }

  Future<Object> fetchAccount() async {
    Account currentAccount = await apiService.getCurrentAccount();
    return account = currentAccount;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Object>(
        future: fetchAccount(),
        builder: (BuildContext context, AsyncSnapshot<Object> snapshot) {
          if (snapshot.hasData) {
            return Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(40),
                      topRight: Radius.circular(400)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black38, spreadRadius: 5, blurRadius: 15),
                  ],
                ),
                width: 200,
                child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(35),
                        bottomRight: Radius.circular(35)),
                    child: Drawer(
                      child: ListView(
                        // Remove padding
                        padding: EdgeInsets.zero,
                        children: [
                          UserAccountsDrawerHeader(
                            accountName: Text(account?.displayName ?? "none",
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                )),
                            accountEmail: Text(account?.acct ?? "none"),
                            currentAccountPicture: CircleAvatar(
                              child: ClipOval(
                                child: Image.network(
                                  avatarurl(),
                                  fit: BoxFit.cover,
                                  width: 90,
                                  height: 90,
                                ),
                              ),
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              image: DecorationImage(
                                  fit: BoxFit.fill,
                                  image: NetworkImage(
                                      'https://img.myloview.fr/images/abstract-square-pattern-on-gradient-background-pixel-tile-backdrop-graphic-art-random-square-shapes-texture-futuristic-cover-wallpaper-banner-poster-flyer-template-stock-vector-illustration-400-183616984.jpg')),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(FontAwesomeIcons.user),
                            title: const Text('Profile',
                                style: TextStyle(
                                  fontSize: 18,
                                )),
                            onTap: () =>
                                Navigator.pushNamed(context, '/Profile'),
                          ),
                          ListTile(
                              leading: const Icon(FontAwesomeIcons.bell),
                              title: const Text('Notifications',
                                  style: TextStyle(
                                    fontSize: 18,
                                  )),
                              onTap: () => Navigator.pushNamed(
                                  context, '/Notification')),
                          ListTile(
                            leading: const Icon(FontAwesomeIcons.inbox),
                            title: const Text('Messages',
                                style: TextStyle(
                                  fontSize: 18,
                                )),
                            onTap: () => null,
                          ),
                          const ListTile(
                            leading: Icon(FontAwesomeIcons.ccDiscover),
                            title: Text('Discovery',
                                style: TextStyle(
                                  fontSize: 18,
                                )),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(FontAwesomeIcons.gear),
                            title: const Text('Settings',
                                style: TextStyle(
                                  fontSize: 18,
                                )),
                            onTap: () => null,
                          ),
                          ListTile(
                            leading:
                                const Icon(FontAwesomeIcons.magnifyingGlass),
                            title: const Text('Search',
                                style: TextStyle(
                                  fontSize: 18,
                                )),
                            onTap: () => null,
                          ),
                          const Divider(),
                          ListTile(
                              title: const Text('Logout',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.red)),
                              leading: const Icon(
                                  FontAwesomeIcons.solidFaceAngry,
                                  color: Colors.red),
                              onTap: () async {
                                await apiService.logOut();
                                exit(0);
                              }),
                        ],
                      ),
                    )));
          } else if (snapshot.hasError) {
            return const Text('Has error in function');
          }
          return const CircularProgressIndicator();
        });
  }
}
