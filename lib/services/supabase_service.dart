import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class SupabaseService {
  static SupabaseClient? _client;
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  static SupabaseService get instance => _instance;
  static final SupabaseService _instance = SupabaseService._internal();
  SupabaseService._internal();

  static bool _isInitialized = false;

  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    if (_isInitialized) {
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
    } catch (e) {
      // If shared_preferences fails, try to continue without it
      // Supabase will use in-memory storage as fallback
      debugPrint('Supabase initialization warning: $e');
      debugPrint('Continuing with in-memory storage fallback...');

      // Try to initialize anyway - Supabase might work without shared_preferences
      try {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
          ),
        );
        _client = Supabase.instance.client;
        _isInitialized = true;
      } catch (e2) {
        debugPrint('Supabase initialization failed: $e2');
        rethrow;
      }
    }
  }

  // Custom session management
  static Future<void> saveUserSession(String userId, String email) async {
    await StorageService.saveUserSession(userId, email);
  }

  static Future<Map<String, String?>> getStoredUserSession() async {
    final userId = await StorageService.getUserId();
    final email = await StorageService.getUserEmail();
    return {'userId': userId, 'email': email};
  }

  static Future<void> clearUserSession() async {
    await StorageService.clearUserSession();
  }

  // Check if user is authenticated
  static bool get isAuthenticated => client.auth.currentUser != null;

  // Get current user ID
  static String? get currentUserId => client.auth.currentUser?.id;

  // Get current user email
  static String? get currentUserEmail => client.auth.currentUser?.email;
}
