import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/enhanced_theme.dart';
import '../../core/widgets/gradient_widgets.dart';
import '../../core/utils/error_handler.dart';
import '../../controllers/auth_controller.dart';
import '../../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/home_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String email;

  const CompleteProfileScreen({super.key, required this.email});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();
  final _supabase = SupabaseService.client;
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  String? _selectedRole; // 'student' or 'staff'
  File? _profileImage;
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your role (Student or Staff)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure we have a valid session
      var currentUser = _supabase.auth.currentUser;

      // If no user, try to refresh the session
      if (currentUser == null) {
        try {
          // Try to refresh the session
          final session = await _supabase.auth.refreshSession();
          if (session.session != null) {
            currentUser = _supabase.auth.currentUser;
          }
        } catch (e) {
          ErrorHandler.logError(
            e,
            context: 'Session refresh in complete profile',
          );
        }

        // If still no user, check if we have a session token stored
        if (currentUser == null) {
          final session = _supabase.auth.currentSession;
          if (session != null) {
            // Wait a moment for session to be recognized
            await Future.delayed(const Duration(milliseconds: 200));
            currentUser = _supabase.auth.currentUser;
          }
        }

        // If still no user, show error
        if (currentUser == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Session expired. Please sign in again.'),
                backgroundColor: Colors.red,
              ),
            );
            // Navigate back to auth screen
            Get.offAllNamed('/auth');
          }
          return;
        }
      }

      String? avatarUrl;

      // Upload profile picture if selected
      if (_profileImage != null) {
        try {
          final extension = _profileImage!.path.split('.').last;
          final fileName =
              '${currentUser.id}/${DateTime.now().millisecondsSinceEpoch}.$extension';
          final fileBytes = await _profileImage!.readAsBytes();

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

          avatarUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
        } catch (e) {
          // Continue without avatar if upload fails, but show error
          ErrorHandler.logError(e, context: 'Profile picture upload');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload image: ${ErrorHandler.getUserFriendlyMessage(e)}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      // Create profile in database
      final profileData = {
        'id': currentUser.id,
        'full_name': _nameController.text.trim(),
        'email': widget.email,
        'role': _selectedRole,
        if (_selectedRole == 'student') 'student_id': _idController.text.trim(),
        if (_selectedRole == 'staff') 'staff_id': _idController.text.trim(),
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (_phoneController.text.trim().isNotEmpty)
          'phone_number': _phoneController.text.trim(),
        if (_bioController.text.trim().isNotEmpty)
          'bio': _bioController.text.trim(),
      };

      await _supabase.from('user_profiles').insert(profileData);
      
      // Reload user profile in AuthController to ensure state is updated
      await _authController.reloadUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Get.offAll(() => const HomeScreen());
      }
    } catch (e) {
      ErrorHandler.logError(e, context: 'Complete profile');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserFriendlyMessage(e)),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  // Header
                  Text(
                    'Complete Your Profile',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please provide your information to continue',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Profile Picture
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: EnhancedTheme.premiumGradient,
                            shape: BoxShape.circle,
                            boxShadow: EnhancedTheme.glowEffect,
                          ),
                          child: ClipOval(
                            child: _profileImage != null
                                ? Image.file(_profileImage!, fit: BoxFit.cover)
                                : const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: EnhancedTheme.oceanGradient,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 20,
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
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Full Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Role Selection
                  Text(
                    'I am a:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRoleOption(
                          'Student',
                          'student',
                          Icons.school,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRoleOption(
                          'Staff',
                          'staff',
                          Icons.badge,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Student ID or Staff ID Field (conditional)
                  if (_selectedRole != null)
                    TextFormField(
                      controller: _idController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: _selectedRole == 'student'
                            ? 'Student ID'
                            : 'Staff ID',
                        prefixIcon: const Icon(Icons.badge),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _selectedRole == 'student'
                              ? 'Please enter your Student ID'
                              : 'Please enter your Staff ID';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 20),

                  // Email (Read-only)
                  TextFormField(
                    initialValue: widget.email,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  GradientButton(
                    text: 'Complete Profile',
                    gradient: EnhancedTheme.premiumGradient,
                    icon: Icons.check_rounded,
                    isLoading: _isLoading,
                    onPressed: _saveProfile,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption(
      String label,
      String value,
      IconData icon,
      bool isDark,
      ) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = value;
          _idController.clear(); // Clear ID when role changes
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? EnhancedTheme.premiumGradient : null,
          color: isSelected
              ? null
              : (isDark ? Colors.white.withOpacity(0.1) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.white30 : Colors.grey[300]!),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black54),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black54),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
