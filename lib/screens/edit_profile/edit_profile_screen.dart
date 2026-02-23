import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/enhanced_theme.dart';
import '../../core/widgets/gradient_widgets.dart';
import '../../core/utils/error_handler.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = Get.find<AuthController>();
  final _supabase = SupabaseService.client;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = _authController.currentUser.value;
    if (user != null) {
      _nameController.text = user.fullName ?? '';
      _emailController.text = user.email;

      // Fetch additional profile data
      try {
        final profile = await _supabase
            .from('user_profiles')
            .select('phone_number, bio')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null) {
          _phoneController.text = profile['phone_number'] ?? '';
          _bioController.text = profile['bio'] ?? '';
        }
      } catch (e) {
        // Handle error silently
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserFriendlyMessage(e)),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserFriendlyMessage(e)),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkGradient : AppTheme.cardGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context, isDark, theme),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Profile Picture
                        _buildProfilePicture(isDark, theme),
                        const SizedBox(height: 32),
                        // Form Fields
                        _buildFormFields(isDark, theme),
                        const SizedBox(height: 32),
                        // Save Button
                        GradientButton(
                          text: 'Save Changes',
                          gradient: EnhancedTheme.premiumGradient,
                          icon: Icons.check_rounded,
                          isLoading: _isLoading,
                          onPressed: _isLoading
                              ? null
                              : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() {
                                _isLoading = true;
                              });

                              try {
                                final userId =
                                    _supabase.auth.currentUser?.id;
                                if (userId != null) {
                                  String? avatarUrl;

                                  // Upload new profile picture if selected
                                  if (_profileImage != null) {
                                    try {
                                      final extension = _profileImage!
                                          .path
                                          .split('.')
                                          .last;
                                      
                                      // Folder structure required by RLS: userId/filename
                                      final fileName =
                                          '$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';
                                      
                                      final fileBytes =
                                      await _profileImage!
                                          .readAsBytes();

                                      await _supabase.storage
                                          .from('avatars')
                                          .uploadBinary(
                                        fileName,
                                        fileBytes,
                                        fileOptions: FileOptions(
                                          cacheControl: '3600',
                                          upsert: true,
                                        ),
                                      );

                                      avatarUrl = _supabase.storage
                                          .from('avatars')
                                          .getPublicUrl(fileName);
                                    } catch (e) {
                                      ErrorHandler.logError(
                                        e,
                                        context: 'Profile picture upload',
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to upload image: ${ErrorHandler.getUserFriendlyMessage(e)}'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                      // Don't proceed with profile update if image upload was intended but failed
                                      setState(() {
                                        _isLoading = false;
                                      });
                                      return;
                                    }
                                  }

                                  await _supabase
                                      .from('user_profiles')
                                      .update({
                                    'phone_number':
                                    _phoneController.text
                                        .trim()
                                        .isEmpty
                                        ? null
                                        : _phoneController.text
                                        .trim(),
                                    'bio':
                                    _bioController.text
                                        .trim()
                                        .isEmpty
                                        ? null
                                        : _bioController.text.trim(),
                                    if (avatarUrl != null)
                                      'avatar_url': avatarUrl,
                                  })
                                      .eq('id', userId);

                                  // Notify AuthController to reload profile
                                  await _authController.reloadUserProfile();

                                  if (mounted) {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Profile updated successfully!',
                                        ),
                                        backgroundColor:
                                        EnhancedTheme.accentEmerald,
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error updating profile: ${e.toString()}',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              }
                            }
                          },
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: EnhancedTheme.premiumGradient),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Edit Profile',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePicture(bool isDark, ThemeData theme) {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: EnhancedTheme.premiumGradient,
            shape: BoxShape.circle,
            boxShadow: EnhancedTheme.glowEffect,
          ),
          child: Obx(
                () => ClipOval(
              child: _profileImage != null
                  ? Image.file(_profileImage!, fit: BoxFit.cover)
                  : (_authController.currentUser.value?.avatarUrl != null &&
                  _authController
                      .currentUser
                      .value!
                      .avatarUrl!
                      .isNotEmpty
                  ? Image.network(
                _authController.currentUser.value!.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 60,
                  );
                },
              )
                  : const Icon(
                Icons.person,
                color: Colors.white,
                size: 60,
              )),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: EnhancedTheme.oceanGradient,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            onSelected: (value) {
              if (value == 'camera') {
                _takePhoto();
              } else if (value == 'gallery') {
                _pickImage();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'camera',
                child: Row(
                  children: [
                    Icon(Icons.camera_alt),
                    SizedBox(width: 8),
                    Text('Take Photo'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'gallery',
                child: Row(
                  children: [
                    Icon(Icons.photo_library),
                    SizedBox(width: 8),
                    Text('Choose from Gallery'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields(bool isDark, ThemeData theme) {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Full Name',
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _emailController,
          readOnly: true,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _bioController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Bio',
            hintText: 'Tell us about yourself...',
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
      ],
    );
  }
}
