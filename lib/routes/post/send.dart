import 'dart:io';

import 'package:fedispace/core/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

List<String> fileNames = [];

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
        backgroundColor: const Color(0xFF050505),
        body: Stack(
          children: [
            // Background
            Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage("https://img.freepik.com/free-vector/dark-hexagonal-background-with-gradient-color_79603-1409.jpg"),
                      fit: BoxFit.cover,
                      opacity: 0.2,
                    ),
                )),

            Column(
              children: [
                const SizedBox(height: 50),
                // Header
                Text("NEW TRANSMISSION", style: TextStyle(fontFamily: 'Orbitron', color: const Color(0xFF00F3FF), fontSize: 24, letterSpacing: 2, shadows: [Shadow(color: const Color(0xFF00F3FF).withOpacity(0.8), blurRadius: 10)])),
                const SizedBox(height: 20),

                // Content Area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101010).withOpacity(0.9),
                      border: Border.all(color: const Color(0xFF00F3FF).withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0xFF00F3FF).withOpacity(0.2), blurRadius: 20)],
                    ),
                    child: Column(
                      children: [
                        // Image Picker Section
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: const Color(0xFF00F3FF).withOpacity(0.3))),
                          ),
                          child: Row(
                            children: [
                              // Add Button
                              GestureDetector(
                                onTap: () async {
                                  fileNames.clear();
                                  final List<AssetEntity>? result =
                                      await AssetPicker.pickAssets(context,
                                          pickerConfig: const AssetPickerConfig());
                                  for (int i = 0; i < result!.length; i++) {
                                    final imageName = await result[i].file;
                                    print(imageName!.path);
                                    setState(() {
                                      fileNames.add(imageName.path);
                                    });
                                  }
                                },
                                child: Container(
                                  width: 120,
                                  height: double.infinity,
                                  color: const Color(0xFF050505),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFFFF00FF), width: 2),
                                          boxShadow: [BoxShadow(color: const Color(0xFFFF00FF).withOpacity(0.5), blurRadius: 10)],
                                        ),
                                        child: const Icon(FontAwesomeIcons.plus, color: Color(0xFFFF00FF), size: 30),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text("ADD DATA", style: TextStyle(color: Color(0xFFFF00FF), fontFamily: 'Rajdhani', fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                              // Image List
                              Expanded(
                                child: fileNames.isNotEmpty ? foreach() : Center(child: Text("NO DATA SELECTED", style: TextStyle(color: Colors.grey.withOpacity(0.5), fontFamily: 'Orbitron'))),
                              ),
                            ],
                          ),
                        ),

                        // Form Fields
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("NSFW CONTENT", style: TextStyle(color: Color(0xFF00F3FF), fontFamily: 'Rajdhani', fontSize: 16)),
                                    Switch(
                                      value: isSwitched,
                                      onChanged: (value) {
                                        setState(() {
                                          isSwitched = value;
                                        });
                                      },
                                      activeColor: const Color(0xFFFF00FF),
                                      inactiveThumbColor: Colors.grey,
                                      inactiveTrackColor: Colors.grey.withOpacity(0.3),
                                    ),
                                  ],
                                ),
                                if (isSwitched) ...[
                                  const SizedBox(height: 10),
                                  TextField(
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFF050505),
                                      hintText: "WARNING PROTOCOL...",
                                      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                                      border: OutlineInputBorder(borderSide: BorderSide(color: const Color(0xFFFAFF00).withOpacity(0.5))),
                                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: const Color(0xFFFAFF00).withOpacity(0.5))),
                                    ),
                                  )
                                ],
                                const SizedBox(height: 20),
                                const Divider(color: Color(0xFF00F3FF)),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: myController,
                                  focusNode: myFocusNode,
                                  maxLines: 4,
                                  maxLength: 500,
                                  style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani', fontSize: 16),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFF050505),
                                    labelText: "CAPTION INPUT",
                                    labelStyle: const TextStyle(color: Color(0xFF00F3FF)),
                                    border: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF00F3FF))),
                                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: const Color(0xFF00F3FF).withOpacity(0.3))),
                                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00F3FF), width: 2)),
                                    suffixIcon: IconButton(
                                      icon: const Icon(FontAwesomeIcons.paperPlane, color: Color(0xFFFF00FF)),
                                      onPressed: () async {
                                        if (fileNames.isEmpty) {
                                          Fluttertoast.showToast(
                                              msg: "NO FILES SELECTED",
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.BOTTOM,
                                              backgroundColor: Colors.red,
                                              textColor: Colors.white,
                                              fontSize: 16.0);
                                          return;
                                        }
                                        
                                        Vibrate.vibrate();
                                        Fluttertoast.showToast(
                                            msg: "UPLOADING DATA PACKET...",
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.BOTTOM,
                                            backgroundColor: const Color(0xFF00F3FF),
                                            textColor: Colors.black,
                                            fontSize: 16.0);
                                        
                                        try {
                                          final result = await widget.apiService.apiPostMedia(
                                              myController.text.toString(), fileNames);
                                          if (result != null && result > 0) {
                                            Fluttertoast.showToast(
                                                msg: "DATA TRANSMITTED ✓",
                                                toastLength: Toast.LENGTH_SHORT,
                                                gravity: ToastGravity.BOTTOM,
                                                backgroundColor: Colors.green,
                                                textColor: Colors.white,
                                                fontSize: 16.0);
                                            Navigator.of(context).pop(false);
                                          } else {
                                            Fluttertoast.showToast(
                                                msg: "UPLOAD FAILED - CHECK LOGS",
                                                toastLength: Toast.LENGTH_LONG,
                                                gravity: ToastGravity.BOTTOM,
                                                backgroundColor: Colors.red,
                                                textColor: Colors.white,
                                                fontSize: 16.0);
                                          }
                                        } catch (e) {
                                          Fluttertoast.showToast(
                                              msg: "TRANSMISSION FAILED: ${e.toString()}",
                                              toastLength: Toast.LENGTH_LONG,
                                              gravity: ToastGravity.BOTTOM,
                                              backgroundColor: Colors.red,
                                              textColor: Colors.white,
                                              fontSize: 16.0);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
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
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/View',
                arguments: {"file": fileNames[index]});
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
            width: 40,
            height: 85,
            child: Image.file(
              fit: BoxFit.cover,
              File(fileNames[index]),
            ),
          ),
        );
      });
}
