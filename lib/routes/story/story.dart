import 'package:advstory/advstory.dart';
import 'package:fedispace/core/api.dart';
import 'package:flutter/material.dart';

class stroryViewer extends StatefulWidget {
  const stroryViewer({Key? key, required this.apiService}) : super(key: key);
  final ApiService apiService;

  @override
  State<stroryViewer> createState() => _stroryViewerState();
}

class _stroryViewerState extends State<stroryViewer> {
  @override
  Widget build(BuildContext context) {
    return AdvStory(
      storyCount: 5,
      storyBuilder: (storyIndex) => Story(
        contentCount: 10,
        contentBuilder: (contentIndex) => const ImageContent(url: ""),
      ),
      trayBuilder: (index) => AdvStoryTray(url: ""),
    );
  }
}
