import 'package:flutter/material.dart';
import 'package:fedispace/widgets/glitch_effect.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/models/accountUsers.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Instagram-style search and discovery page
class SearchPage extends StatefulWidget {
  final ApiService apiService;

  const SearchPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<AccountUsers> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      appLogger.debug('Searching for: $query');
      final results = await widget.apiService.searchAccounts(query, limit: 50);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (error, stackTrace) {
      appLogger.error('Search error', error, stackTrace);
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _navigateToProfile(AccountUsers account) {
    Navigator.pushNamed(
      context,
      '/UserProfile',
      arguments: {'userId': account.id},
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Center(
                       child: const GlitchEffect(
                         child: Text('SEARCH PROTOCOL', 
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
                     const SizedBox(height: 20),
                     // Cyberpunk Search Bar
                     Container(
                       decoration: BoxDecoration(
                         color: Colors.black.withOpacity(0.5),
                         border: Border.all(color: const Color(0xFF00F3FF).withOpacity(0.5)),
                         borderRadius: BorderRadius.circular(5),
                         boxShadow: [BoxShadow(color: const Color(0xFF00F3FF).withOpacity(0.1), blurRadius: 5)]
                       ),
                       child: TextField(
                         controller: _searchController,
                         style: const TextStyle(color: Color(0xFF00F3FF), fontFamily: 'Rajdhani', fontSize: 18),
                         decoration: InputDecoration(
                           hintText: 'ENTER USER_ID...',
                           hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5), fontFamily: 'Rajdhani'),
                           prefixIcon: const Icon(Icons.search, color: Color(0xFF00F3FF)),
                           border: InputBorder.none,
                           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                         ),
                         onSubmitted: _performSearch,
                         onChanged: (value) {
                            if (value.length >= 2) {
                              Future.delayed(const Duration(milliseconds: 500), () {
                                if (_searchController.text == value) {
                                  _performSearch(value);
                                }
                              });
                            }
                         },
                       ),
                     )
                  ],
                ),
              ),

              // Results
              Expanded(child: _buildBody(true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00F3FF)),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.travel_explore,
              size: 80,
              color: Color(0xFF00F3FF),
            ),
            const SizedBox(height: 16),
            const Text(
              'AWAITING INPUT',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 20,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Initialize search sequence...',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 16,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'NO DATA FOUND',
              style: TextStyle(fontFamily: 'Orbitron', fontSize: 20, color: Colors.red),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final account = _searchResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF101010).withOpacity(0.8),
            border: Border.all(color: const Color(0xFF00F3FF).withOpacity(0.3)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: _UserListItem(
            account: account,
            onTap: () => _navigateToProfile(account),
          ),
        );
      },
    );
  }
}

class _UserListItem extends StatelessWidget {
  final AccountUsers account;
  final VoidCallback onTap;

  const _UserListItem({
    Key? key,
    required this.account,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF00F3FF), width: 1.5),
          boxShadow: [BoxShadow(color: const Color(0xFF00F3FF).withOpacity(0.4), blurRadius: 8)]
        ),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.black,
          backgroundImage: account.avatar.isNotEmpty
              ? CachedNetworkImageProvider(account.avatar)
              : null,
          child: account.avatar.isEmpty
              ? const Icon(Icons.person, size: 24, color: Color(0xFF00F3FF))
              : null,
        ),
      ),
      title: Text(
        account.username,
        style: const TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      subtitle: account.display_name.isNotEmpty
          ? Text(
              account.display_name,
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            )
          : null,
      trailing: account.followers_count != null
          ? Text(
              '${account.followers_count} UNITS',
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 12,
                color: Color(0xFFFF00FF), // Neon Pink for stats
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
