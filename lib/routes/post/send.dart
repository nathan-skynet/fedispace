import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/themes/cyberpunk_theme.dart';
import 'package:fedispace/routes/post/takecamera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class sendPosts extends StatefulWidget {
  final ApiService apiService;

  const sendPosts({Key? key, required this.apiService}) : super(key: key);

  @override
  State<sendPosts> createState() => _sendPostsState();
}

class _sendPostsState extends State<sendPosts> {
  final TextEditingController _captionController = TextEditingController();
  final FocusNode _captionFocus = FocusNode();
  final List<String> _selectedFiles = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSensitive = false;
  bool _isUploading = false;
  String _spoilerText = '';
  bool _isCreatingStory = false;

  @override
  void initState() {
    super.initState();
  }

  // ── Media source picker bottom sheet ──────────────────────────────
  void _showMediaSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CyberpunkTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: CyberpunkTheme.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Add Media',
                style: TextStyle(
                  color: CyberpunkTheme.textWhite,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _sourceOption(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              subtitle: 'Select photos & videos',
              color: CyberpunkTheme.neonCyan,
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery();
              },
            ),
            _sourceOption(
              icon: Icons.camera_alt_outlined,
              label: 'Take a Photo',
              subtitle: 'Use your camera',
              color: CyberpunkTheme.neonPink,
              onTap: () {
                Navigator.pop(ctx);
                _pickFromCamera(ImageSource.camera);
              },
            ),
            _sourceOption(
              icon: Icons.videocam_outlined,
              label: 'Record a Video',
              subtitle: 'Capture moments',
              color: const Color(0xFFFF9800),
              onTap: () {
                Navigator.pop(ctx);
                _pickVideoFromCamera();
              },
            ),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            _sourceOption(
              icon: Icons.auto_stories_rounded,
              label: 'Create a Story',
              subtitle: 'Share a moment that disappears in 24h',
              color: const Color(0xFF9C27B0),
              onTap: () {
                Navigator.pop(ctx);
                _createStoryFromGallery();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sourceOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label, style: const TextStyle(color: CyberpunkTheme.textWhite, fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: CyberpunkTheme.textTertiary, fontSize: 12)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  // ── Gallery picker ───────────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    try {
      // Cyberpunk dark theme for the gallery picker
      final pickerTheme = ThemeData.dark().copyWith(
        primaryColor: CyberpunkTheme.neonCyan,
        scaffoldBackgroundColor: CyberpunkTheme.backgroundBlack,
        canvasColor: CyberpunkTheme.surfaceDark,
        cardColor: CyberpunkTheme.cardDark,
        dialogBackgroundColor: CyberpunkTheme.surfaceDark,
        indicatorColor: CyberpunkTheme.neonCyan,
        colorScheme: const ColorScheme.dark(
          primary: CyberpunkTheme.neonCyan,
          secondary: CyberpunkTheme.neonPink,
          surface: CyberpunkTheme.surfaceDark,
          onPrimary: Colors.black,
          onSecondary: Colors.white,
          onSurface: CyberpunkTheme.textWhite,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: CyberpunkTheme.backgroundBlack,
          elevation: 0,
          foregroundColor: CyberpunkTheme.textWhite,
          titleTextStyle: TextStyle(
            color: CyberpunkTheme.textWhite,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: CyberpunkTheme.neonCyan),
        ),
        iconTheme: const IconThemeData(color: CyberpunkTheme.neonCyan),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: CyberpunkTheme.textWhite),
          bodyMedium: TextStyle(color: CyberpunkTheme.textWhite),
          bodySmall: TextStyle(color: CyberpunkTheme.textSecondary),
          titleLarge: TextStyle(color: CyberpunkTheme.textWhite, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(color: CyberpunkTheme.textWhite),
          titleSmall: TextStyle(color: CyberpunkTheme.textSecondary),
          labelLarge: TextStyle(color: CyberpunkTheme.neonCyan, fontWeight: FontWeight.w600),
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: CyberpunkTheme.neonCyan,
          textTheme: ButtonTextTheme.primary,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: CyberpunkTheme.neonCyan,
          ),
        ),
        bottomAppBarTheme: const BottomAppBarThemeData(
          color: CyberpunkTheme.backgroundBlack,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return CyberpunkTheme.neonCyan;
            }
            return Colors.transparent;
          }),
          checkColor: WidgetStateProperty.all(Colors.black),
          side: BorderSide(color: CyberpunkTheme.neonCyan.withOpacity(0.6)),
        ),
      );

      final List<AssetEntity>? result = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          pickerTheme: pickerTheme,
          maxAssets: 10,
          gridCount: 4,
          requestType: RequestType.image,
        ),
      );
      if (result != null && result.isNotEmpty) {
        for (var asset in result) {
          final file = await asset.file;
          if (file != null) {
            setState(() {
              _selectedFiles.add(file.path);
            });
          }
        }
      }
    } catch (e) {
      appLogger.error('Error picking media', e);
    }
  }

  // ── Camera picker ────────────────────────────────────────────────
  Future<void> _pickFromCamera(ImageSource source) async {
    try {
      final String? filePath = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => CameraScreen(
            apiService: widget.apiService,
            returnFile: true,
          ),
        ),
      );
      if (filePath != null && filePath.isNotEmpty) {
        setState(() {
          _selectedFiles.add(filePath);
        });
      }
    } catch (e) {
      appLogger.error('Error taking photo', e);
    }
  }

  Future<void> _pickVideoFromCamera() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 120),
      );
      if (video != null) {
        setState(() {
          _selectedFiles.add(video.path);
        });
      }
    } catch (e) {
      appLogger.error('Error recording video', e);
    }
  }

  // ── Story creation from gallery ──────────────────────────────────
  Future<void> _createStoryFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image == null) return;

      String storyPath = image.path;

      // Step 1: Offer the photo editor (crop / filters / draw)
      final file = File(storyPath);
      final imageData = await file.readAsBytes();
      final editedImage = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageEditor(image: imageData),
        ),
      );
      if (editedImage != null) {
        final tempFile = File('${Directory.systemTemp.path}/story_edited_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(editedImage);
        storyPath = tempFile.path;
      }

      // Step 2: Ask if user wants AI editing
      if (mounted) {
        final wantsAiEdit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: CyberpunkTheme.surfaceDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: CyberpunkTheme.neonPink.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.auto_awesome, color: CyberpunkTheme.neonPink, size: 20),
                ),
                const SizedBox(width: 10),
                const Text('AI Edit', style: TextStyle(color: CyberpunkTheme.textWhite, fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            content: const Text(
              'Want to further edit this image with AI?',
              style: TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Skip', style: TextStyle(color: CyberpunkTheme.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Edit with AI', style: TextStyle(color: CyberpunkTheme.neonPink, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );

        if (wantsAiEdit == true && mounted) {
          final aiPath = await _showStoryAiEditDialog(storyPath);
          if (aiPath != null) {
            storyPath = aiPath;
          }
        }
      }

      setState(() => _isCreatingStory = true);

      // Show a loading overlay
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: Card(
              color: Color(0xFF1A1A2E),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.cyanAccent),
                    SizedBox(height: 16),
                    Text('Publishing story...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      final error = await widget.apiService.createStory(filePath: storyPath);
      
      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading dialog
      }

      setState(() => _isCreatingStory = false);

      if (error == null) {
        // Success
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Story published! 🎉',
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
        }
      } else {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Story failed: $error',
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      }
    } catch (e) {
      setState(() => _isCreatingStory = false);
      appLogger.error('Error creating story from gallery', e);
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error: $e',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  /// Show AI edit dialog for story — returns the edited file path or null
  Future<String?> _showStoryAiEditDialog(String imagePath) async {
    final promptController = TextEditingController();
    final prompt = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: CyberpunkTheme.neonPink.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.auto_awesome, color: CyberpunkTheme.neonPink, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('AI Edit', style: TextStyle(color: CyberpunkTheme.textWhite, fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Describe how you want to modify the image:',
              style: TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: promptController,
              style: const TextStyle(color: CyberpunkTheme.textWhite, fontSize: 14),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. "Make it look like a painting"',
                hintStyle: const TextStyle(color: CyberpunkTheme.textTertiary, fontSize: 13),
                filled: true,
                fillColor: CyberpunkTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: CyberpunkTheme.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: CyberpunkTheme.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: CyberpunkTheme.neonPink),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel', style: TextStyle(color: CyberpunkTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final p = promptController.text.trim();
              if (p.isNotEmpty) Navigator.pop(ctx, p);
            },
            child: Text('Apply', style: TextStyle(color: CyberpunkTheme.neonPink, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (prompt == null || prompt.isEmpty || !mounted) return null;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: CyberpunkTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: CyberpunkTheme.neonPink),
              SizedBox(height: 16),
              Text('AI is working...', style: TextStyle(color: CyberpunkTheme.textWhite, fontSize: 14)),
            ],
          ),
        ),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final provider = prefs.getString('ai_default_provider') ?? 'stability';
      final apiKey = prefs.getString('${provider}_api_key') ?? '';

      if (apiKey.isEmpty) {
        if (mounted) Navigator.of(context).pop();
        Fluttertoast.showToast(msg: 'No API key set for $provider', backgroundColor: Colors.red, textColor: Colors.white);
        return null;
      }

      final bytes = await File(imagePath).readAsBytes();
      Uint8List? resultBytes;

      if (provider == 'stability') {
        resultBytes = await _editWithStability(apiKey, bytes, prompt);
      } else if (provider == 'openai') {
        resultBytes = await _editWithOpenAI(apiKey, bytes, prompt);
      } else {
        resultBytes = await _editWithNanoBanano(apiKey, bytes, prompt);
      }

      if (mounted) Navigator.of(context).pop(); // dismiss loading

      if (resultBytes != null) {
        final dir = await Directory.systemTemp.createTemp('story_ai_');
        final editedFile = File('${dir.path}/ai_edited_${DateTime.now().millisecondsSinceEpoch}.png');
        await editedFile.writeAsBytes(resultBytes);
        return editedFile.path;
      }
      return null;
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      appLogger.error('Story AI edit error', e);
      Fluttertoast.showToast(msg: 'AI edit failed: $e', backgroundColor: Colors.red, textColor: Colors.white);
      return null;
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  // ── AI Image Editing (Stability AI) ──────────────────────────────
  // ── Photo Editor (crop / rotate / filters) ──────────────────────
  Future<void> _openPhotoEditor(int fileIndex) async {
    try {
      final filePath = _selectedFiles[fileIndex];
      final file = File(filePath);
      final imageData = await file.readAsBytes();

      final editedImage = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageEditor(
            image: imageData,
          ),
        ),
      );

      if (editedImage != null && editedImage is Uint8List) {
        // Write edited image back to the file
        await file.writeAsBytes(editedImage);
        setState(() {});  // Refresh to show updated image
        Fluttertoast.showToast(
          msg: 'Image edited successfully',
          backgroundColor: CyberpunkTheme.neonCyan,
          textColor: Colors.black,
        );
      }
    } catch (e) {
      appLogger.error('Error opening photo editor', e);
      Fluttertoast.showToast(
        msg: 'Failed to open editor',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _showAiEditDialog(int fileIndex) {
    final promptController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberpunkTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: CyberpunkTheme.neonPink.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: CyberpunkTheme.neonPink, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('AI Edit', style: TextStyle(color: CyberpunkTheme.textWhite, fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe how you want to modify this image:',
              style: TextStyle(color: CyberpunkTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: promptController,
              maxLines: 3,
              style: const TextStyle(color: CyberpunkTheme.textWhite, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. Make the sky more dramatic...',
                hintStyle: TextStyle(color: CyberpunkTheme.textTertiary.withOpacity(0.5), fontSize: 14),
                filled: true,
                fillColor: CyberpunkTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: CyberpunkTheme.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: CyberpunkTheme.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: CyberpunkTheme.neonPink),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: CyberpunkTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberpunkTheme.neonPink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final prompt = promptController.text.trim();
              if (prompt.isNotEmpty) {
                _runAiEdit(fileIndex, prompt);
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  Future<void> _runAiEdit(int fileIndex, String prompt) async {
    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: CyberpunkTheme.surfaceDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: CyberpunkTheme.neonPink),
                const SizedBox(height: 16),
                const Text('AI is working...', style: TextStyle(color: CyberpunkTheme.textWhite, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final provider = prefs.getString('ai_default_provider') ?? 'stability';
      final apiKey = prefs.getString('${provider}_api_key') ?? '';

      if (apiKey.isEmpty) {
        Navigator.of(context).pop();
        Fluttertoast.showToast(msg: 'Set your API key in Settings first');
        return;
      }

      final file = File(_selectedFiles[fileIndex]);
      final bytes = await file.readAsBytes();
      Uint8List? resultBytes;

      if (provider == 'stability') {
        resultBytes = await _editWithStability(apiKey, bytes, prompt);
      } else if (provider == 'openai') {
        resultBytes = await _editWithOpenAI(apiKey, bytes, prompt);
      } else if (provider == 'nanobanano') {
        resultBytes = await _editWithNanoBanano(apiKey, bytes, prompt);
      }

      if (resultBytes != null) {
        final dir = file.parent;
        final editedFile = File('${dir.path}/ai_edited_${DateTime.now().millisecondsSinceEpoch}.png');
        await editedFile.writeAsBytes(resultBytes);

        setState(() {
          _selectedFiles[fileIndex] = editedFile.path;
        });

        Fluttertoast.showToast(
          msg: 'Image edited successfully!',
          backgroundColor: CyberpunkTheme.neonPink,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      appLogger.error('AI edit error', e);
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

  // ── Stability AI ────────────────────────────────────────────────────
  Future<Uint8List?> _editWithStability(String apiKey, Uint8List bytes, String prompt) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.stability.ai/v2beta/stable-image/edit/search-and-replace'),
    );
    request.headers['authorization'] = 'Bearer $apiKey';
    request.headers['accept'] = 'image/*';
    request.fields['prompt'] = prompt;
    request.fields['output_format'] = 'png';
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: 'input.png',
      contentType: MediaType('image', 'png'),
    ));

    final response = await request.send();
    final responseBytes = await response.stream.toBytes();
    if (response.statusCode == 200) return responseBytes;

    final errBody = utf8.decode(responseBytes);
    appLogger.error('Stability AI error [${response.statusCode}]: $errBody');
    String errMsg = 'Stability AI failed (${response.statusCode})';
    try {
      final errJson = jsonDecode(errBody);
      errMsg = errJson['message'] ?? errJson['errors']?.toString() ?? errMsg;
    } catch (_) {}
    Fluttertoast.showToast(msg: errMsg, backgroundColor: Colors.red, textColor: Colors.white);
    return null;
  }

  // ── OpenAI / ChatGPT (DALL-E) ──────────────────────────────────────
  Future<Uint8List?> _editWithOpenAI(String apiKey, Uint8List bytes, String prompt) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.openai.com/v1/images/edits'),
    );
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.fields['prompt'] = prompt;
    request.fields['model'] = 'dall-e-2';
    request.fields['size'] = '1024x1024';
    request.fields['response_format'] = 'b64_json';
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: 'input.png',
      contentType: MediaType('image', 'png'),
    ));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    appLogger.info('OpenAI response [${response.statusCode}]: $responseBody');

    if (response.statusCode == 200) {
      final json = jsonDecode(responseBody);
      final b64 = json['data'][0]['b64_json'] as String;
      return base64Decode(b64);
    }

    // Extract error message from OpenAI response
    String errMsg = 'ChatGPT edit failed (${response.statusCode})';
    try {
      final errJson = jsonDecode(responseBody);
      errMsg = errJson['error']?['message'] ?? errMsg;
    } catch (_) {}
    appLogger.error('OpenAI error: $errMsg');
    Fluttertoast.showToast(msg: errMsg, backgroundColor: Colors.red, textColor: Colors.white);
    return null;
  }

  // ── Nano Banano Pro (via kie.ai) ────────────────────────────────
  Future<Uint8List?> _editWithNanoBanano(String apiKey, Uint8List bytes, String prompt) async {
    try {
      // Step 1: Upload image as base64
      final b64Data = 'data:image/png;base64,${base64Encode(bytes)}';
      final uploadResp = await http.post(
        Uri.parse('https://kieai.redpandaai.co/api/file-base64-upload'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'base64Data': b64Data,
          'uploadPath': 'images',
          'fileName': 'input_${DateTime.now().millisecondsSinceEpoch}.png',
        }),
      );

      if (uploadResp.statusCode != 200) {
        appLogger.error('Kie.ai upload failed [${uploadResp.statusCode}]: ${uploadResp.body}');
        Fluttertoast.showToast(msg: 'Image upload failed (${uploadResp.statusCode})', backgroundColor: Colors.red, textColor: Colors.white);
        return null;
      }

      final uploadJson = jsonDecode(uploadResp.body);
      appLogger.info('Kie.ai upload response: ${uploadResp.body}');

      // Try multiple possible field names
      final data = uploadJson['data'];
      String? fileUrl;
      if (data != null) {
        fileUrl = data['fileUrl'] ?? data['url'] ?? data['file_url'] ?? data['downloadUrl'];
      }
      if (fileUrl == null || fileUrl.isEmpty) {
        appLogger.error('Kie.ai upload: no fileUrl in response: ${uploadResp.body}');
        Fluttertoast.showToast(msg: 'Upload error — check logs', backgroundColor: Colors.red, textColor: Colors.white);
        return null;
      }

      // Step 2: Create image edit task
      final createResp = await http.post(
        Uri.parse('https://api.kie.ai/api/v1/gpt4o-image/generate'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'filesUrl': [fileUrl],
          'prompt': prompt,
          'size': '1:1',
          'nVariants': 1,
        }),
      );

      if (createResp.statusCode != 200) {
        appLogger.error('Kie.ai createTask failed [${createResp.statusCode}]: ${createResp.body}');
        Fluttertoast.showToast(msg: 'Task creation failed (${createResp.statusCode})', backgroundColor: Colors.red, textColor: Colors.white);
        return null;
      }

      final createJson = jsonDecode(createResp.body);
      appLogger.info('Kie.ai createTask response: ${createResp.body}');
      final taskId = createJson['data']?['taskId'] as String?;
      if (taskId == null) {
        appLogger.error('Kie.ai createTask: no taskId in response');
        Fluttertoast.showToast(msg: 'No task ID returned', backgroundColor: Colors.red, textColor: Colors.white);
        return null;
      }

      appLogger.info('Kie.ai task created: $taskId — polling...');

      // Step 3: Poll for result (max ~2 minutes)
      String? resultUrl;
      for (int i = 0; i < 60; i++) {
        await Future.delayed(const Duration(seconds: 2));
        final pollResp = await http.get(
          Uri.parse('https://api.kie.ai/api/v1/gpt4o-image/record-info?taskId=$taskId'),
          headers: {'Authorization': 'Bearer $apiKey'},
        );

        if (pollResp.statusCode != 200) {
          appLogger.warning('Kie.ai poll error [${pollResp.statusCode}]');
          continue;
        }

        final pollJson = jsonDecode(pollResp.body);
        final flag = pollJson['data']?['successFlag'];
        final progress = pollJson['data']?['progress'] ?? '?';
        if (i < 3) {
          appLogger.info('Kie.ai poll #$i FULL: ${pollResp.body}');
        } else {
          appLogger.info('Kie.ai poll #$i: flag=$flag progress=$progress');
        }

        if (flag == 1) {
          final urls = pollJson['data']?['response']?['result_urls'] as List?;
          if (urls != null && urls.isNotEmpty) {
            resultUrl = urls[0] as String;
          }
          break;
        } else if (flag == 2) {
          final errMsg = pollJson['data']?['errorMessage'] ?? 'Unknown error';
          appLogger.error('Kie.ai task failed: $errMsg');
          Fluttertoast.showToast(msg: 'AI edit failed: $errMsg', backgroundColor: Colors.red, textColor: Colors.white);
          return null;
        }
        // flag == 0 → still generating, keep polling
      }

      if (resultUrl == null) {
        appLogger.error('Kie.ai task $taskId timed out after 2 minutes');
        Fluttertoast.showToast(msg: 'AI edit timed out (2 min)', backgroundColor: Colors.red, textColor: Colors.white);
        return null;
      }

      // Step 4: Download result image
      final imgResp = await http.get(Uri.parse(resultUrl));
      if (imgResp.statusCode == 200) return imgResp.bodyBytes;

      appLogger.error('Kie.ai download failed: ${imgResp.statusCode}');
      Fluttertoast.showToast(msg: 'Failed to download result', backgroundColor: Colors.red, textColor: Colors.white);
      return null;
    } catch (e) {
      appLogger.error('Kie.ai error: $e');
      Fluttertoast.showToast(msg: 'Nano Banano error: $e', backgroundColor: Colors.red, textColor: Colors.white);
      return null;
    }
  }

  // ── Publish ──────────────────────────────────────────────────────
  Future<void> _publish() async {
    if (_selectedFiles.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please select at least one photo or video",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isUploading = true);
    Vibrate.vibrate();

    try {
      final result = await widget.apiService.apiPostMedia(
        _captionController.text.trim(),
        _selectedFiles,
      );
      if (result != null && result > 0) {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        Fluttertoast.showToast(
          msg: "Upload failed — please try again",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: ${e.toString()}",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _captionFocus.dispose();
    super.dispose();
  }

  // ── UI ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberpunkTheme.backgroundBlack,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Icon(Icons.close_rounded, color: CyberpunkTheme.textWhite, size: 20),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [CyberpunkTheme.neonCyan, CyberpunkTheme.neonPink],
          ).createShader(bounds),
          child: const Text(
            'CREATE POST',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _isUploading ? null : _publish,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  gradient: _isUploading
                      ? null
                      : const LinearGradient(
                          colors: [CyberpunkTheme.neonCyan, Color(0xFF0077CC)],
                        ),
                  color: _isUploading ? Colors.white.withOpacity(0.1) : null,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _isUploading
                      ? null
                      : [
                          BoxShadow(
                            color: CyberpunkTheme.neonCyan.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CyberpunkTheme.neonCyan,
                        ),
                      )
                    : const Text(
                        'Share',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top spacing for AppBar
            SizedBox(height: MediaQuery.of(context).padding.top + 56),

            // ── Media Selection Area ───────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: CyberpunkTheme.neonCyan.withOpacity(0.04),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    // Selected media preview
                    if (_selectedFiles.isNotEmpty) ...[
                      SizedBox(
                        height: 280,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(14),
                          itemCount: _selectedFiles.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _selectedFiles.length) {
                              // Add more button
                              return GestureDetector(
                                onTap: _showMediaSourceSheet,
                                child: Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: CyberpunkTheme.neonCyan.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        CyberpunkTheme.neonCyan.withOpacity(0.08),
                                        CyberpunkTheme.neonCyan.withOpacity(0.02),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: CyberpunkTheme.neonCyan.withOpacity(0.4),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.add_rounded,
                                          size: 24,
                                          color: CyberpunkTheme.neonCyan.withOpacity(0.8),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Add More',
                                        style: TextStyle(
                                          color: CyberpunkTheme.neonCyan.withOpacity(0.8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 10),
                              child: Stack(
                                children: [
                                  // Image card with glow
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: CyberpunkTheme.neonPink.withOpacity(0.08),
                                          blurRadius: 20,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.file(
                                            File(_selectedFiles[index]),
                                            fit: BoxFit.cover,
                                          ),
                                          // Bottom gradient overlay
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            height: 60,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black.withOpacity(0.7),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Image counter
                                          Positioned(
                                            bottom: 8,
                                            left: 10,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.5),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${index + 1}/${_selectedFiles.length}',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Remove button — glassmorphic
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => _removeFile(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                                        ),
                                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  // Photo editor button (crop/rotate)
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    child: GestureDetector(
                                      onTap: () => _openPhotoEditor(index),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [CyberpunkTheme.neonCyan, Color(0xFF0088FF)],
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: CyberpunkTheme.neonCyan.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.crop_rotate_rounded, size: 13, color: Colors.white),
                                            SizedBox(width: 4),
                                            Text('Edit', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // AI Edit button — premium glow
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => _showAiEditDialog(index),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [CyberpunkTheme.neonPink, Color(0xFFAA00FF)],
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: CyberpunkTheme.neonPink.withOpacity(0.4),
                                              blurRadius: 10,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.auto_awesome, size: 13, color: Colors.white),
                                            SizedBox(width: 4),
                                            Text('AI Edit', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      // Empty state — premium hero
                      GestureDetector(
                        onTap: _showMediaSourceSheet,
                        child: Container(
                          height: 260,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 0.8,
                              colors: [
                                CyberpunkTheme.neonCyan.withOpacity(0.06),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      CyberpunkTheme.neonCyan.withOpacity(0.12),
                                      CyberpunkTheme.neonPink.withOpacity(0.08),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: CyberpunkTheme.neonCyan.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: CyberpunkTheme.neonCyan.withOpacity(0.15),
                                      blurRadius: 30,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: CyberpunkTheme.neonPink.withOpacity(0.08),
                                      blurRadius: 30,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [CyberpunkTheme.neonCyan, CyberpunkTheme.neonPink],
                                  ).createShader(bounds),
                                  child: const Icon(
                                    Icons.add_a_photo_rounded,
                                    size: 36,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Add your media',
                                style: TextStyle(
                                  fontSize: 17,
                                  color: CyberpunkTheme.textWhite,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _mediaBadge(Icons.photo_library_outlined, 'Gallery'),
                                  Container(width: 3, height: 3, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: CyberpunkTheme.textTertiary, shape: BoxShape.circle)),
                                  _mediaBadge(Icons.camera_alt_outlined, 'Camera'),
                                  Container(width: 3, height: 3, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: CyberpunkTheme.textTertiary, shape: BoxShape.circle)),
                                  _mediaBadge(Icons.videocam_outlined, 'Video'),
                                  Container(width: 3, height: 3, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: CyberpunkTheme.textTertiary, shape: BoxShape.circle)),
                                  _mediaBadge(Icons.auto_stories_rounded, 'Story'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Divider with gradient
                    Container(
                      height: 0.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            CyberpunkTheme.neonCyan.withOpacity(0.2),
                            CyberpunkTheme.neonPink.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // Caption Input
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                      child: TextField(
                        controller: _captionController,
                        focusNode: _captionFocus,
                        maxLines: 4,
                        minLines: 2,
                        maxLength: 500,
                        style: const TextStyle(
                          color: CyberpunkTheme.textWhite,
                          fontSize: 15,
                          height: 1.6,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write a caption...',
                          hintStyle: TextStyle(
                            color: CyberpunkTheme.textTertiary.withOpacity(0.4),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          counterStyle: TextStyle(
                            color: CyberpunkTheme.textTertiary.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Options card ───────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  // NSFW Toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: (_isSensitive ? Colors.orange : CyberpunkTheme.textTertiary).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: _isSensitive ? Colors.orange : CyberpunkTheme.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Sensitive content',
                              style: TextStyle(
                                fontSize: 14,
                                color: CyberpunkTheme.textWhite,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: _isSensitive,
                          onChanged: (value) {
                            setState(() => _isSensitive = value);
                          },
                          activeColor: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  if (_isSensitive) ...[
                    Container(
                      height: 0.5,
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      color: Colors.orange.withOpacity(0.15),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        onChanged: (val) => _spoilerText = val,
                        style: const TextStyle(
                          color: CyberpunkTheme.textWhite,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Content warning (optional)',
                          hintStyle: TextStyle(
                            color: CyberpunkTheme.textTertiary.withOpacity(0.4),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.orange.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.orange.withOpacity(0.2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.orange.withOpacity(0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.orange),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Selected media counter ─────────────────────────────
            if (_selectedFiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: CyberpunkTheme.neonCyan.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: CyberpunkTheme.neonCyan.withOpacity(0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_library_rounded, size: 14, color: CyberpunkTheme.neonCyan.withOpacity(0.8)),
                          const SizedBox(width: 6),
                          Text(
                            '${_selectedFiles.length} ${_selectedFiles.length == 1 ? 'item' : 'items'} selected',
                            style: TextStyle(
                              fontSize: 12,
                              color: CyberpunkTheme.neonCyan.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _mediaBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: CyberpunkTheme.textTertiary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: CyberpunkTheme.textTertiary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
