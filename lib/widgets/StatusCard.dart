// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_share_me/flutter_share_me.dart';
import 'package:flutter_html/shims/dart_ui_real.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:zoom_pinch_overlay/zoom_pinch_overlay.dart';
import 'package:full_screen_image_null_safe/full_screen_image_null_safe.dart';
import 'package:video_viewer/video_viewer.dart';
import 'package:like_button/like_button.dart';

import 'package:carousel_slider/carousel_slider.dart';

import 'package:fedispace/widgets/LikedByStatusCard.dart';
import 'package:fedispace/widgets/HeaderStatusCard.dart';
import 'package:fedispace/data/favourited.dart';
import 'package:fedispace/utils/messages.dart';
import 'package:fedispace/services/api.dart';
import 'package:fedispace/data/status.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StatusCard extends StatefulWidget {
  final ApiService apiService;
  final Status initialStatus;
  const StatusCard(
    this.initialStatus, {
    Key? key,
    required this.apiService,
  }) : super(key: key);

  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard> {
  /// The [Status] instance that will be displayed with this widget.
  late Status status;
  final VideoViewerController controller = VideoViewerController();
  final AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    status = widget.initialStatus;
    super.initState();
  }

  static String stripHtmlIfNeeded(String text) {
    // The regular expression is simplified for an HTML tag (opening or
    // closing) or an HTML escape. We might want to skip over such expressions
    // when estimating the text directionality.
    return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
  }

  Future<List<Favourited>> fetchFavour(id) async {
    final response = await widget.apiService.GetRepliesBy(id);
    final parsedJson = json.decode(response).cast<Map<String, dynamic>>();
    return parsedJson
        .map<Favourited>((json) => Favourited.fromJson(json))
        .toList();
  }

  /// Makes a call unto the Mastodon API in order to (un)favorite the current
  /// toot, and updates the toot's state in the current widget accordingly.
  Future<bool> onFavoritePress(bool isLiked) async {
    Status newStatus;
    try {
      String audioasset = "assets/sounds/soundtrack1.wav";
      ByteData bytes =
          await rootBundle.load(audioasset); //load sound from assets
      Uint8List soundbytes =
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
      int result = await player.playBytes(soundbytes);
      if (result == 1) {
        //play success
        print("Sound playing successful.");
      } else {
        print("Error while playing sound.");
      }
      if (status.favorited) {
        newStatus = await widget.apiService.undoFavoriteStatus(status.id);
      } else {
        newStatus = await widget.apiService.favoriteStatus(status.id);
      }
      setState(() {
        status = newStatus;
      });
      return !isLiked;
    } on ApiException {
      showSnackBar(
        context,
        "We couldn't perform that action, please try again!",
      );
      return !isLiked;
    }
  }

  Future<void> onFavorite() async {
    Status newStatus;
    try {
      String audioasset = "assets/sounds/soundtrack1.wav";
      ByteData bytes =
          await rootBundle.load(audioasset); //load sound from assets
      Uint8List soundbytes =
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
      int result = await player.playBytes(soundbytes);
      if (result == 1) {
        //play success
        print("Sound playing successful.");
      } else {
        print("Error while playing sound.");
      }
      if (status.favorited) {
        newStatus = await widget.apiService.undoFavoriteStatus(status.id);
      } else {
        newStatus = await widget.apiService.favoriteStatus(status.id);
      }
      setState(() {
        //status = newStatus;
      });
    } on ApiException {
      showSnackBar(
        context,
        "We couldn't perform that action, please try again!",
      );
    }
  }

  Future<void> onReblogPress() async {
    Status newStatus;
    int temp = status.reblogs_count;

    try {
      if (status.reblogged == true) {
        newStatus = await widget.apiService.undoBoostStatus(status.id);
      } else {
        newStatus = await widget.apiService.boostStatus(status.id);
      }
      setState(() {
        status = newStatus;
      });
    } on ApiException {
      showSnackBar(
        context,
        "We couldn't perform that action, please try again!",
      );
      return;
    }
  }

  final FlutterShareMe flutterShareMe = FlutterShareMe();

  late Uint8List imageDataBytes;

  @override
  Widget build(BuildContext context) {
    // TODO: display more information on each status
    // TODO: main text color (Colors.white) should change depending on theme
    print(status.muted);
    if (status.sensitive != true && status.muted != true) {
      return Container(
        width: MediaQuery.of(context).size.width - 0,
        padding: const EdgeInsets.all(0.0),
        child: Card(
          elevation: 10,
          color: Colors.grey.shade700,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.black54, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Column(
            children: [
              HeaderStatusCard(
                  postsAccount: status.account,
                  created_at: status.created_at,
                  apiService: widget.apiService),

              /// IF MEDIA ATTACHEMENT != 1
              if (status.attachement.length != 1) ...[
                CarouselSlider.builder(
                  itemCount: status.attachement.length,
                  options: CarouselOptions(
                    height: 300,
                    autoPlay: true,
                    aspectRatio: 2.0,
                    enlargeCenterPage: true,
                  ),
                  itemBuilder: (context, index, realIdx) {
                    /// IF MEDIA ATTACHAMENT IS [VIDEO] AND LENGTH != 1
                    if (status.attachement[index]["url"].contains(".mp4")) {
                      return VideoViewer(
                        enableVerticalSwapingGesture: false,
                        enableHorizontalSwapingGesture: false,
                        onFullscreenFixLandscape: false,
                        style: VideoViewerStyle(
                        ),
                        controller: controller,
                        source: {
                          status.attach: VideoSource(
                            video: VideoPlayerController.network(
                              status.attachement[index]["url"],
                            ),
                          )
                        },
                      );
                    } else {
                      /// IF MEDIA ATTACHEMENT IS [IMAGE] AND LENGTH != 1
                      return FullScreenWidget(
                          child: Hero(
                              tag: Random().nextInt(10000).toString(),
                              child: ClipRRect(
                                  // TODO NEED UPDATE CODE AND SEE LOG !!! APP CRASH
                                  //child : ZoomOverlay(
                                  //   minScale: 0.0, // Optional
                                  //   maxScale: 6.0, // Optional
                                  //   twoTouchOnly: true, // Defaults to false
                                  child: CachedNetworkImage(
                                      imageUrl: status.attachement[index]
                                          ["url"],
                                      placeholder: (context, url) => BlurHash(
                                          hash: status.attachement[index]
                                              ["blurhash"]),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                      imageBuilder: (context, imageProvider) =>
                                          Container(
                                              margin: const EdgeInsets
                                                      .symmetric(
                                                  horizontal: 0,
                                                  vertical:
                                                      5), //apply padding horizontal or vertical only
                                              width: 490,
                                              height: 290,
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: imageProvider,
                                                  fit: BoxFit.cover,
                                                ),
                                              )))
                                  //  )
                                  )));
                    }
                  },
                ),
              ] else ...[
                /// IF [VIDEO] POSTS AND [LENGTH] == 1
                if (status.attach.contains(".mp4")) ...[
                  Container(
                    width: 490,
                    height: 290,
                    child: VideoViewer(
                      enableVerticalSwapingGesture: false,
                      enableHorizontalSwapingGesture: false,
                      onFullscreenFixLandscape: false,
                      style: VideoViewerStyle(
                        thumbnail: Container(
                          child: Container(),
                        ),
                      ),
                      controller: controller,
                      source: {
                        status.attach: VideoSource(
                            video: VideoPlayerController.network(status.attach))
                      },
                    ),
                  )
                ] else ...[
                  /// ELSE [PHOTO] POSTS AND [LENGTH] == 1
                  FullScreenWidget(
                      child: Hero(
                          tag: Random().nextInt(100000).toString(),
                          child: ClipRRect(
                              child: ZoomOverlay(
                                  minScale: 0.5, // Optional
                                  maxScale: 3.0, // Optional
                                  twoTouchOnly: true, // Defaults to false
                                  child: CachedNetworkImage(
                                      imageUrl: status.attach,
                                      placeholder: (context, url) => Container(
                                            width: 490,
                                            height: 290,
                                            child: BlurHash(
                                                hash: status.blurhash!),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                      imageBuilder: (context, imageProvider) =>
                                          Container(
                                              margin: const EdgeInsets
                                                      .symmetric(
                                                  horizontal: 0,
                                                  vertical:
                                                      5), //apply padding horizontal or vertical only
                                              width: 490,
                                              height: 290,
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: imageProvider,
                                                  fit: BoxFit.cover,
                                                ),
                                              )))))))
                ],
              ],

              Row(
                children: [
                  Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 0)),
                  LikeButton(
                    circleColor: const CircleColor(
                        start: Color(0xff00ddff), end: Color(0xff0099cc)),
                    bubblesColor: const BubblesColor(
                      dotPrimaryColor: Color(0xff33b5e5),
                      dotSecondaryColor: Color(0xff0099cc),
                    ),
                    isLiked: status.favorited,
                    likeCount: null,
                    onTap: onFavoritePress,
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(FontAwesomeIcons.commentDots),
                  ),
                  Expanded(child: Container()),
                  IconButton(
                    onPressed: onReblogPress,
                    tooltip: "Reblog",
                    icon: status.reblogged == true
                        ? const Icon(FontAwesomeIcons.repeat)
                        : const Icon(FontAwesomeIcons.repeat),
                    color: status.reblogged ? Colors.green : null,
                  ),
                  status.replies_count != 0
                      ? Text(status.reblogs_count.toString())
                      : Container(),
                  IconButton(
                      onPressed: () async {
                        await flutterShareMe.shareToSystem(msg: status.url);
                      },
                      tooltip: "Share",
                      icon: const Icon(FontAwesomeIcons.shareNodes)),
                ],
              ),
              FutureBuilder<List>(
                  future: fetchFavour(status.id),
                  builder:
                      (BuildContext context, AsyncSnapshot<List> snapshot) {
                    if (snapshot.data != null) {
                      return likedByStatusCard(
                          posts: status,
                          apiService: widget.apiService,
                          likedby: snapshot.data);
                    } else if (snapshot.hasError) {}
                    return Container();
                  }),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(width: 5),
                        Expanded(
                          child: Html(
                            data: status.content,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    status.replies_count != 0
                        ? Text(
                            'See ${status.replies_count.toString()} comments',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade400),
                          )
                        : Container(),
                    Container(),
                    const SizedBox(height: 15),
                  ],
                ),
              )
            ],
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}
