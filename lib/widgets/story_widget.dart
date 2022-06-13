// import 'dart:ui';

import 'package:flutter/material.dart';

class StoryWidget extends StatelessWidget {
  StoryWidget({Key? key}) : super(key: key);

  final List storyItems = [
    {
      "pseudo": 'painStop',
      "photo": "assets/images/photo/photo-1.jpeg",
    },
    {
      "pseudo": 'sonTomato',
      "photo": "assets/images/photo/photo-2.jpeg",
    },
    {
      "pseudo": 'dramaLove',
      "photo": "assets/images/photo/photo-3.jpeg",
    },
    {
      "pseudo": 'moonTomato',
      "photo": "assets/images/photo/photo-4.jpeg",
    },
    {
      "pseudo": 'tvIt\'s',
      "photo": "assets/images/photo/photo-5.jpeg",
    },
    {
      "pseudo": 'moodPrety',
      "photo": "assets/images/photo/photo-7.jpeg",
    },
    {
      "pseudo": 'callofCallof',
      "photo": "assets/images/photo/photo-8.jpeg",
    },
    {
      "pseudo": 'flyLike',
      "photo": "assets/images/photo/photo-9.jpeg",
    },
    {
      "pseudo": 'amourOnemore',
      "photo": "assets/images/photo/photo-10.jpeg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: storyItems.map((story) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/images/story-circle.png',
                      height: 70,
                    ),
                    Image.asset(
                      'assets/images/story-circle.png',
                      height: 68,
                    ),
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 30,
                      backgroundImage: NetworkImage(
                          "http://pix.echelon4.space/storage/avatars/042/944/987/111/835/648/1/nfnuRTNqZXPDofTrALBM_avatar.jpg?v=14"
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  story['pseudo'],
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
