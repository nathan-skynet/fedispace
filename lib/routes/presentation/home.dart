import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';

class presentation extends StatefulWidget {
  const presentation({Key? key}) : super(key: key);

  @override
  State<presentation> createState() => _presentationState();
}

class _presentationState extends State<presentation> {
  List<ContentConfig> slides = [];

  @override
  void initState() {
    super.initState();

    slides.add(
      ContentConfig(
        title: "Pixelfed",
        description:
            "Pixelfed is an image sharing system in the form of free software, using the ActivityPub protocol, to federate with the Fediverse.",
        pathImage: "assets/images/pixelfed.png",
        backgroundColor: const Color(0xfff5a623),
      ),
    );
    slides.add(
      ContentConfig(
        title: "Fediverse",
        description:
            "The Fediverse is a giant Network of social media platforms. There are platforms for microblogging, blogging, photoblogging, videohosting and much more and they are all interconnected or federated. So you only need one account to follow users on any of the platforms.",
        pathImage: "assets/images/fediverse.png",
        backgroundColor: const Color(0xff203152),
      ),
    );
    slides.add(
      ContentConfig(
        title: "Privacy",
        description: "Ad free, Open Source, Your data's is YOUR data's",
        pathImage: "assets/images/privacy.png",
        backgroundColor: const Color(0xff9932CC),
      ),
    );
  }

  void onDonePress() {
    Navigator.of(context).pop(false);
    print("End of slides");
  }

  @override
  Widget build(BuildContext context) {
    return IntroSlider(
      listContentConfig: slides,
      onDonePress: onDonePress,
    );
  }
}
