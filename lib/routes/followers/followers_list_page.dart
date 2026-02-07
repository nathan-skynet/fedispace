import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/models/accountUsers.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Instagram-style followers/following list page
class FollowersListPage extends StatefulWidget {
  final ApiService apiService;
  final String userId;
  final bool isFollowers; // true for followers, false for following

  const FollowersListPage({
    Key? key,
    required this.apiService,
    required this.userId,
    required this.isFollowers,
  }) : super(key: key);

  @override
  State<FollowersListPage> createState() => _FollowersListPageState();
}

class _FollowersListPageState extends State<FollowersListPage> {
  List<AccountUsers> _accounts = [];
  bool _isLoading = true;
  String? _nextPageId;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts({String? maxId}) async {
    try {
      appLogger.debug(
          'Loading ${widget.isFollowers ? 'followers' : 'following'}: ${widget.userId}');
      
      final List<AccountUsers> accounts;
      if (widget.isFollowers) {
        accounts = await widget.apiService.getFollowers(
          widget.userId,
          maxId: maxId,
        );
      } else {
        accounts = await widget.apiService.getFollowing(
          widget.userId,
          maxId: maxId,
        );
      }

      setState(() {
        if (maxId == null) {
          _accounts = accounts;
        } else {
          _accounts.addAll(accounts);
        }
        _nextPageId = accounts.isNotEmpty ? accounts.last.id : null;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      appLogger.error('Error loading accounts', error, stackTrace);
      setState(() {
        _isLoading = false;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFollowers ? 'Followers' : 'Following'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: InstagramLoadingIndicator(size: 32));
    }

    if (_accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black54,
            ),
            const SizedBox(height: 16),
            Text(
              widget.isFollowers ? 'No Followers' : 'Not Following Anyone',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _accounts.length + (_nextPageId != null ? 1 : 0),
      separatorBuilder: (context, index) => const InstagramDivider(),
      itemBuilder: (context, index) {
        if (index == _accounts.length) {
          // Load more button
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: TextButton(
                onPressed: () => _loadAccounts(maxId: _nextPageId),
                child: const Text('Load More'),
              ),
            ),
          );
        }

        final account = _accounts[index];
        return _UserListItem(
          account: account,
          onTap: () => _navigateToProfile(account),
        );
      },
    );
  }
}

class _UserListItem extends StatefulWidget {
  final AccountUsers account;
  final VoidCallback onTap;

  const _UserListItem({
    Key? key,
    required this.account,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_UserListItem> createState() => _UserListItemState();
}

class _UserListItemState extends State<_UserListItem> {
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.account.following ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: GestureDetector(
        onTap: widget.onTap,
        child: CircleAvatar(
          radius: 24,
          backgroundImage: widget.account.avatar.isNotEmpty
              ? CachedNetworkImageProvider(widget.account.avatar)
              : null,
          child: widget.account.avatar.isEmpty
              ? const Icon(Icons.person, size: 24)
              : null,
        ),
      ),
      title: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.account.username,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      subtitle: widget.account.display_name.isNotEmpty
          ? GestureDetector(
              onTap: widget.onTap,
              child: Text(
                widget.account.display_name,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFA8A8A8)
                      : const Color(0xFF8E8E8E),
                ),
              ),
            )
          : null,
      trailing: SizedBox(
        width: 100,
        child: InstagramFollowButton(
          isFollowing: _isFollowing,
          onPressed: () {
            setState(() {
              _isFollowing = !_isFollowing;
            });
            // TODO: Call API to follow/unfollow
          },
        ),
      ),
    );
  }
}
