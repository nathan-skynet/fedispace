// ignore_for_file: non_constant_identifier_names, avoid_print
import 'dart:io';

import 'package:fedispace/core/api.dart';
import 'package:fedispace/models/status.dart';
import 'package:fedispace/routes/timeline/widget/statusCard/StatusCard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class TagTimeline extends StatefulWidget {
  final ApiService apiService;
  final String tag;

  const TagTimeline({Key? key, required this.apiService, required this.tag})
      : super(key: key);

  @override
  State<TagTimeline> createState() => _TagTimelineState();
}

class _TagTimelineState extends State<TagTimeline> {
  static const _pageSize = 20;

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
         return await widget.apiService.getTimelineTag(widget.tag, key, _pageSize);
       } catch (error) {
          rethrow;
       }
    },
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            appBar: AppBar(
              title: Text('#${widget.tag}', style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              flexibleSpace: Container(
                  decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: const Color(0xFF00F3FF).withOpacity(0.3), width: 1))
                  ),
              ),
            ),
            body: RefreshIndicator(
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
                    firstPageErrorIndicatorBuilder: (context) => Center(
                      child: Text('Error: ${_pagingController.error}'),
                    ),
                    noItemsFoundIndicatorBuilder: (context) => Center(
                      child: Text('No posts found for #${widget.tag}'),
                    ),
                  ),
                ),
              ),
            )
        )
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
