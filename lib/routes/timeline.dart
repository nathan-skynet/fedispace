// ignore_for_file: non_constant_identifier_names, avoid_print
import 'dart:io';

import 'package:fedispace/data/account.dart';
import 'package:fedispace/data/status.dart';
import 'package:fedispace/services/api.dart';
import 'package:fedispace/widgets/StatusCard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../widgets/bottomWidget.dart';
import 'navbar.dart';

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

  /// If called, requests a new page of statuses from the Mastodon API.
  Future<void> _fetchPage(String? lastStatusId, String typeTimeLine) async {
    try {
      final List<Status> newStatuses = await widget.apiService
          .getStatusList(lastStatusId, _pageSize, typeTimeLine);
      final isLastPage = newStatuses.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newStatuses);
      } else {
        final nextPageKey = newStatuses.last.id;
        _pagingController.appendPage(newStatuses, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  final PagingController<String?, Status> _pagingController = PagingController(
    firstPageKey: null,
    invisibleItemsThreshold: 10,
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

    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey, typeTimeLine);
    });
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
                gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Colors.lightBlue,
                Colors.red.shade900,
                Colors.blue.shade800,
              ],
            )),
            child: Scaffold(
                backgroundColor: Colors.transparent,
                drawer: NavBar(apiService: widget.apiService),
                // appBar: HeaderWidget(apiService: widget.apiService),
                extendBody: true,
                body: RefreshIndicator(
                  backgroundColor: Colors.yellowAccent,
                  onRefresh: () => Future.sync(_pagingController.refresh),
                  child: PagedListView<String?, Status>(
                    pagingController: _pagingController,
                    physics: const ClampingScrollPhysics(),
                    builderDelegate: PagedChildBuilderDelegate<Status>(
                      itemBuilder: (context, item, index) => StatusCard(
                        item,
                        apiService: widget.apiService,
                      ),
                    ),
                  ),
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
