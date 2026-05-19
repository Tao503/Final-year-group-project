import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter/material.dart';
import '../core/config/app_config.dart';

class AIService {
  
  static final _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: AppConfig.geminiApiKey,
    systemInstruction: Content.system('''
      You are an elite item recognition AI for the Ummu (Nile Find) community platform.
      Your goal is to accurately identify objects from images to help people find lost items or categorize donations.
      
      CRITICAL RULES:
      1. LABEL EXTRACTION: Extract the primary asset name. Be specific (e.g., "Silver iPhone 13", "Black Nike Backpack", "Dorm Room Key").
      2. FORMAT: Return ONLY the label string. No conversation, no explanations.
      3. ACCURACY: If you cannot identify the object clearly, respond with "Unknown Object".
    '''),
  );

  
  static Future<Map<String, String>?> analyzeImage(File imageFile, List<String> categories) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final categoriesList = categories.join(', ');
      
      final content = [
        Content.multi([
          DataPart('image/jpeg', bytes),
          TextPart('''
            Identify the main object in this image.
            
            Return ONLY a valid JSON object matching this schema:
            {
              "label": "Specific Item Name (e.g., 'Silver iPhone 13')",
              "category": "Must be EXACTLY one of: [$categoriesList]"
            }
          '''),
        ])
      ];

      final response = await _model.generateContent(content);
      print('🤖 Gemini raw response: ${response.text}');
      
      String? rawText = response.text?.trim();
      if (rawText == null || rawText.isEmpty) return null;

      if (rawText.contains('```json')) {
        rawText = rawText.split('```json').last.split('```').first.trim();
      } else if (rawText.contains('```')) {
        rawText = rawText.split('```').where((e) => e.trim().isNotEmpty).first.trim();
      }

      final jsonMap = Map<String, dynamic>.from(json.decode(rawText));
      return {
        'label': jsonMap['label']?.toString() ?? 'Unknown Item',
        'category': jsonMap['category']?.toString() ?? categories.first,
      };
    } catch (e) {
      debugPrint('AI Analysis Error: $e');
      return null;
    }
  }

  
  static Future<String?> detectItemLabel(File imageFile) async {
    final result = await analyzeImage(imageFile, ['Accessories', 'Electronics', 'Books', 'Clothing', 'ID/Card']);
    return result?['label'];
  }

  
  static Future<String?> detectColor(File imageFile) async {
    try {
      final imageProvider = FileImage(imageFile);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
      );

      
      final colors = <Color>[];

      
      if (paletteGenerator.dominantColor != null) {
        colors.add(paletteGenerator.dominantColor!.color);
      }

      
      if (paletteGenerator.vibrantColor != null) {
        colors.add(paletteGenerator.vibrantColor!.color);
      }
      if (paletteGenerator.mutedColor != null) {
        colors.add(paletteGenerator.mutedColor!.color);
      }

      
      paletteGenerator.colors.forEach((color) {
        if (!colors.contains(color)) {
          colors.add(color);
        }
      });

      if (colors.isEmpty) return null;

      
      
      Color? bestColor;

      
      if (paletteGenerator.vibrantColor != null) {
        bestColor = paletteGenerator.vibrantColor!.color;
      }
      
      else if (paletteGenerator.dominantColor != null) {
        bestColor = paletteGenerator.dominantColor!.color;
      }
      
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

  
  static String _colorToName(Color color) {
    final r = color.red;
    final g = color.green;
    final b = color.blue;

    
    final max = [r, g, b].reduce((a, b) => a > b ? a : b);
    final min = [r, g, b].reduce((a, b) => a < b ? a : b);
    final brightness = (max + min) / 2 / 255;
    final saturation = max == 0 ? 0 : (max - min) / max;

    
    if (brightness < 0.15) return 'Black';

    
    if (brightness > 0.85 && saturation < 0.2) return 'White';

    
    if (saturation < 0.2) {
      if (brightness < 0.5) return 'Black';
      if (brightness < 0.7) return 'Gray';
      return 'White';
    }

    
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

    
    
    if ((hue >= 0 && hue < 15) || (hue >= 345 && hue <= 360)) {
      if (brightness < 0.4) return 'Black';
      if (brightness > 0.7 && saturation < 0.5) return 'Gray';
      return 'Red';
    }
    
    if (hue >= 15 && hue < 60) {
      if (brightness < 0.4) return 'Black';
      if (brightness > 0.8) return 'White';
      
      if (hue < 45 && brightness < 0.7) return 'Yellow';
      return 'Yellow';
    }
    
    if (hue >= 60 && hue < 150) {
      if (brightness < 0.4) return 'Black';
      
      if (brightness < 0.5 && saturation > 0.4) return 'Green';
      if (brightness < 0.6) return 'Green';
      return 'Green';
    }
    
    if (hue >= 150 && hue < 240) {
      if (brightness < 0.4) return 'Black';
      if (brightness > 0.8 && saturation < 0.5) return 'White';
      return 'Blue';
    }
    
    if (hue >= 240 && hue < 300) {
      if (brightness < 0.4) return 'Black';
      return 'Blue'; 
    }
    
    if (hue >= 300 && hue < 345) {
      if (brightness < 0.4) return 'Black';
      return 'Red';
    }

    
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

    
    if (brightness < 0.3) return 'Black';
    if (brightness > 0.7) return 'White';
    return 'Gray';
  }

  
  static Future<Map<String, String>> getAdvancedRecommendation(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          DataPart('image/jpeg', bytes),
          TextPart('''
            Analyze this item and provide a recommendation for donation in the Nile University community.
            
            Return ONLY a valid JSON object matching this schema:
            {
              "label": "Specific Item Name",
              "category": "Electronics" | "Books" | "Clothing" | "ID/Card" | "Accessories",
              "recommendation": "Specific campus department or local charity (e.g., 'IT Lab', 'Main Library', 'Student Union')",
              "rationale": "Brief reason for this recommendation"
            }
          '''),
        ])
      ];

      final response = await _model.generateContent(content);
      String? rawText = response.text?.trim();
      if (rawText == null || rawText.isEmpty) {
        return {'label': 'Item', 'category': 'Accessories', 'recommendation': 'General Office', 'rationale': 'AI analysis failed'};
      }

      
      if (rawText.contains('```json')) {
        rawText = rawText.split('```json').last.split('```').first.trim();
      } else if (rawText.contains('```')) {
        rawText = rawText.split('```').where((e) => e.trim().isNotEmpty).first.trim();
      }

      final jsonMap = Map<String, dynamic>.from(json.decode(rawText));
      return {
        'label': jsonMap['label']?.toString() ?? 'Item',
        'category': jsonMap['category']?.toString() ?? 'Accessories',
        'recommendation': jsonMap['recommendation']?.toString() ?? 'General Office',
        'rationale': jsonMap['rationale']?.toString() ?? 'AI identified this item.',
      };
    } catch (e) {
      debugPrint('AI Recommendation Error: $e');
      return {'label': 'Item', 'category': 'Accessories', 'recommendation': 'General Office', 'rationale': 'Error: $e'};
    }
  }


  
  static String mapColorToDropdown(String? detectedColor) {
    if (detectedColor == null) return 'Black';

    final color = detectedColor.toLowerCase();

    
    if (color.contains('black') || color.contains('dark')) return 'Black';
    if (color.contains('white') || color.contains('light')) return 'White';
    if (color.contains('blue') || color.contains('cyan')) return 'Blue';
    if (color.contains('red') || color.contains('magenta')) return 'Red';
    if (color.contains('green')) return 'Green';
    if (color.contains('yellow') || color.contains('gold') || color.contains('orange')) return 'Yellow';
    if (color.contains('gray') || color.contains('grey') || color.contains('silver')) return 'Gray';

    return 'Black';
  }
}

