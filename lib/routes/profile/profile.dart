import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:fedispace/models/account.dart';
import 'package:fedispace/models/accountUsers.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:video_player/video_player.dart';


var UserAccount;

class Profile extends StatefulWidget {
  final ApiService apiService;

  const Profile({Key? key, required this.apiService}) : super(key: key);

  @override
  State<Profile> createState() => _Profile();
}

class _Profile extends State<Profile> {
  final apiService = ApiService();
  int page = 1;
  Account? account;
  AccountUsers? accountUsers;

  late Object jsonData;
  List<Map<String, dynamic>> arrayOfProducts = [];
  bool isPageLoading = false;

  String getFormattedNumber(int? inputNumber) {
    if (inputNumber == null) return '0';
    if (inputNumber >= 1000000) {
      return "${(inputNumber / 1000000).toStringAsFixed(1)}M";
    } else if (inputNumber >= 10000) {
      return "${(inputNumber / 1000).toStringAsFixed(1)}K";
    }
    return inputNumber.toString();
  }

  Future<Object> fetchAccount() async {
    final arguments = (ModalRoute.of(context)?.settings.arguments ??
        <String, dynamic>{}) as Map;
    if (arguments["id"] != null) {
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

  void makeRebuild() {
    setState(() {});
  }

  Future<List<Map<String, dynamic>>> _callAPIToGetListOfData() async {
    if (isPageLoading == true || (isPageLoading == false && page == 1)) {
      final responseDic;
      if (arrayOfProducts.length == 0) {
        responseDic = await widget.apiService.getUserStatus(UserAccount.id, page, "0");
      } else {
        responseDic = await widget.apiService.getUserStatus(UserAccount.id, page, arrayOfProducts[arrayOfProducts.length - 1]["id"]);
      }
      List<Map<String, dynamic>> temArr = List<Map<String, dynamic>>.from(responseDic);
      if (page == 1) {
        arrayOfProducts = temArr;
      } else {
        arrayOfProducts.addAll(temArr);
      }
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
        if (arrayOfProducts.length >= (16 * page)) {
          page++;
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
            backgroundColor: CyberpunkTheme.backgroundBlack,
            body: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Collapsing app bar with avatar
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor: CyberpunkTheme.backgroundBlack,
                  leading: Navigator.canPop(context)
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                          onPressed: () => Navigator.pop(context),
                        )
                      : null,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, size: 22, color: CyberpunkTheme.textWhite),
                      onPressed: () => Navigator.pushNamed(context, '/Notification'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 22, color: CyberpunkTheme.textWhite),
                      onPressed: () => Navigator.pushNamed(context, '/Settings'),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            CyberpunkTheme.neonCyan.withOpacity(0.10),
                            CyberpunkTheme.backgroundBlack,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Profile info
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar + Stats row
                        Row(
                          children: [
                            // Avatar
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: CyberpunkTheme.neonCyan.withOpacity(0.5),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: CyberpunkTheme.neonCyan.withOpacity(0.2),
                                    blurRadius: 12,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: CircleAvatar(
                                  radius: 36,
                                  backgroundColor: CyberpunkTheme.cardDark,
                                  backgroundImage: CachedNetworkImageProvider(avatarUrl()),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Stats
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatItem(S.of(context).posts, UserAccount.statuses_count),
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, '/FollowersList', arguments: {
                                      'userId': UserAccount.id,
                                      'type': 'followers',
                                    }),
                                    child: _buildStatItem(S.of(context).followers, UserAccount.followers_count),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, '/FollowersList', arguments: {
                                      'userId': UserAccount.id,
                                      'type': 'following',
                                    }),
                                    child: _buildStatItem(S.of(context).following, UserAccount.following_count),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Display name
                        Text(
                          UserAccount?.displayName ?? 'User',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: CyberpunkTheme.textWhite,
                          ),
                        ),

                        const SizedBox(height: 2),

                        // Username
                        Text(
                          '@${UserAccount?.acct ?? ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: CyberpunkTheme.textSecondary,
                          ),
                        ),

                        // Bio
                        if (UserAccount?.note != null && UserAccount.note.toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: html.Html(
                              data: UserAccount.note,
                              style: {
                                "body": html.Style(
                                  margin: html.Margins.zero,
                                  padding: html.HtmlPaddings.zero,
                                  fontSize: html.FontSize(14),
                                  color: CyberpunkTheme.textWhite.withOpacity(0.9),
                                  lineHeight: html.LineHeight(1.4),
                                ),
                                "a": html.Style(
                                  color: CyberpunkTheme.neonCyan,
                                  textDecoration: TextDecoration.none,
                                ),
                              },
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pushNamed(context, '/EditProfile'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: CyberpunkTheme.textWhite,
                                  side: const BorderSide(color: CyberpunkTheme.borderDark),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: Text(S.of(context).editProfile, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Container(height: 0.5, color: CyberpunkTheme.borderDark),
                      ],
                    ),
                  ),
                ),

                // Grid
                SliverToBoxAdapter(
                  child: FutureBuilder(
                    future: _callAPIToGetListOfData(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 2),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 1.5,
                            mainAxisSpacing: 1.5,
                            childAspectRatio: 1,
                          ),
                          itemCount: snapshot.data.length,
                          itemBuilder: (BuildContext context, int index) {
                            final media = snapshot.data[index]["media_attachments"][0];
                            final String url = media["url"];
                            final String type = media["type"] ?? "image";
                            final bool isVideo = type == "video" || type == "gifv";

                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/statusDetail', arguments: {
                                  'statusId': snapshot.data[index]["id"],
                                  'apiService': widget.apiService,
                                });
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  isVideo
                                      ? Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            _ProfileVideoItem(url: url),
                                            const Center(
                                              child: Icon(Icons.play_circle_outline, color: Colors.white, size: 36),
                                            ),
                                          ],
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: url,
                                          placeholder: (context, url) => Container(
                                            color: CyberpunkTheme.cardDark,
                                            child: const Center(child: InstagramLoadingIndicator(size: 16)),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: CyberpunkTheme.cardDark,
                                            child: const Icon(Icons.broken_image_outlined, color: CyberpunkTheme.textTertiary, size: 20),
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                  if ((snapshot.data[index]["media_attachments"] as List).length > 1)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Icon(
                                        Icons.collections_rounded,
                                        color: Colors.white.withOpacity(0.9),
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      } else if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(child: Text(S.of(context).error, style: const TextStyle(color: CyberpunkTheme.textSecondary))),
                        );
                      }
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: InstagramLoadingIndicator(size: 24)),
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: CyberpunkTheme.backgroundBlack,
            body: Center(child: Text(S.of(context).error, style: const TextStyle(color: CyberpunkTheme.textSecondary))),
          );
        }
        return Scaffold(
          backgroundColor: CyberpunkTheme.backgroundBlack,
          body: const Center(child: InstagramLoadingIndicator(size: 32)),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          getFormattedNumber(value),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: CyberpunkTheme.textWhite,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CyberpunkTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ProfileVideoItem extends StatefulWidget {
  final String url;
  const _ProfileVideoItem({Key? key, required this.url}) : super(key: key);

  @override
  State<_ProfileVideoItem> createState() => _ProfileVideoItemState();
}

class _ProfileVideoItemState extends State<_ProfileVideoItem> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        _controller.setVolume(0);
        _controller.seekTo(const Duration(milliseconds: 100));
        _controller.pause();
        if (mounted) {
          setState(() {
            _initialized = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: IgnorePointer(child: VideoPlayer(_controller)),
          ),
        ),
      );
    }
    return Container(
      color: CyberpunkTheme.cardDark,
      child: const Center(child: InstagramLoadingIndicator(size: 16)),
    );
  }
}
