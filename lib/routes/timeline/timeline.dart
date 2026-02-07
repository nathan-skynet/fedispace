// ignore_for_file: non_constant_identifier_names, avoid_print
import 'dart:io';

import 'package:fedispace/core/api.dart';
import 'package:fedispace/models/account.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/routes/timeline/widget/navbar.dart';
import 'package:fedispace/routes/timeline/widget/statusCard/StatusCard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '/widgets/bottomWidget.dart';

class Timeline extends StatefulWidget implements PreferredSizeWidget {
  final ApiService apiService;

  String typeTimeLine;

  /// Main instance of the API service to use in the widget.
  Timeline({Key? key, required this.apiService, required this.typeTimeLine})
      : super(key: key);

  @override
  State<Timeline> createState() => _TimelineTabsState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TimelineTabsState extends State<Timeline> with TickerProviderStateMixin {
  Account? account;
  static const _pageSize = 20;
  late Animation<double> _animation;
  late AnimationController _animationController;

  Future<Object> fetchAccount() async {
    Account currentAccount = await widget.apiService.getCurrentAccount();
    return account = currentAccount;
  }

  late final PagingController<String?, Status> _pagingController = PagingController(
    getNextPageKey: (state) {
      if ((state.pages ?? []).isEmpty) return "";
      final lastPage = state.pages!.last;
      if (lastPage.length < _pageSize) return null;
      return lastPage.last.id;
    },
    fetchPage: (pageKey) async {
       try {
         final key = (pageKey == "" || pageKey == null) ? null : pageKey;
         return await widget.apiService.getStatusList(key, _pageSize, widget.typeTimeLine);
       } catch (error) {
          rethrow;
       }
    },
  );

  Future<bool> _onWillPop() async {
    if (widget.typeTimeLine == "home") {
      return (await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Are you sure?'),
              content: const Text('Do you want to exit an App'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  //<-- SEE HERE
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => exit(0), // <-- SEE HERE
                  child: const Text('Yes'),
                ),
              ],
            ),
          )) ??
          false;
    }
    Navigator.pushReplacementNamed(context, "/TimeLine");
    return false;
  }

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    String typeTimeLine = widget.typeTimeLine;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    final curvedAnimation =
        CurvedAnimation(curve: Curves.easeInOut, parent: _animationController);
    _animation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                image: const DecorationImage(
                  image: NetworkImage("https://img.freepik.com/free-vector/dark-hexagonal-background-with-gradient-color_79603-1409.jpg"), // Hex grid pattern
                  fit: BoxFit.cover,
                  opacity: 0.2, // Subtle background texture
                ),
            ),
            child: Scaffold(
                backgroundColor: Colors.transparent,
                drawer: NavBar(apiService: widget.apiService),
                // AppBar removed for full-screen immersive experience
                extendBody: true,
                body: Builder(
                  builder: (BuildContext scaffoldContext) {
                    return GestureDetector(
                      onHorizontalDragStart: (details) {
                        // Only open drawer if swipe starts from left edge (first 50px)
                        if (details.globalPosition.dx < 50) {
                          Scaffold.of(scaffoldContext).openDrawer();
                        }
                      },
                      behavior: HitTestBehavior.translucent,
                      child: Stack(
                        children: [
                          // Main Content
                          RefreshIndicator(
                            backgroundColor: Colors.yellowAccent,
                            onRefresh: () => Future.sync(_pagingController.refresh),
                            child: ValueListenableBuilder<PagingState<String?, Status>>(
                              valueListenable: _pagingController,
                              builder: (context, state, child) => PagedListView<String?, Status>(
                                state: state,
                                fetchNextPage: _pagingController.fetchNextPage,
                                physics: const ClampingScrollPhysics(),
                                builderDelegate: PagedChildBuilderDelegate<Status>(
                                  itemBuilder: (context, item, index) => StatusCard(
                                    item,
                                    apiService: widget.apiService,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Floating Menu Button (Top-Left)
                          Positioned(
                            top: 40,
                            left: 16,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF101010).withOpacity(0.8),
                                border: Border.all(color: const Color(0xFF00F3FF), width: 1.5),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00F3FF).withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                  )
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.menu, color: Color(0xFF00F3FF), size: 28),
                                onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.endFloat,

                //Init Floating Action Bubble
                bottomNavigationBar: widget.typeTimeLine == 'home'
                    ? bottomWidget(apiService: widget.apiService, page: 0)
                    : bottomWidget(apiService: widget.apiService, page: 1))));
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
