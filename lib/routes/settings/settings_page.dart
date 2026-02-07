import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';

/// Instagram-style settings page
class SettingsPage extends StatefulWidget {
  final ApiService apiService;

  const SettingsPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _privateAccount = false;

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        appLogger.info('User logging out');
        await widget.apiService.resetApiServiceState();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/Login',
            (route) => false,
          );
        }
      } catch (error, stackTrace) {
        appLogger.error('Error during logout', error, stackTrace);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Account'),
          _buildListTile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () {
              Navigator.pushNamed(context, '/EditProfile');
            },
          ),
          _buildListTile(
            icon: Icons.lock_outline,
            title: 'Privacy',
            trailing: Switch(
              value: _privateAccount,
              onChanged: (value) {
                setState(() {
                  _privateAccount = value;
                });
                // TODO: Update privacy settings via API
              },
            ),
          ),
          const InstagramDivider(),
          
          _buildSectionHeader('Notifications'),
          _buildListTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                // TODO: Update notification settings
              },
            ),
          ),
          const InstagramDivider(),
          
          _buildSectionHeader('Content'),
          _buildListTile(
            icon: Icons.bookmark_outline,
            title: 'Saved Posts',
            onTap: () {
              Navigator.pushNamed(context, '/Bookmarks');
            },
          ),
          _buildListTile(
            icon: Icons.favorite_outline,
            title: 'Liked Posts',
            onTap: () {
              Navigator.pushNamed(context, '/LikedPosts');
            },
          ),
          _buildListTile(
            icon: Icons.history,
            title: 'Archive',
            onTap: () {
              // TODO: Navigate to archive
              appLogger.debug('Archive tapped');
            },
          ),
          const InstagramDivider(),
          
          _buildSectionHeader('About'),
          _buildListTile(
            icon: Icons.info_outline,
            title: 'About FediSpace',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'FediSpace',
                applicationVersion: '2.0.0',
                applicationLegalese: '© 2024 FediSpace',
                children: [
                  const SizedBox(height: 16),
                  const Text('A modern Pixelfed client for Flutter'),
                ],
              );
            },
          ),
          _buildListTile(
            icon: Icons.code,
            title: 'Instance',
            subtitle: widget.apiService.getInstanceUrl() ?? 'Not connected',
          ),
          const InstagramDivider(),
          
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF262626)
                    : const Color(0xFFEFEFEF),
                foregroundColor: Colors.red,
                elevation: 0,
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFA8A8A8) : const Color(0xFF8E8E8E),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFA8A8A8)
                    : const Color(0xFF8E8E8E),
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, size: 20)
              : null),
      onTap: onTap,
    );
  }
}
