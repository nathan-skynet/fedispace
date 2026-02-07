import 'package:flutter/material.dart';
import 'package:fedispace/widgets/glitch_effect.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Instagram-style notifications page
class NotificationsPage extends StatefulWidget {
  final ApiService apiService;

  const NotificationsPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      appLogger.debug('Loading notifications');
      final response = await widget.apiService.getNotification();
      final List<dynamic> notifications = [];
      
      // Parse notification response
      if (response != null) {
        // TODO: Parse based on actual API response format
        appLogger.debug('Notifications loaded');
      }
      
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      appLogger.error('Error loading notifications', error, stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      final success = await widget.apiService.clearNotifications();
      if (success) {
        setState(() {
          _notifications.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications cleared')),
        );
      }
    } catch (error, stackTrace) {
      appLogger.error('Error clearing notifications', error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
           // Carbon Background
          Container(
              decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage("https://img.freepik.com/free-vector/carbon-fiber-pattern-dark-background_1017-31362.jpg"),
                    fit: BoxFit.cover,
                    opacity: 0.2, // Subtle texture
                  ))),
          
          Column(
            children: [
               // Custom AppBar Area
              Container(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF101010).withOpacity(0.9),
                  border: const Border(bottom: BorderSide(color: Color(0xFF00F3FF), width: 1)),
                  boxShadow: [BoxShadow(color: const Color(0xFF00F3FF).withOpacity(0.2), blurRadius: 15)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Expanded(
                       child: Center(
                         child: const GlitchEffect(
                            child: Text('NOTIFICATIONS', 
                             style: TextStyle(
                               fontFamily: 'Orbitron', 
                               fontSize: 24, 
                               fontWeight: FontWeight.bold, 
                               color: Colors.white,
                               letterSpacing: 2
                             )
                            )
                          ),
                       ),
                     ),
                     if (_notifications.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep, color: Color(0xFFFF00FF)),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF101010),
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(color: Color(0xFF00F3FF)),
                                borderRadius: BorderRadius.circular(10)
                              ),
                              title: const Text('PURGE LOGS?', style: TextStyle(color: Color(0xFF00F3FF), fontFamily: 'Orbitron')),
                              content: const Text('Confirm deletion of all notification protocols.', style: TextStyle(color: Colors.white, fontFamily: 'Rajdhani')),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('ABORT', style: TextStyle(color: Colors.grey, fontFamily: 'Orbitron')),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('PURGE', style: TextStyle(color: Color(0xFFFF00FF), fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            _clearAllNotifications();
                          }
                        },
                      ),
                  ],
                ),
              ),

              // Body
              Expanded(child: _buildBody(true)),
            ],
          ),
        ],
      )
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00F3FF)),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 64,
              color: const Color(0xFF00F3FF).withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'NO NEW SIGNALS',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 2
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comms silence...',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                color: Colors.white.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF00F3FF),
      backgroundColor: Colors.black,
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          // TODO: Create proper notification card based on notification type
          // Using a placeholder card for now
           return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF101010).withOpacity(0.8),
              border: Border(left: BorderSide(color: const Color(0xFFFF00FF), width: 3)), // Neon Pink accent
              boxShadow: [BoxShadow(color: const Color(0xFFFF00FF).withOpacity(0.1), blurRadius: 5)],
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  border: Border.all(color: const Color(0xFFFF00FF).withOpacity(0.5))
                ),
                child: const Icon(Icons.notifications, color: Color(0xFFFF00FF)),
              ),
              title: const Text('INCOMING TRANSMISSION', style: TextStyle(fontFamily: 'Orbitron', color: Colors.white, fontSize: 14)),
              subtitle: Text('Details encrypted...', style: TextStyle(fontFamily: 'Rajdhani', color: Colors.white.withOpacity(0.7))),
            ),
          );
        },
      ),
    );
  }
}
