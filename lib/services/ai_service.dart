import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter/material.dart';

class AIService {
  // Detect item label from image using ML Kit
  static Future<String?> detectItemLabel(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final imageLabeler = ImageLabeler(options: ImageLabelerOptions());

      final labels = await imageLabeler.processImage(inputImage);
      await imageLabeler.close();

      if (labels.isEmpty) return null;

      // Sort by confidence
      labels.sort((a, b) => b.confidence.compareTo(a.confidence));

      // Get top 3 labels with confidence > 0.3
      final topLabels = labels
          .where((label) => label.confidence > 0.3)
          .take(3)
          .toList();

      if (topLabels.isEmpty) return labels.first.label;

      // Prefer more specific labels (shorter, more specific terms)
      // Filter out generic terms like "object", "thing", "item"
      final specificLabels = topLabels.where((label) {
        final labelLower = label.label.toLowerCase();
        return !labelLower.contains('object') &&
            !labelLower.contains('thing') &&
            !labelLower.contains('item') &&
            !labelLower.contains('stuff') &&
            labelLower.length < 20; // Prefer shorter, more specific labels
      }).toList();

      // Use most specific label if available, otherwise use highest confidence
      if (specificLabels.isNotEmpty) {
        return specificLabels.first.label;
      }

      return topLabels.first.label;
    } catch (e) {
      print('Error detecting label: $e');
      return null;
    }
  }

  // Detect dominant color from image (improved with multiple color analysis)
  static Future<String?> detectColor(File imageFile) async {
    try {
      final imageProvider = FileImage(imageFile);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
      );

      // Get multiple colors from palette for better accuracy
      final colors = <Color>[];

      // Add dominant color
      if (paletteGenerator.dominantColor != null) {
        colors.add(paletteGenerator.dominantColor!.color);
      }

      // Add vibrant colors (usually more accurate for objects)
      if (paletteGenerator.vibrantColor != null) {
        colors.add(paletteGenerator.vibrantColor!.color);
      }
      if (paletteGenerator.mutedColor != null) {
        colors.add(paletteGenerator.mutedColor!.color);
      }

      // Add other palette colors
      paletteGenerator.colors.forEach((color) {
        if (!colors.contains(color)) {
          colors.add(color);
        }
      });

      if (colors.isEmpty) return null;

      // Analyze all colors and pick the most representative one
      // Prefer vibrant colors over muted ones for object detection
      Color? bestColor;

      // First try vibrant color (usually most accurate for objects)
      if (paletteGenerator.vibrantColor != null) {
        bestColor = paletteGenerator.vibrantColor!.color;
      }
      // Then try dominant color
      else if (paletteGenerator.dominantColor != null) {
        bestColor = paletteGenerator.dominantColor!.color;
      }
      // Fallback to first color
      else if (colors.isNotEmpty) {
        bestColor = colors.first;
      }

      if (bestColor != null) {
        return _colorToName(bestColor);
      }

      return null;
    } catch (e) {
      print('Error detecting color: $e');
      return null;
    }
  }

  // Convert Color to color name (improved mapping with HSL for better accuracy)
  static String _colorToName(Color color) {
    final r = color.red;
    final g = color.green;
    final b = color.blue;

    // Calculate brightness and saturation for better color detection
    final max = [r, g, b].reduce((a, b) => a > b ? a : b);
    final min = [r, g, b].reduce((a, b) => a < b ? a : b);
    final brightness = (max + min) / 2 / 255;
    final saturation = max == 0 ? 0 : (max - min) / max;

    // Very dark colors
    if (brightness < 0.15) return 'Black';

    // Very light colors
    if (brightness > 0.85 && saturation < 0.2) return 'White';

    // Low saturation = gray
    if (saturation < 0.2) {
      if (brightness < 0.5) return 'Black';
      if (brightness < 0.7) return 'Gray';
      return 'White';
    }

    // Calculate hue for color classification
    final delta = max - min;
    double hue = 0;

    if (delta != 0) {
      if (max == r) {
        hue = ((g - b) / delta) % 6;
      } else if (max == g) {
        hue = (b - r) / delta + 2;
      } else {
        hue = (r - g) / delta + 4;
      }
      hue *= 60;
      if (hue < 0) hue += 360;
    }

    // Map hue to color names with better accuracy
    // Red: 0-15, 345-360
    if ((hue >= 0 && hue < 15) || (hue >= 345 && hue <= 360)) {
      if (brightness < 0.4) return 'Black';
      if (brightness > 0.7 && saturation < 0.5) return 'Gray';
      return 'Red';
    }
    // Orange/Yellow: 15-60
    if (hue >= 15 && hue < 60) {
      if (brightness < 0.4) return 'Black';
      if (brightness > 0.8) return 'White';
      // Distinguish between yellow and gold
      if (hue < 45 && brightness < 0.7) return 'Yellow';
      return 'Yellow';
    }
    // Green: 60-150
    if (hue >= 60 && hue < 150) {
      if (brightness < 0.4) return 'Black';
      // Dark green detection
      if (brightness < 0.5 && saturation > 0.4) return 'Green';
      if (brightness < 0.6) return 'Green';
      return 'Green';
    }
    // Cyan/Blue: 150-240
    if (hue >= 150 && hue < 240) {
      if (brightness < 0.4) return 'Black';
      if (brightness > 0.8 && saturation < 0.5) return 'White';
      return 'Blue';
    }
    // Magenta/Purple: 240-300
    if (hue >= 240 && hue < 300) {
      if (brightness < 0.4) return 'Black';
      return 'Blue'; // Map purple to blue for dropdown
    }
    // Red-Purple: 300-345
    if (hue >= 300 && hue < 345) {
      if (brightness < 0.4) return 'Black';
      return 'Red';
    }

    // Fallback: use dominant RGB channel
    if (r > g && r > b) {
      if (brightness < 0.4) return 'Black';
      return 'Red';
    }
    if (g > r && g > b) {
      if (brightness < 0.4) return 'Black';
      return 'Green';
    }
    if (b > r && b > g) {
      if (brightness < 0.4) return 'Black';
      return 'Blue';
    }

    // Default fallback
    if (brightness < 0.3) return 'Black';
    if (brightness > 0.7) return 'White';
    return 'Gray';
  }

  // Map AI-detected label to Lost & Found category
  static String mapLabelToCategory(String? itemLabel) {
    if (itemLabel == null) return 'Accessories';

    final label = itemLabel.toLowerCase();

    // Map to Lost & Found categories: Electronics, Books, Clothing, ID/Card, Accessories
    if (label.contains('phone') ||
        label.contains('laptop') ||
        label.contains('computer') ||
        label.contains('tablet') ||
        label.contains('electronic') ||
        label.contains('charger') ||
        label.contains('headphone') ||
        label.contains('earphone') ||
        label.contains('camera')) {
      return 'Electronics';
    }
    if (label.contains('book') ||
        label.contains('textbook') ||
        label.contains('notebook') ||
        label.contains('magazine') ||
        label.contains('journal')) {
      return 'Books';
    }
    if (label.contains('cloth') ||
        label.contains('shirt') ||
        label.contains('dress') ||
        label.contains('jacket') ||
        label.contains('pants') ||
        label.contains('shoe') ||
        label.contains('bag') ||
        label.contains('backpack') ||
        label.contains('hat')) {
      return 'Clothing';
    }
    if (label.contains('card') ||
        label.contains('id') ||
        label.contains('license') ||
        label.contains('passport') ||
        label.contains('wallet') ||
        label.contains('key')) {
      return 'ID/Card';
    }

    // Default to Accessories for everything else
    return 'Accessories';
  }

  // Map AI-detected color to dropdown color options
  static String mapColorToDropdown(String? detectedColor) {
    if (detectedColor == null) return 'Black';

    final color = detectedColor.toLowerCase();

    // Map to available dropdown options: Black, White, Blue, Red, Green, Yellow, Gray
    // More comprehensive mapping
    if (color.contains('black') || color.contains('dark')) return 'Black';
    if (color.contains('white') || color.contains('light')) return 'White';
    if (color.contains('blue') || color.contains('cyan')) return 'Blue';
    if (color.contains('red') || color.contains('magenta')) return 'Red';
    if (color.contains('green')) return 'Green';
    if (color.contains('yellow') ||
        color.contains('gold') ||
        color.contains('orange'))
      return 'Yellow';
    if (color.contains('gray') ||
        color.contains('grey') ||
        color.contains('silver') ||
        color.contains('gray'))
      return 'Gray';

    // Default fallback
    return 'Black';
  }

  // Recommend donation category based on item label
  static String recommendDonationCategory(String? itemLabel) {
    if (itemLabel == null) return 'General';

    final label = itemLabel.toLowerCase();

    // Rule-based recommendation
    if (label.contains('book') ||
        label.contains('textbook') ||
        label.contains('notebook')) {
      return 'Library/Students';
    }
    if (label.contains('cloth') ||
        label.contains('shirt') ||
        label.contains('dress') ||
        label.contains('jacket') ||
        label.contains('pants')) {
      return 'Orphanage';
    }
    if (label.contains('phone') ||
        label.contains('laptop') ||
        label.contains('computer') ||
        label.contains('tablet') ||
        label.contains('electronic')) {
      return 'IT Department or Lab';
    }
    if (label.contains('toy') || label.contains('game')) {
      return 'Orphanage';
    }
    if (label.contains('food') || label.contains('snack')) {
      return 'Food Bank';
    }

    return 'General';
  }
}
