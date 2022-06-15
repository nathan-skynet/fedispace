import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import '../../services/api.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../../widgets/story_widget.dart';


List fileNames = [];

class sendPosts extends StatefulWidget {
  final ApiService apiService;
  const sendPosts({Key? key, required this.apiService}) : super(key: key);
  @override
  State<sendPosts> createState() => _sendPostsState();
}

final myController = TextEditingController();
FocusNode myFocusNode = FocusNode();
bool isSwitched = false;


class _sendPostsState extends State<sendPosts> {

  @override
  void initState() {
    super.initState();
    myController.clear();
    fileNames.clear();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
      children: [
        Container(
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
            ))),

        /// Container for Image
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.3,
          color: Colors.black45,
          child: Row(
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                width: 100,
                height: 150,
                child:  IconButton(
                    icon :  const Icon(FontAwesomeIcons.plus),
                  onPressed: () async {
                    fileNames.clear();
                    final List<AssetEntity>? result =
                    await AssetPicker.pickAssets(context,
                        pickerConfig:
                        const AssetPickerConfig());
                    for (int i = 0; i < result!.length; i++) {
                      final imageName = await result[i].file;
                      print(imageName!.path);
                      setState(() {
                        fileNames.add(imageName.path);
                      });
                    }
                  },
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width - (MediaQuery.of(context).size.width * 0.3) - 3,
                height: MediaQuery.of(context).size.height * 0.3,
                child: fileNames.isNotEmpty ?  foreach() : Container(),
              ),

              /// Reprendre ICI pour la list des fichiers selectionné
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.fromLTRB(
              0, MediaQuery.of(context).size.height * 0.3, 0, 0),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height -
              (MediaQuery.of(context).size.height * 0.3),
          color: Colors.black54,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Text("Contains NSFW Media"),
                  Switch(
                    value: isSwitched,
                    onChanged: (value) {
                      setState(() {
                        isSwitched = value;
                        print(isSwitched);
                      });
                    },
                    activeColor: Colors.redAccent,
                  ),
                ],
              ),
              if (isSwitched == true) ...[
                const TextField(
                  maxLines: 1,
                  minLines: 1,
                  decoration: InputDecoration(
                      hintText: "Add an optional content warning"),
                )
              ],
              const Divider(),
              Expanded(child: Container()),
              TextField(
                controller: myController,
                focusNode: myFocusNode,
                // controller: this._text2,
                maxLines: 3,
                minLines: 3,
                maxLength: 500,
                onTap: (){
                  print("tap");
                  myFocusNode.requestFocus();
                },
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon:  const Icon(FontAwesomeIcons.arrowRight),
                    onPressed: () {
                      setState(() {
                          widget.apiService.apiPostMedia(
                              myController.text.toString(), fileNames);
                          Vibrate.vibrate();
                          Fluttertoast.showToast(
                              msg: "Uploading your post in background mode",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 2,
                              // backgroundColor: Colors.red,
                              // textColor: Colors.white,
                              fontSize: 16.0);
                          Navigator.of(context).pop(false);
                      });
                    },
                  ),
                  labelText: "Write a caption",
                ),
              ),
            ],
          ),
        ),
      ],
    ));
  }



  @override
  void dispose() {
    super.dispose();
    myController.dispose();
  }
}


 foreach() {
    return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemCount: fileNames.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
            width: 40,
            height: 85,

            child: Image.file(
              fit : BoxFit.cover,
              File(fileNames[index]),
            ),
          );
        }
    );
}