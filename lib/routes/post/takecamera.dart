import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/messages.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  final ApiService apiService;
  final bool isStoryMode;
  /// If true, returns file path via Navigator.pop instead of uploading directly
  final bool returnFile;

  const CameraScreen({
    Key? key,
    required this.apiService,
    this.isStoryMode = false,
    this.returnFile = false,
  }) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? controller;
  List<CameraDescription> _cameras = [];

  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = false;
  bool _isRearCameraSelected = true;
  bool _isVideoCameraSelected = false;
  bool _isRecordingInProgress = false;
  bool _noCamerasFound = false;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;

  double _currentZoomLevel = 1.0;
  double _currentExposureOffset = 0.0;
  FlashMode? _currentFlashMode;

  ResolutionPreset currentResolutionPreset = ResolutionPreset.veryHigh;

  // ── Lifecycle ─────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = controller;
    if (cam == null || !cam.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      cam.dispose();
    } else if (state == AppLifecycleState.resumed && _cameras.isNotEmpty) {
      final idx = _isRearCameraSelected ? 0 : (_cameras.length > 1 ? 1 : 0);
      _selectCamera(_cameras[idx]);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  // ── Permissions & Discovery ───────────────────

  Future<void> _requestPermission() async {
    await Permission.camera.request();
    final status = await Permission.camera.status;
    if (status.isGranted) {
      log('Camera Permission: GRANTED');
      setState(() => _isCameraPermissionGranted = true);

      // Discover cameras on this device
      try {
        _cameras = await availableCameras();
        log('Found ${_cameras.length} cameras');
      } catch (e) {
        log('availableCameras error: $e');
      }

      if (_cameras.isEmpty) {
        setState(() => _noCamerasFound = true);
        return;
      }

      _selectCamera(_cameras[0]);
    } else {
      log('Camera Permission: DENIED');
    }
  }

  // ── Camera selection ──────────────────────────

  Future<void> _selectCamera(CameraDescription desc) async {
    final prev = controller;
    final cam = CameraController(desc, currentResolutionPreset, imageFormatGroup: ImageFormatGroup.jpeg);
    await prev?.dispose();

    try {
      await cam.initialize();
      cam.getMaxZoomLevel().then((v) => _maxAvailableZoom = v);
      cam.getMinZoomLevel().then((v) => _minAvailableZoom = v);
      cam.getMaxExposureOffset().then((v) => _maxAvailableExposureOffset = v);
      cam.getMinExposureOffset().then((v) => _minAvailableExposureOffset = v);
      _currentFlashMode = cam.value.flashMode;
    } catch (e) {
      log('Camera init error: $e');
    }

    if (mounted) {
      setState(() {
        controller = cam;
        _isCameraInitialized = cam.value.isInitialized;
        _currentZoomLevel = 1.0;
        _currentExposureOffset = 0.0;
      });
    }
  }

  void _flipCamera() {
    if (_cameras.length < 2) return;
    setState(() => _isCameraInitialized = false);
    _isRearCameraSelected = !_isRearCameraSelected;
    _selectCamera(_cameras[_isRearCameraSelected ? 0 : 1]);
  }

  // ── Capture ───────────────────────────────────

  Future<void> _takePicture() async {
    final cam = controller;
    if (cam == null || cam.value.isTakingPicture) return;

    try {
      final xFile = await cam.takePicture();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final dir = await getApplicationDocumentsDirectory();
      final ext = xFile.path.split('.').last;
      final dest = '${dir.path}/$ts.$ext';
      await File(xFile.path).copy(dest);

      if (widget.returnFile) {
        if (mounted) Navigator.pop(context, dest);
      } else if (widget.isStoryMode) {
        _confirmStoryUpload(dest);
      } else {
        _confirmMediaUpload(dest);
      }
    } catch (e) {
      log('Take picture error: $e');
    }
  }

  Future<void> _startVideoRecording() async {
    final cam = controller;
    if (cam == null || _isRecordingInProgress) return;
    try {
      await cam.startVideoRecording();
      setState(() => _isRecordingInProgress = true);
    } catch (e) {
      log('Start recording error: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    final cam = controller;
    if (cam == null || !_isRecordingInProgress) return;
    try {
      final xFile = await cam.stopVideoRecording();
      setState(() => _isRecordingInProgress = false);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final dir = await getApplicationDocumentsDirectory();
      final ext = xFile.path.split('.').last;
      final dest = '${dir.path}/$ts.$ext';
      await File(xFile.path).copy(dest);

      if (widget.returnFile) {
        if (mounted) Navigator.pop(context, dest);
      } else {
        _confirmMediaUpload(dest);
      }
    } catch (e) {
      log('Stop recording error: $e');
    }
  }

  Future<void> _pauseResumeRecording() async {
    final cam = controller;
    if (cam == null) return;
    if (cam.value.isRecordingPaused) {
      await cam.resumeVideoRecording();
    } else {
      await cam.pauseVideoRecording();
    }
    setState(() {});
  }

  // ── Upload dialogs ────────────────────────────

  void _confirmStoryUpload(String path) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add to Story?', style: GoogleFonts.inter(color: CyberpunkTheme.textWhite, fontWeight: FontWeight.w700)),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(path), height: 280, fit: BoxFit.cover),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: CyberpunkTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberpunkTheme.neonPink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await widget.apiService.createStory(filePath: path);
              if (mounted) showSnackBar(context, error == null ? 'Added to Story ✓' : 'Story error: $error');
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmMediaUpload(String path) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Upload?', style: GoogleFonts.inter(color: CyberpunkTheme.textWhite, fontWeight: FontWeight.w700)),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(path), height: 280, fit: BoxFit.cover),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: CyberpunkTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberpunkTheme.neonCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await widget.apiService.apiPostMedia('Description', [path]);
              if (mounted) showSnackBar(context, result == 200 ? 'Media uploaded' : 'Upload error');
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  // ── Focus tap ─────────────────────────────────

  void _onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    final cam = controller;
    if (cam == null) return;
    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cam.setExposurePoint(offset);
    cam.setFocusPoint(offset);
  }

  // ══════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      body: SafeArea(
        child: _isCameraPermissionGranted
            ? _noCamerasFound
                ? _buildNoCameras()
                : _isCameraInitialized
                    ? _buildCameraUI()
                    : const Center(child: CircularProgressIndicator(color: CyberpunkTheme.neonCyan))
            : _buildPermissionDenied(),
      ),
    );
  }

  Widget _buildNoCameras() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CyberpunkTheme.neonPink.withOpacity(0.1),
              border: Border.all(color: CyberpunkTheme.neonPink.withOpacity(0.2)),
            ),
            child: const Icon(Icons.no_photography_rounded, size: 48, color: CyberpunkTheme.neonPink),
          ),
          const SizedBox(height: 24),
          Text('No Camera Found', style: GoogleFonts.inter(color: CyberpunkTheme.textWhite, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('This device has no available cameras', style: GoogleFonts.inter(color: CyberpunkTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: CyberpunkTheme.textWhite,
              side: BorderSide(color: CyberpunkTheme.borderDark),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CyberpunkTheme.neonPink.withOpacity(0.1),
              border: Border.all(color: CyberpunkTheme.neonPink.withOpacity(0.2)),
            ),
            child: const Icon(Icons.camera_alt_outlined, size: 48, color: CyberpunkTheme.neonPink),
          ),
          const SizedBox(height: 24),
          Text('Camera Permission Required', style: GoogleFonts.inter(color: CyberpunkTheme.textWhite, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Allow camera access to take photos', style: GoogleFonts.inter(color: CyberpunkTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberpunkTheme.neonCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.lock_open_rounded, size: 18),
            label: Text('Grant Permission', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            onPressed: _requestPermission,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraUI() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(child: _buildPreview()),
        _buildBottomControls(),
      ],
    );
  }

  // ── Top Bar ───────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _circleButton(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
          const Spacer(),
          _circleButton(
            icon: _flashIcon(),
            color: _currentFlashMode == FlashMode.off ? CyberpunkTheme.textSecondary : CyberpunkTheme.neonCyan,
            onTap: _cycleFlash,
          ),
          if (!_isRecordingInProgress && _cameras.length > 1) ...[
            const SizedBox(width: 12),
            _circleButton(icon: Icons.cameraswitch_rounded, onTap: _flipCamera),
          ],
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, VoidCallback? onTap, Color color = CyberpunkTheme.textWhite}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }

  IconData _flashIcon() {
    switch (_currentFlashMode) {
      case FlashMode.auto: return Icons.flash_auto_rounded;
      case FlashMode.always: return Icons.flash_on_rounded;
      case FlashMode.torch: return Icons.flashlight_on_rounded;
      default: return Icons.flash_off_rounded;
    }
  }

  void _cycleFlash() async {
    final modes = [FlashMode.off, FlashMode.auto, FlashMode.always, FlashMode.torch];
    final idx = modes.indexOf(_currentFlashMode ?? FlashMode.off);
    final next = modes[(idx + 1) % modes.length];
    setState(() => _currentFlashMode = next);
    await controller?.setFlashMode(next);
  }

  // ── Preview ───────────────────────────────────

  Widget _buildPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _onViewFinderTap(d, constraints),
                onScaleUpdate: (details) async {
                  final newZoom = (_currentZoomLevel * details.scale).clamp(_minAvailableZoom, _maxAvailableZoom);
                  setState(() => _currentZoomLevel = newZoom);
                  await controller?.setZoomLevel(newZoom);
                },
                child: CameraPreview(controller!),
              );
            },
          ),
          // Zoom indicator
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                '${_currentZoomLevel.toStringAsFixed(1)}x',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          // REC indicator
          if (_isRecordingInProgress)
            Positioned(
              top: 16, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('REC', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Bottom Controls ───────────────────────────

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        children: [
          if (!_isRecordingInProgress)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _modeToggle('PHOTO', !_isVideoCameraSelected, () => setState(() => _isVideoCameraSelected = false)),
                const SizedBox(width: 4),
                _modeToggle('VIDEO', _isVideoCameraSelected, () => setState(() => _isVideoCameraSelected = true)),
              ],
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecordingInProgress) ...[
                GestureDetector(
                  onTap: _pauseResumeRecording,
                  child: Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Icon(
                      controller?.value.isRecordingPaused == true ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      color: Colors.white, size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 30),
              ],
              // Main capture button
              GestureDetector(
                onTap: _isVideoCameraSelected
                    ? (_isRecordingInProgress ? _stopVideoRecording : _startVideoRecording)
                    : _takePicture,
                child: Container(
                  width: 76, height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isRecordingInProgress ? Colors.red
                          : _isVideoCameraSelected ? Colors.red.withOpacity(0.7) : CyberpunkTheme.neonCyan,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecordingInProgress ? Colors.red
                            : _isVideoCameraSelected ? Colors.red : CyberpunkTheme.neonCyan).withOpacity(0.25),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: _isRecordingInProgress ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: _isRecordingInProgress ? BorderRadius.circular(8) : null,
                      color: _isRecordingInProgress ? Colors.red
                          : _isVideoCameraSelected ? Colors.red.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeToggle(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: active
              ? (label == 'VIDEO' ? Colors.red.withOpacity(0.15) : CyberpunkTheme.neonCyan.withOpacity(0.12))
              : Colors.transparent,
          border: Border.all(
            color: active
                ? (label == 'VIDEO' ? Colors.red.withOpacity(0.3) : CyberpunkTheme.neonCyan.withOpacity(0.25))
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? (label == 'VIDEO' ? Colors.red : CyberpunkTheme.neonCyan) : CyberpunkTheme.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
