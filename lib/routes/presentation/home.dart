import 'package:flutter/material.dart';
import 'package:fedispace/l10n/app_localizations.dart';
import 'package:intro_slider/intro_slider.dart';

class presentation extends StatefulWidget {
  const presentation({Key? key}) : super(key: key);

  @override
  State<presentation> createState() => _presentationState();
}

class _presentationState extends State<presentation> {

  void onDonePress() {
    Navigator.of(context).pop(false);
    print("End of slides");
  }

  @override
  Widget build(BuildContext context) {
    final l = S.of(context);
    final slides = <ContentConfig>[
      ContentConfig(
        title: l.presentPixelfedTitle,
        description: l.presentPixelfedDesc,
        pathImage: "assets/images/pixelfed.png",
        backgroundColor: const Color(0xfff5a623),
      ),
      ContentConfig(
        title: l.presentFediverseTitle,
        description: l.presentFediverseDesc,
        pathImage: "assets/images/fediverse.png",
        backgroundColor: const Color(0xff203152),
      ),
      ContentConfig(
        title: l.presentPrivacyTitle,
        description: l.presentPrivacyDesc,
        pathImage: "assets/images/privacy.png",
        backgroundColor: const Color(0xff9932CC),
      ),
    ];

    return IntroSlider(
      listContentConfig: slides,
      onDonePress: onDonePress,
    );
  }
}
