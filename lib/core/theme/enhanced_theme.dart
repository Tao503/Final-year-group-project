import 'package:flutter/material.dart';


class EnhancedTheme {
  
  static const Color primaryIndigo = Color(0xFF6366F1); 
  static const Color primaryViolet = Color(0xFF8B5CF6); 
  static const Color primaryPurple = Color(0xFF9333EA); 
  static const Color primaryPink = Color(0xFFEC4899); 
  
  static const Color accentCyan = Color(0xFF06B6D4); 
  static const Color accentTeal = Color(0xFF14B8A6); 
  static const Color accentEmerald = Color(0xFF10B981); 
  static const Color accentLime = Color(0xFF84CC16); 
  
  static const Color accentOrange = Color(0xFFF97316); 
  static const Color accentAmber = Color(0xFFF59E0B); 
  static const Color accentYellow = Color(0xFFEAB308); 
  
  static const Color accentRose = Color(0xFFF43F5E); 
  static const Color accentRed = Color(0xFFEF4444); 
  
  
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);
  
  
  static const Color darkSurface = Color(0xFF0A0A0F);
  static const Color darkCard = Color(0xFF151520);
  static const Color darkElevated = Color(0xFF1F1F2E);
  
  
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryIndigo, primaryViolet, primaryPink],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentCyan, accentTeal, accentEmerald],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentOrange, accentAmber, accentYellow],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const LinearGradient energyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentRose, accentRed, accentOrange],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentEmerald, accentLime],
    stops: [0.0, 1.0],
  );
  
  
  static LinearGradient glassGradient(bool isDark) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isDark
        ? [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ]
        : [
            Colors.white.withOpacity(0.8),
            Colors.white.withOpacity(0.6),
          ],
  );
  
  
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: primaryIndigo.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
  
  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: primaryIndigo.withOpacity(0.2),
      blurRadius: 30,
      offset: const Offset(0, 15),
    ),
  ];
  
  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: primaryIndigo.withOpacity(0.3),
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
  ];
  
  
  static List<BoxShadow> get glowEffect => [
    BoxShadow(
      color: primaryIndigo.withOpacity(0.5),
      blurRadius: 30,
      spreadRadius: 5,
    ),
  ];
}

