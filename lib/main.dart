import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'services/supabase_service.dart';
import 'controllers/auth_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/chat_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  
  try {
    await SupabaseService.initialize(
      supabaseUrl: 'https://uvbixnbbbalqqhhzxjml.supabase.co',
      supabaseAnonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2Yml4bmJiYmFscXFoaHp4am1sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY1MDEwNzMsImV4cCI6MjA4MjA3NzA3M30.W62r_n4pCM1s5FCrVnd-ywu6845C1FTm53ltXZ9DYSs',
    );
  } catch (e) {
    
    debugPrint('Supabase init error (non-fatal): $e');
  }

  
  Get.put(AuthController());
  Get.put(ThemeController());
  Get.put(ChatController());

  runApp(const NileConnectApp());
}

class NileConnectApp extends StatelessWidget {
  const NileConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Obx(
      () => GetMaterialApp(
        title: 'Nile Find',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode.value,
        home: const SplashScreen(),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
              ),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
