import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/gradient_widgets.dart';
import '../../controllers/lost_found_controller.dart';
import '../../services/ai_service.dart';

class PostLostFoundScreen extends StatefulWidget {
  const PostLostFoundScreen({super.key});

  @override
  State<PostLostFoundScreen> createState() => _PostLostFoundScreenState();
}

class _PostLostFoundScreenState extends State<PostLostFoundScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _dateController = TextEditingController();

  String _postType = 'lost'; 
  String _selectedCategory = 'Accessories';
  String _selectedColor = 'Black';
  File? _imageFile;
  bool _isDetecting = false;

  final LostFoundController _controller = Get.find<LostFoundController>();
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _categories = [
    'Electronics',
    'Books',
    'Clothing',
    'ID/Card',
    'Accessories',
  ];

  final List<String> _colors = [
    'Black',
    'White',
    'Blue',
    'Red',
    'Green',
    'Yellow',
    'Gray',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        print('🖼️ Image selected: ${image.path}');
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

  Future<void> _handleAIDetection() async {
    if (_imageFile == null) return;

    setState(() {
      _isDetecting = true;
    });

    try {
      print('🔍 AI Detection starting...');
      final aiResult = await AIService.analyzeImage(_imageFile!, _categories);
      print('🤖 AI Result: $aiResult');
      
      final detectedColor = await AIService.detectColor(_imageFile!);
      print('🎨 AI detected color: $detectedColor');

      if (mounted) {
        setState(() {
          _isDetecting = false;

          
          if (aiResult != null) {
            final label = aiResult['label'] ?? '';
            final category = aiResult['category'] ?? '';
            
            print('✅ AI detected: Label="$label", Category="$category"');
            
            _nameController.text = label;
            if (_categories.contains(category)) {
              _selectedCategory = category;
            }
          }
          
          if (detectedColor != null) {
            final mappedColor = AIService.mapColorToDropdown(detectedColor);
            print('🖌️ Mapped color to: "$mappedColor"');
            if (_colors.contains(mappedColor)) {
              _selectedColor = mappedColor;
            }
          }
        });

        
        final detectedInfo = <String>[];
        if (aiResult != null) {
          detectedInfo.add('Label: ${aiResult['label']}');
          detectedInfo.add('Category: ${aiResult['category']}');
        }
        if (detectedColor != null) detectedInfo.add('Color: $detectedColor');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              detectedInfo.isEmpty
                  ? 'Image selected. AI analysis complete.'
                  : 'AI detected: ${detectedInfo.join(", ")}. Category and color auto-filled!',
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

    
    DateTime? dateFound;
    if (_dateController.text.isNotEmpty) {
      try {
        final dateParts = _dateController.text.split('-');
        if (dateParts.length == 3) {
          dateFound = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
          );
        }
      } catch (e) {
        print('⚠️ Error parsing date: $e');
      }
    }

    final success = await _controller.postItem(
      title: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      type: _postType,
      category: _selectedCategory,
      color: _selectedColor,
      dateFound: dateFound,
      imageFile: _imageFile,
    );

    if (mounted) {
      if (success) {
        Get.back();
        Get.snackbar(
          'Success',
          '${_postType == 'lost' ? 'Lost' : 'Found'} item posted successfully!',
          backgroundColor: AppTheme.accentEmerald,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to post item. Please try again.',
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
                        
                        _buildTypeSelection(isDark, theme),
                        const SizedBox(height: 24),
                        
                        _buildImageUpload(isDark, theme),
                        const SizedBox(height: 24),
                        
                        _buildFormFields(isDark, theme),
                        const SizedBox(height: 32),
                        
                        Obx(
                          () => GradientButton(
                            text: 'Submit Report',
                            gradient: AppTheme.accentGradient,
                            icon: Icons.send,
                            isLoading: _controller.isLoading.value,
                            onPressed: _submitForm,
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
          bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
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
                  'Post Lost/Found Item',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Let AI help you describe your item',
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

  Widget _buildTypeSelection(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeButton(
                'Lost',
                Icons.error_outline,
                _postType == 'lost',
                const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFFF6B6B)],
                ),
                () => setState(() => _postType = 'lost'),
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeButton(
                'Found',
                Icons.check_circle,
                _postType == 'found',
                const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                ),
                () => setState(() => _postType = 'found'),
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeButton(
    String label,
    IconData icon,
    bool isSelected,
    Gradient gradient,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected
              ? null
              : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.white.withOpacity(0.2) : Colors.grey[300]!),
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
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
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
              child: _buildUploadBox(Icons.camera_alt, 'Camera', () async {
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
                          'Camera not available. Use Gallery or post without image.',
                        ),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                  print('⚠️ Camera error: $e');
                }
              }, isDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildUploadBox(
                Icons.image,
                'Gallery',
                _pickImage,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _isDetecting ? null : _handleAIDetection,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppTheme.successGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentEmerald.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: _isDetecting
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'AI Detect',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _imageFile!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUploadBox(
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
            color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey[300]!,
            width: 1.5,
            style: BorderStyle.solid,
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
            hintText: 'e.g., Black Leather Wallet',
            labelStyle: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.8),
          ),
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
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
            hintText: 'Add details like brand, distinguishing marks, etc.',
            labelStyle: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.8),
          ),
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        const SizedBox(height: 20),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  hintText: 'Library, Cafeteria...',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.8),
                ),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Date',
                  hintText: 'Select date',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.8),
                  suffixIcon: Icon(
                    Icons.calendar_today,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    _dateController.text =
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
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
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedColor,
                decoration: InputDecoration(
                  labelText: 'Color',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.8),
                ),
                items: _colors.map((color) {
                  return DropdownMenuItem(
                    value: color,
                    child: Text(
                      color,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedColor = value);
                  }
                },
                dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
