import 'dart:io';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/models/account.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

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
            width: 260,
            decoration: BoxDecoration(
              color: CyberpunkTheme.surfaceDark,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border(
                right: BorderSide(color: CyberpunkTheme.neonCyan.withOpacity(0.15), width: 1),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: CyberpunkTheme.neonCyan.withOpacity(0.4), width: 1.5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: CyberpunkTheme.cardDark,
                              backgroundImage: account?.avatarUrl != null && account!.avatarUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(avatarurl())
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account?.displayName ?? 'User',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: CyberpunkTheme.textWhite,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '@${account?.acct ?? ''}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: CyberpunkTheme.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Container(height: 0.5, color: CyberpunkTheme.borderDark),
                  
                  // Menu Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _DrawerItem(
                          icon: Icons.person_outline_rounded,
                          label: 'Profile',
                          onTap: () => Navigator.pushNamed(context, '/Profile'),
                        ),
                        _DrawerItem(
                          icon: Icons.notifications_none_rounded,
                          label: 'Notifications',
                          onTap: () => Navigator.pushNamed(context, '/Notification'),
                        ),
                        _DrawerItem(
                          icon: Icons.mail_outline_rounded,
                          label: 'Messages',
                          onTap: () => Navigator.pushNamed(context, '/DirectMessages'),
                        ),
                        _DrawerItem(
                          icon: Icons.explore_outlined,
                          label: 'Discovery',
                          onTap: () => Navigator.pushNamed(context, '/Local'),
                        ),
                        _DrawerItem(
                          icon: Icons.search_rounded,
                          label: 'Search',
                          onTap: () => Navigator.pushNamed(context, '/Search'),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Container(height: 0.5, color: CyberpunkTheme.borderDark),
                        ),
                        
                        _DrawerItem(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          onTap: () => Navigator.pushNamed(context, '/Settings'),
                        ),
                      ],
                    ),
                  ),
                  
                  Container(height: 0.5, color: CyberpunkTheme.borderDark),
                  
                  // Logout
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    color: const Color(0xFFFF4757),
                    onTap: () async {
                      await apiService.logOut();
                      exit(0);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Container(
            width: 260,
            color: CyberpunkTheme.surfaceDark,
            child: const Center(
              child: Text('Error loading menu', style: TextStyle(color: CyberpunkTheme.textSecondary)),
            ),
          );
        }
        return Container(
          width: 260,
          color: CyberpunkTheme.surfaceDark,
          child: const Center(child: CircularProgressIndicator(color: CyberpunkTheme.neonCyan)),
        );
      },
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: CyberpunkTheme.neonCyan.withOpacity(0.05),
        highlightColor: CyberpunkTheme.neonCyan.withOpacity(0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color ?? CyberpunkTheme.textSecondary),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color ?? CyberpunkTheme.textWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
