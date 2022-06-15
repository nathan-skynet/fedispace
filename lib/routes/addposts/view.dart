import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_editor_plus/image_editor_plus.dart';

class View extends StatefulWidget {
  const View({Key? key}) : super(key: key);

  @override
  State<View> createState() => _viewState();
}

class _viewState extends State<View> {
  Uint8List? imageData;

  @override
  void initState() {
    super.initState();
  }

  void loadAsset(String name) async {
    var data = await rootBundle.load(name);
    setState(() => imageData = data.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final arguments = (ModalRoute.of(context)?.settings.arguments ??
        <String, dynamic>{}) as Map;

    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          /// CONTAINER PHOTO / VIDEO
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,

            /// Insert image ici
            child: Image.file(
                fit: BoxFit.cover, File(arguments["file"].toString())),
          ),
          Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 25),
              width: MediaQuery.of(context).size.width,
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: const Icon(FontAwesomeIcons.xmark, size: 65),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: IconButton(
                      onPressed: () async {
                        loadAsset(arguments["file"].toString());
                        Image.memory(imageData!);
                        var editedImage = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageEditor(
                              image: imageData,
                            ),
                          ),
                        );
                        if (editedImage != null) {
                          imageData = editedImage;
                          setState(() {});
                        }
                      },
                      icon: const Icon(
                        FontAwesomeIcons.penToSquare,
                        size: 25,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: const Icon(
                      FontAwesomeIcons.check,
                      size: 65,
                    ),
                  )
                ],
              ))
        ],
      ),
    );
  }
}
