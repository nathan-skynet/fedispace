import 'package:fedispace/core/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_social_textfield/flutter_social_textfield.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class Desc extends StatefulWidget {
  final ApiService apiService;

  const Desc({Key? key, required this.apiService}) : super(key: key);

  @override
  State<Desc> createState() => _DescState();
}

final _myController = SocialTextEditingController();
List<String> fileNames = [];

class _DescState extends State<Desc> {
  @override
  void initState() {
    super.initState();
    final _myController = SocialTextEditingController();

    _myController.clear();
    fileNames.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              width: MediaQuery.of(context).size.width,
              child: Row(
                children: [
                  SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: Stack(
                        alignment: AlignmentDirectional.topEnd,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.6,
                            height: MediaQuery.of(context).size.height * 0.6,
                            decoration: BoxDecoration(

                                // color: Colors.black,
                                border: Border.all(
                                  width: 5,
                                  color: Colors.black54,
                                ),
                                // Make rounded corners
                                borderRadius: BorderRadius.circular(30)),
                            margin: const EdgeInsets.fromLTRB(20, 30, 0, 0),
                            child: IconButton(
                              onPressed: () async {
                                fileNames.clear();
                                final List<AssetEntity>? result =
                                    await AssetPicker.pickAssets(context,
                                        pickerConfig:
                                            const AssetPickerConfig());
                                for (int i = 0; i < result!.length; i++) {
                                  final imageName = await result[i].file;
                                  print(imageName!.path);
                                  fileNames.add(imageName.path);
                                }
                              },
                              icon: const Icon(
                                FontAwesomeIcons.circlePlus,
                                size: 85,
                              ),
                            ),
                          ),
                        ],
                      )),
                  Expanded(
                      child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(0,
                            ((MediaQuery.of(context).size.width * 0.3)), 0, 0),
                        //height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.max,
                          children: const [
                            /// TODO completer
                          ],
                        ),
                      ),
                    ],
                  ))
                ],
              )),
          SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: [
                  Text("gdfgdfgdfdgf"),
                  Container(
                      margin: EdgeInsets.fromLTRB(0, 50, 0, 0),
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "You have selected ${fileNames.length.toString()} files"),
                          Container(
                            height: 10,
                          ),
                          TextField(
                            // controller: this._text2,
                            maxLines: 3,
                            minLines: 3,
                            maxLength: 500,
                            controller: _myController,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    width: 1, color: Colors.blue),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    width: 1, color: Colors.blue),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    // this._text2.text="";
                                    _myController.clear();
                                  });
                                },
                              ),
                              labelText: "Write a caption",
                            ),
                          ),
                        ],
                      )),
                  Center(
                    child: Row(
                      children: const [],
                    ),
                  ),
                ],
              )),
          Expanded(
            child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.2,
                width: MediaQuery.of(context).size.width,
                child: Row(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: const Icon(FontAwesomeIcons.deleteLeft,
                          size: 25, color: Colors.red),
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: IconButton(
                          onPressed: () {
                            widget.apiService.apiPostMedia(
                                _myController.text.toString(), fileNames);
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
                          },
                          icon: const Icon(
                            FontAwesomeIcons.fileImport,
                            size: 25,
                          ),
                        ))
                  ],
                )),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    //_myController.dispose();
    super.dispose();
  }
}
