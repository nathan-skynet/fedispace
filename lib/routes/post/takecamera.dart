import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/messages.dart';
import 'package:fedispace/main.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

class CameraScreen extends StatefulWidget {
  final ApiService apiService;

  const CameraScreen({Key? key, required this.apiService}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? controller;
  VideoPlayerController? videoController;

  File? _imageFile;
  File? _videoFile;

  // Initial values
  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = false;
  bool _isRearCameraSelected = true;
  bool _isVideoCameraSelected = false;
  bool _isRecordingInProgress = false;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;

  // Current values
  double _currentZoomLevel = 1.0;
  double _currentExposureOffset = 0.0;
  FlashMode? _currentFlashMode;

  List<File> allFileList = [];

  final resolutionPresets = ResolutionPreset.values;

  ResolutionPreset currentResolutionPreset = ResolutionPreset.veryHigh;

  getPermissionStatus() async {
    await Permission.camera.request();
    var status = await Permission.camera.status;

    if (status.isGranted) {
      log('Camera Permission: GRANTED');
      setState(() {
        _isCameraPermissionGranted = true;
      });
      // Set and initialize the new camera
      onNewCameraSelected(cameras[0]);
      refreshAlreadyCapturedImages();
    } else {
      log('Camera Permission: DENIED');
    }
  }

  viewerPicture(patch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: Image.file(File(patch)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            //<-- SEE HERE
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              var result =
                  await widget.apiService.apiPostMedia("Description", patch);
              if (result == 200) {
                showSnackBar(context, "Media uploaded");
                Navigator.of(context).pop(false);
              } else {
                showSnackBar(context, "Error in fonction upload posts");
                Navigator.of(context).pop(false);
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  refreshAlreadyCapturedImages() async {
    final directory = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> fileList = await directory.list().toList();
    allFileList.clear();
    List<Map<int, dynamic>> fileNames = [];

    for (var file in fileList) {
      if (file.path.contains('.jpg') || file.path.contains('.mp4')) {
        allFileList.add(File(file.path));

        String name = file.path.split('/').last.split('.').first;
        fileNames.add({0: int.parse(name), 1: file.path.split('/').last});
      }
    }

    if (fileNames.isNotEmpty) {
      final recentFile =
          fileNames.reduce((curr, next) => curr[0] > next[0] ? curr : next);
      String recentFileName = recentFile[1];
      if (recentFileName.contains('.mp4')) {
        _videoFile = File('${directory.path}/$recentFileName');
        _imageFile = null;
        _startVideoPlayer();
      } else {
        _imageFile = File('${directory.path}/$recentFileName');
        _videoFile = null;
      }

      setState(() {});
    }
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;
    if (cameraController!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      print('Error occurred while taking picture: $e');
      return null;
    }
  }

  Future<void> _startVideoPlayer() async {
    if (_videoFile != null) {
      videoController = VideoPlayerController.file(_videoFile!);
      await videoController!.initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized,
        // even before the play button has been pressed.
        setState(() {});
      });
      await videoController!.setLooping(true);
      await videoController!.play();
    }
  }

  Future<void> startVideoRecording() async {
    final CameraController? cameraController = controller;

    if (controller!.value.isRecordingVideo) {
      // A recording has already started, do nothing.
      return;
    }

    try {
      await cameraController!.startVideoRecording();
      setState(() {
        _isRecordingInProgress = true;
        print(_isRecordingInProgress);
      });
    } on CameraException catch (e) {
      print('Error starting to record video: $e');
    }
  }

  Future<XFile?> stopVideoRecording() async {
    if (!controller!.value.isRecordingVideo) {
      // Recording is already is stopped state
      return null;
    }

    try {
      XFile file = await controller!.stopVideoRecording();
      setState(() {
        _isRecordingInProgress = false;
      });
      return file;
    } on CameraException catch (e) {
      print('Error stopping video recording: $e');
      return null;
    }
  }

  Future<void> pauseVideoRecording() async {
    if (!controller!.value.isRecordingVideo) {
      // Video recording is not in progress
      return;
    }

    try {
      await controller!.pauseVideoRecording();
    } on CameraException catch (e) {
      print('Error pausing video recording: $e');
    }
  }

  Future<void> resumeVideoRecording() async {
    if (!controller!.value.isRecordingVideo) {
      // No video recording was in progress
      return;
    }

    try {
      await controller!.resumeVideoRecording();
    } on CameraException catch (e) {
      print('Error resuming video recording: $e');
    }
  }

  void resetCameraValues() async {
    _currentZoomLevel = 1.0;
    _currentExposureOffset = 0.0;
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;

    final CameraController cameraController = CameraController(
      cameraDescription,
      currentResolutionPreset,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await previousCameraController?.dispose();

    resetCameraValues();

    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    try {
      await cameraController.initialize();
      await Future.wait([
        cameraController
            .getMinExposureOffset()
            .then((value) => _minAvailableExposureOffset = value),
        cameraController
            .getMaxExposureOffset()
            .then((value) => _maxAvailableExposureOffset = value),
        cameraController
            .getMaxZoomLevel()
            .then((value) => _maxAvailableZoom = value),
        cameraController
            .getMinZoomLevel()
            .then((value) => _minAvailableZoom = value),
      ]);

      _currentFlashMode = controller!.value.flashMode;
    } on CameraException catch (e) {
      print('Error initializing camera: $e');
    }

    if (mounted) {
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (controller == null) {
      return;
    }

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    controller!.setExposurePoint(offset);
    controller!.setFocusPoint(offset);
  }

  @override
  Future<void> initState() async {
    try {
      cameras = await availableCameras();
    } on CameraException catch (e) {
      debugPrint('Error in fetching the cameras: $e');
    }
    getPermissionStatus();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController.description);
    }
  }

  Future<bool> _onWillPop() async {
    Navigator.pushReplacementNamed(context, "/TimeLine");
    return false;
  }

  @override
  void dispose() {
    controller?.dispose();
    videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child: SafeArea(
          child: Scaffold(
            backgroundColor: Colors.black,
            body: _isCameraPermissionGranted
                ? _isCameraInitialized
                    ? Column(
                        children: [
                          AspectRatio(
                            aspectRatio: 1 / controller!.value.aspectRatio,
                            child: Stack(
                              children: [
                                CameraPreview(
                                  controller!,
                                  child: LayoutBuilder(builder:
                                      (BuildContext context,
                                          BoxConstraints constraints) {
                                    return GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTapDown: (details) =>
                                          onViewFinderTap(details, constraints),
                                    );
                                  }),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16.0,
                                    8.0,
                                    16.0,
                                    8.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            right: 8.0, top: 16.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              '${_currentExposureOffset.toStringAsFixed(1)}x',
                                              style: const TextStyle(
                                                  color: Colors.black),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: RotatedBox(
                                          quarterTurns: 3,
                                          child: SizedBox(
                                            height: 10,
                                            child: Slider(
                                              value: _currentExposureOffset,
                                              min: _minAvailableExposureOffset,
                                              max: _maxAvailableExposureOffset,
                                              activeColor: Colors.white,
                                              inactiveColor: Colors.white30,
                                              onChanged: (value) async {
                                                setState(() {
                                                  _currentExposureOffset =
                                                      value;
                                                });
                                                await controller!
                                                    .setExposureOffset(value);
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Slider(
                                              value: _currentZoomLevel,
                                              min: _minAvailableZoom,
                                              max: _maxAvailableZoom,
                                              activeColor: Colors.white,
                                              inactiveColor: Colors.white30,
                                              onChanged: (value) async {
                                                setState(() {
                                                  _currentZoomLevel = value;
                                                });
                                                await controller!
                                                    .setZoomLevel(value);
                                              },
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black87,
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  '${_currentZoomLevel.toStringAsFixed(1)}x',
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          InkWell(
                                            onTap: _isRecordingInProgress
                                                ? () async {
                                                    if (controller!.value
                                                        .isRecordingPaused) {
                                                      await resumeVideoRecording();
                                                    } else {
                                                      await pauseVideoRecording();
                                                    }
                                                  }
                                                : () {
                                                    setState(() {
                                                      _isCameraInitialized =
                                                          false;
                                                    });
                                                    onNewCameraSelected(cameras[
                                                        _isRearCameraSelected
                                                            ? 1
                                                            : 0]);
                                                    setState(() {
                                                      _isRearCameraSelected =
                                                          !_isRearCameraSelected;
                                                    });
                                                  },
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.circle,
                                                  color: Colors.black38,
                                                  size: 60,
                                                ),
                                                _isRecordingInProgress
                                                    ? controller!.value
                                                            .isRecordingPaused
                                                        ? const Icon(
                                                            Icons.play_arrow,
                                                            color: Colors.white,
                                                            size: 30,
                                                          )
                                                        : const Icon(
                                                            Icons.pause,
                                                            color: Colors.white,
                                                            size: 30,
                                                          )
                                                    : Icon(
                                                        _isRearCameraSelected
                                                            ? Icons.camera_front
                                                            : Icons.camera_rear,
                                                        color: Colors.white,
                                                        size: 30,
                                                      ),
                                              ],
                                            ),
                                          ),
                                          InkWell(
                                            onTap: _isVideoCameraSelected
                                                ? () async {
                                                    if (_isRecordingInProgress) {
                                                      XFile? rawVideo =
                                                          await stopVideoRecording();
                                                      File videoFile =
                                                          File(rawVideo!.path);

                                                      int currentUnix = DateTime
                                                              .now()
                                                          .millisecondsSinceEpoch;

                                                      final directory =
                                                          await getApplicationDocumentsDirectory();

                                                      String fileFormat =
                                                          videoFile.path
                                                              .split('.')
                                                              .last;

                                                      _videoFile =
                                                          await videoFile.copy(
                                                        '${directory.path}/$currentUnix.$fileFormat',
                                                      );

                                                      _startVideoPlayer();
                                                    } else {
                                                      await startVideoRecording();
                                                    }
                                                  }
                                                : () async {
                                                    XFile? rawImage =
                                                        await takePicture();
                                                    File imageFile =
                                                        File(rawImage!.path);

                                                    int currentUnix = DateTime
                                                            .now()
                                                        .millisecondsSinceEpoch;

                                                    final directory =
                                                        await getApplicationDocumentsDirectory();

                                                    String fileFormat =
                                                        imageFile.path
                                                            .split('.')
                                                            .last;

                                                    print(fileFormat);

                                                    await imageFile.copy(
                                                      '${directory.path}/$currentUnix.$fileFormat',
                                                    );
                                                    print(
                                                        "${directory.path}/$currentUnix.$fileFormat");
                                                    print("reprendre ici ");
                                                    viewerPicture(
                                                        '${directory.path}/$currentUnix.$fileFormat');
                                                    // TODO: reprendre ici

                                                    //refreshAlreadyCapturedImages();
                                                  },
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  Icons.circle,
                                                  color: _isVideoCameraSelected
                                                      ? Colors.white
                                                      : Colors.white38,
                                                  size: 80,
                                                ),
                                                Icon(
                                                  Icons.circle,
                                                  color: _isVideoCameraSelected
                                                      ? Colors.red
                                                      : Colors.white,
                                                  size: 65,
                                                ),
                                                _isVideoCameraSelected &&
                                                        _isRecordingInProgress
                                                    ? const Icon(
                                                        Icons.stop_rounded,
                                                        color: Colors.white,
                                                        size: 32,
                                                      )
                                                    : Container(),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8.0,
                                              right: 4.0,
                                            ),
                                            child: TextButton(
                                              onPressed: _isRecordingInProgress
                                                  ? null
                                                  : () {
                                                      if (_isVideoCameraSelected) {
                                                        setState(() {
                                                          _isVideoCameraSelected =
                                                              false;
                                                        });
                                                      }
                                                    },
                                              style: TextButton.styleFrom(
                                                foregroundColor: _isVideoCameraSelected
                                                    ? Colors.black54
                                                    : Colors.black,
                                                backgroundColor:
                                                    _isVideoCameraSelected
                                                        ? Colors.white30
                                                        : Colors.white,
                                              ),
                                              child: const Text('IMAGE'),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: 4.0, right: 8.0),
                                            child: TextButton(
                                              onPressed: () {
                                                if (!_isVideoCameraSelected) {
                                                  setState(() {
                                                    _isVideoCameraSelected =
                                                        true;
                                                  });
                                                }
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor: _isVideoCameraSelected
                                                    ? Colors.black
                                                    : Colors.black54,
                                                backgroundColor:
                                                    _isVideoCameraSelected
                                                        ? Colors.white
                                                        : Colors.white30,
                                              ),
                                              child: const Text('VIDEO'),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16.0, 8.0, 16.0, 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        InkWell(
                                          onTap: () async {
                                            setState(() {
                                              _currentFlashMode = FlashMode.off;
                                            });
                                            await controller!.setFlashMode(
                                              FlashMode.off,
                                            );
                                          },
                                          child: Icon(
                                            Icons.flash_off,
                                            color: _currentFlashMode ==
                                                    FlashMode.off
                                                ? Colors.amber
                                                : Colors.white,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            setState(() {
                                              _currentFlashMode =
                                                  FlashMode.auto;
                                            });
                                            await controller!.setFlashMode(
                                              FlashMode.auto,
                                            );
                                          },
                                          child: Icon(
                                            Icons.flash_auto,
                                            color: _currentFlashMode ==
                                                    FlashMode.auto
                                                ? Colors.amber
                                                : Colors.white,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            setState(() {
                                              _currentFlashMode =
                                                  FlashMode.always;
                                            });
                                            await controller!.setFlashMode(
                                              FlashMode.always,
                                            );
                                          },
                                          child: Icon(
                                            Icons.flash_on,
                                            color: _currentFlashMode ==
                                                    FlashMode.always
                                                ? Colors.amber
                                                : Colors.white,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            setState(() {
                                              _currentFlashMode =
                                                  FlashMode.torch;
                                            });
                                            await controller!.setFlashMode(
                                              FlashMode.torch,
                                            );
                                          },
                                          child: Icon(
                                            Icons.highlight,
                                            color: _currentFlashMode ==
                                                    FlashMode.torch
                                                ? Colors.amber
                                                : Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(),
                      const Text(
                        'Permission denied',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          getPermissionStatus();
                        },
                        child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(
                              child: CircularProgressIndicator(),
                            )),
                      ),
                    ],
                  ),
          ),
        ));
  }
}
