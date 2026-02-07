import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fedispace/core/api.dart';
import 'package:fedispace/core/logger.dart';
import 'package:fedispace/models/account.dart';
import 'package:fedispace/widgets/instagram_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

/// Instagram-style profile editing page
class EditProfilePage extends StatefulWidget {
  final ApiService apiService;

  const EditProfilePage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  
  Account? _account;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _newAvatarFile;
  File? _newHeaderFile;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    try {
      final account = await widget.apiService.getCurrentAccount();
      setState(() {
        _account = account;
        _displayNameController.text = account.display_name;
        _bioController.text = account.note;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      appLogger.error('Error loading account', error, stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(bool isAvatar) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: isAvatar ? 400 : 1500,
      maxHeight: isAvatar ? 400 : 500,
    );

    if (pickedFile != null) {
      setState(() {
        if (isAvatar) {
          _newAvatarFile = File(pickedFile.path);
        } else {
          _newHeaderFile = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      appLogger.debug('Saving profile');
      await widget.apiService.updateCredentials(
        displayName: _displayNameController.text,
        note: _bioController.text,
        avatar: _newAvatarFile,
        header: _newHeaderFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (error, stackTrace) {
      appLogger.error('Error saving profile', error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: InstagramLoadingIndicator(size: 32)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: InstagramLoadingIndicator(size: 20),
                  )
                : const Text(
                    'Done',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Avatar
              GestureDetector(
                onTap: () => _pickImage(true),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _newAvatarFile != null
                          ? FileImage(_newAvatarFile!) as ImageProvider
                          : (_account?.avatar.isNotEmpty ?? false)
                              ? CachedNetworkImageProvider(_account!.avatar)
                              : null,
                      child: (_newAvatarFile == null && 
                              (_account?.avatar.isEmpty ?? true))
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0095F6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.black : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Change Profile Photo',
                style: TextStyle(
                  color: const Color(0xFF0095F6),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              const InstagramDivider(),
              _buildTextField(
                label: 'Name',
                controller: _displayNameController,
                maxLength: 30,
              ),
              const InstagramDivider(),
              _buildTextField(
                label: 'Username',
                value: _account?.username ?? '',
                enabled: false,
              ),
              const InstagramDivider(),
              _buildTextField(
                label: 'Bio',
                controller: _bioController,
                maxLength: 150,
                maxLines: 3,
              ),
              const InstagramDivider(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Header Image',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _pickImage(false),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF262626)
                                : const Color(0xFFDBDBDB),
                          ),
                        ),
                        child: _newHeaderFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _newHeaderFile!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : (_account?.header.isNotEmpty ?? false)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: _account!.header,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 40,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Add Header Image',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
    String? value,
    int maxLength = 100,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: controller,
              initialValue: controller == null ? value : null,
              enabled: enabled,
              maxLength: maxLength,
              maxLines: maxLines,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                border: InputBorder.none,
                counterText: '',
                hintText: label,
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFA8A8A8)
                      : const Color(0xFF8E8E8E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
