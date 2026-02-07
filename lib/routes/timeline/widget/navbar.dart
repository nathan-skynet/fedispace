import 'dart:io';
import 'dart:ui';

import 'package:fedispace/core/api.dart';
import 'package:fedispace/models/account.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
                decoration: BoxDecoration(
                  color: const Color(0xFF101010),
                  borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(40),
                      topRight: Radius.circular(30)), // Sharper angles
                  border: Border.all(color: const Color(0xFF00F3FF).withOpacity(0.5), width: 1.5), // Neon Border
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0xFF00F3FF), // Neon glow
                        blurRadius: 10,
                        spreadRadius: 0,
                        blurStyle: BlurStyle.outer),
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                            decoration: const BoxDecoration(
                              color: Color(0xFF101010),
                              border: Border(bottom: BorderSide(color: Color(0xFF00F3FF), width: 2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  account?.displayName ?? "UNKNOWN USER",
                                  style: const TextStyle(
                                    fontFamily: 'Orbitron',
                                    fontSize: 18,
                                    color: Color(0xFF00F3FF),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '@${account?.acct ?? "none"}',
                                  style: const TextStyle(
                                    fontFamily: 'Rajdhani',
                                    fontSize:14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
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
                            onTap: () => Navigator.pushNamed(
                                context, '/DirectMessages'),
                          ),
                          ListTile(
                            leading: const Icon(FontAwesomeIcons.ccDiscover),
                            title: const Text('Discovery',
                                style: TextStyle(
                                  fontSize: 18,
                                )),
                            onTap: () => Navigator.pushNamed(context, '/Local'),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(FontAwesomeIcons.gear),
                            title: const Text('Settings',
                                style: TextStyle(
                                  fontSize: 18,
                                )),
                            onTap: () => Navigator.pushNamed(context, '/Settings'),
                          ),
                          ListTile(
                            leading:
                                const Icon(FontAwesomeIcons.magnifyingGlass),
                            title: const Text('Search',
                                style: TextStyle(
                                  fontSize: 18,
                                )),
                            onTap: () => Navigator.pushNamed(context, '/Search'),
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
