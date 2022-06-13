import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class View extends StatefulWidget {
  const View({Key? key}) : super(key: key);

  @override
  State<View> createState() => _viewState();
}

class _viewState extends State<View> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment : Alignment.bottomCenter,
      children: [
        /// CONTAIRE PHOTO / VIDEO
         Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 25),
          width: MediaQuery.of(context).size.width,
          height: 100,
          color : Colors.black,
            child : Row(
              crossAxisAlignment : CrossAxisAlignment.center,
              mainAxisAlignment : MainAxisAlignment.center,
              children: [

              SizedBox(
                width: MediaQuery.of(context).size.width * 0.3,
                child: const Icon(FontAwesomeIcons.xmark,size : 65
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.3,
                child: const Icon(FontAwesomeIcons.penToSquare,
                  size : 25,
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.3,
                child: const Icon(FontAwesomeIcons.check,
                    size : 65,
                ),
              )
            ],)
        )
      ],
    );
  }
}
