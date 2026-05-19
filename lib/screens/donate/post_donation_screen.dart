import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/gradient_widgets.dart';
import '../../controllers/donation_controller.dart';
import '../../services/ai_service.dart';

class PostDonationScreen extends StatefulWidget {
  const PostDonationScreen({super.key});

  @override
  State<PostDonationScreen> createState() => _PostDonationScreenState();
}

class _PostDonationScreenState extends State<PostDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'General';
  File? _imageFile;
  bool _isDetecting = false;
  String? _aiRecommendedCategory;

  final DonationController _controller = Get.find<DonationController>();
  final ImagePicker _imagePicker = ImagePicker();

  
  final List<String> _categories = [
    'General',
    'Library/Students',
    'Orphanage',
    'IT Department or Lab',
    'Food Bank',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
          _imageFile = File(image.path);
        });
        await _handleAIDetection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Image picker not available. You can still post without an image.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print('⚠️ Image picker error: $e');
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
          _imageFile = File(image.path);
        });
        await _handleAIDetection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Camera not available. You can still post without an image.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print('⚠️ Camera error: $e');
    }
  }

  Future<void> _handleAIDetection() async {
    if (_imageFile == null) return;

    setState(() {
      _isDetecting = true;
    });

    try {
      print('🔍 AI Donation Detection starting...');
      final aiResult = await AIService.analyzeImage(_imageFile!, _categories);
      print('🤖 AI Donation Result: $aiResult');
      
      final detectedColor = await AIService.detectColor(_imageFile!);

      if (mounted) {
        setState(() {
          _isDetecting = false;
          
          if (aiResult != null) {
            final label = aiResult['label'] ?? '';
            final category = aiResult['category'] ?? '';
            
            _nameController.text = label;
            _aiRecommendedCategory = category;
            
            if (_categories.contains(category)) {
              _selectedCategory = category;
            }
          }
        });

        
        final detectedInfo = <String>[];
        if (aiResult != null) detectedInfo.add('Label: ${aiResult['label']}');
        if (detectedColor != null) detectedInfo.add('Color: $detectedColor');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              detectedInfo.isEmpty
                  ? 'Image selected. AI analysis complete.'
                  : 'AI detected: ${detectedInfo.join(", ")}. Category auto-filled!',
            ),
            backgroundColor: AppTheme.accentEmerald,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('⚠️ AI detection error: $e');
      if (mounted) {
        setState(() {
          _isDetecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'AI detection failed, but you can still post manually.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _controller.postDonation(
      title: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      imageFile: _imageFile,
    );

    if (mounted) {
      if (success) {
        Get.back();
        Get.snackbar(
          'Success',
          'Donation posted successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.accentEmerald,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to post donation. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
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
          child: Column(
            children: [
              
              _buildHeader(isDark, theme),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        _buildImageUpload(isDark, theme),
                        const SizedBox(height: 24),
                        
                        _buildFormFields(isDark, theme),
                        
                        if (_aiRecommendedCategory != null &&
                            _aiRecommendedCategory != _selectedCategory) ...[
                          const SizedBox(height: 20),
                          _buildAIRecommendation(isDark, theme),
                        ],
                        const SizedBox(height: 32),
                        
                        Obx(() => GradientButton(
                              text: _controller.isLoading.value
                                  ? 'Posting...'
                                  : 'Post Donation',
                              gradient: AppTheme.accentGradient,
                              icon: Icons.send,
                              onPressed: _controller.isLoading.value
                                  ? null
                                  : _submitForm,
                            )),
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

  Widget _buildHeader(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.6),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            color: isDark ? Colors.white : Colors.black87,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Post Donation',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Give what you don't need",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUpload(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Image',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildImageButton(
                Icons.photo_library,
                'Gallery',
                _pickImage,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildImageButton(
                Icons.camera_alt,
                'Camera',
                _takePhoto,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _imageFile != null ? _handleAIDetection : null,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: _imageFile != null
                        ? AppTheme.primaryPurple.withOpacity(0.1)
                        : (isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _imageFile != null
                          ? AppTheme.primaryPurple
                          : (isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey[300]!),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isDetecting)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryPurple,
                          ),
                        )
                      else
                        Icon(
                          Icons.auto_awesome,
                          color: _imageFile != null
                              ? AppTheme.primaryPurple
                              : (isDark ? Colors.white30 : Colors.black26),
                          size: 28,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'AI Detect',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _imageFile != null
                              ? AppTheme.primaryPurple
                              : (isDark ? Colors.white30 : Colors.black26),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_imageFile != null) ...[
          const SizedBox(height: 12),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _imageFile!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _imageFile = null;
                      _aiRecommendedCategory = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildImageButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.2)
                : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Item Name',
            hintText: 'e.g., Discrete Math Textbook',
            labelStyle: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: AppTheme.primaryTeal,
                width: 2,
              ),
            ),
          ),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter item name';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Condition, usage, notes...',
            labelStyle: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: AppTheme.primaryTeal,
                width: 2,
              ),
            ),
          ),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter description';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            labelText: 'Category',
            labelStyle: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: AppTheme.primaryTeal,
                width: 2,
              ),
            ),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(
                category,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedCategory = value);
            }
          },
          dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
        ),
      ],
    );
  }

  Widget _buildAIRecommendation(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome,
            color: AppTheme.primaryPurple,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Recommendation',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.primaryPurple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI suggests: $_aiRecommendedCategory',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    
                    if (_categories.contains(_aiRecommendedCategory)) {
                      setState(() {
                        _selectedCategory = _aiRecommendedCategory!;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Recommended category not available in list.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Use AI Recommendation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
