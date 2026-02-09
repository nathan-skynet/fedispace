import 'package:cached_network_image/cached_network_image.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/models/story.dart';
import 'package:fedispace/routes/post/takecamera.dart';
import 'package:fedispace/widgets/story_viewer.dart';
import 'package:flutter/material.dart';

class StoryBar extends StatefulWidget {
  final ApiService apiService;

  const StoryBar({Key? key, required this.apiService}) : super(key: key);

  @override
  State<StoryBar> createState() => _StoryBarState();
}

class _StoryBarState extends State<StoryBar> {
  List<Story> _stories = [];
  bool _isLoading = true;
  Story? _myStory;

  @override
  void initState() {
    super.initState();
    _fetchStories();
  }

  Future<void> _fetchStories() async {
    try {
      final carousel = await widget.apiService.getStoryCarousel();

      if (mounted) {
        setState(() {
          _myStory = carousel.self;
          _stories = carousel.others;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // Fail silently for stories
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 1 + _stories.length, // +1 for "My Story" / "Add Story"
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildMyStoryAvatar();
          }
          return _buildStoryAvatar(_stories[index - 1]);
        },
      ),
    );
  }

  Widget _buildMyStoryAvatar() {
    final hasStory = _myStory != null && _myStory!.items.isNotEmpty;
    
    return GestureDetector(
      onTap: () {
        if (hasStory) {
          // Open Story Viewer
          Navigator.pushNamed(context, '/StoryViewer', arguments: {'story': _myStory});
        } else {
          // Open Camera to create story
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CameraScreen(
                apiService: widget.apiService,
                isStoryMode: true,
              ),
            ),
          ).then((_) => _fetchStories()); // Refresh after return
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: hasStory 
                      ? Border.all(color: Colors.cyanAccent, width: 2)
                      : null,
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: widget.apiService.currentAccount?.avatar != null
                        ? CachedNetworkImageProvider(widget.apiService.currentAccount!.avatar)
                        : null,
                    backgroundColor: Colors.grey[800],
                  ),
                ),
                if (!hasStory)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, size: 16, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              "Your Story",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryAvatar(Story story) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/StoryViewer', arguments: {'story': story});
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.orange],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2), // White border between gradient and image
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black, 
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: CachedNetworkImageProvider(story.account.avatar),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              story.account.username,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
