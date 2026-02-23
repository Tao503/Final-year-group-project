import 'dart:io';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // File-based storage as fallback when secure storage fails
  static Future<File> _getSessionFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/session.json');
  }

  // User session storage
  static Future<void> saveUserSession(String userId, String email) async {
    await _storage.write(key: 'user_id', value: userId);
    await _storage.write(key: 'user_email', value: email);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  static Future<String?> getUserEmail() async {
    return await _storage.read(key: 'user_email');
  }

  // Session token storage (for Remember Me)
  // Uses file-based storage as fallback when secure storage fails
  static Future<void> saveSessionTokens(
    String accessToken,
    String refreshToken,
  ) async {
    // Try secure storage first
    try {
      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);
      print('✅ Session tokens saved to secure storage');
      return;
    } catch (e) {
      print('⚠️ Secure storage failed, trying file storage: $e');
    }

    // Fallback to file storage
    try {
      final file = await _getSessionFile();
      final data = {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await file.writeAsString(jsonEncode(data));
      print('✅ Session tokens saved to file');
    } catch (e) {
      print('⚠️ File storage also failed: $e');
    }
  }

  static Future<Map<String, String?>> getSessionTokens() async {
    // Try secure storage first
    try {
      final accessToken = await _storage.read(key: 'access_token');
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (accessToken != null) {
        print('✅ Session tokens read from secure storage');
        return {'access_token': accessToken, 'refresh_token': refreshToken};
      }
    } catch (e) {
      print('⚠️ Secure storage read failed, trying file storage: $e');
    }

    // Fallback to file storage
    try {
      final file = await _getSessionFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;

        // Check if session is not too old (e.g., 30 days)
        if (data['timestamp'] != null) {
          final timestamp = DateTime.parse(data['timestamp']);
          final now = DateTime.now();
          if (now.difference(timestamp).inDays > 30) {
            print('⚠️ Session expired, clearing');
            await file.delete();
            return {'access_token': null, 'refresh_token': null};
          }
        }

        print('✅ Session tokens read from file');
        return {
          'access_token': data['access_token'] as String?,
          'refresh_token': data['refresh_token'] as String?,
        };
      }
    } catch (e) {
      print('⚠️ File storage read failed: $e');
    }

    return {'access_token': null, 'refresh_token': null};
  }

  static Future<void> clearUserSession() async {
    // Try secure storage first
    try {
      await _storage.delete(key: 'user_id');
      await _storage.delete(key: 'user_email');
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
    } catch (e) {
      print('⚠️ Could not clear secure storage: $e');
    }

    // Also clear file storage
    try {
      final file = await _getSessionFile();
      if (await file.exists()) {
        await file.delete();
        print('✅ Session file deleted');
      }
    } catch (e) {
      print('⚠️ Could not delete session file: $e');
    }
  }

  // Remember Me preference (with file fallback)
  static Future<void> setRememberMe(bool value) async {
    // Try secure storage first
    try {
      await saveBool('remember_me', value);
      print('✅ Remember Me saved to secure storage');
      return;
    } catch (e) {
      print('⚠️ Secure storage failed for Remember Me, trying file: $e');
    }

    // Fallback to file storage
    try {
      final file = await _getSessionFile();
      final data = <String, dynamic>{};
      if (await file.exists()) {
        final content = await file.readAsString();
        data.addAll(jsonDecode(content) as Map<String, dynamic>);
      }
      data['remember_me'] = value;
      await file.writeAsString(jsonEncode(data));
      print('✅ Remember Me saved to file');
    } catch (e) {
      print('⚠️ File storage also failed for Remember Me: $e');
    }
  }

  static Future<bool> getRememberMe() async {
    // Try secure storage first
    try {
      final value = await getBool('remember_me');
      if (value != null) {
        return value;
      }
    } catch (e) {
      print('⚠️ Secure storage read failed for Remember Me, trying file: $e');
    }

    // Fallback to file storage
    try {
      final file = await _getSessionFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        return data['remember_me'] as bool? ?? false;
      }
    } catch (e) {
      print('⚠️ File storage read failed for Remember Me: $e');
    }

    return false;
  }

  // App preferences
  static Future<void> saveBool(String key, bool value) async {
    await _storage.write(key: key, value: value.toString());
  }

  static Future<bool?> getBool(String key) async {
    final value = await _storage.read(key: key);
    return value != null ? value.toLowerCase() == 'true' : null;
  }

  static Future<void> saveString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> getString(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> removeKey(String key) async {
    await _storage.delete(key: key);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
