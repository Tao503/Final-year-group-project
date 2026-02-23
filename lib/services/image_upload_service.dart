import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'supabase_service.dart';

class ImageUploadService {
  static final _supabase = SupabaseService.client;
  static const _uuid = Uuid();

  // Upload item image
  static Future<String?> uploadItemImage(File imageFile) async {
    try {
      final fileName = '${_uuid.v4()}${path.extension(imageFile.path)}';
      final fileBytes = await imageFile.readAsBytes();

      await _supabase.storage
          .from('item-images')
          .uploadBinary(fileName, fileBytes);

      final imageUrl = _supabase.storage
          .from('item-images')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Upload donation image
  static Future<String?> uploadDonationImage(File imageFile) async {
    try {
      final fileName = '${_uuid.v4()}${path.extension(imageFile.path)}';
      final fileBytes = await imageFile.readAsBytes();

      await _supabase.storage
          .from('donation-images')
          .uploadBinary(fileName, fileBytes);

      final imageUrl = _supabase.storage
          .from('donation-images')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Upload event image
  static Future<String?> uploadEventImage(File imageFile) async {
    try {
      final fileName = '${_uuid.v4()}${path.extension(imageFile.path)}';
      final fileBytes = await imageFile.readAsBytes();

      // Upload image
      await _supabase.storage
          .from('event-images')
          .uploadBinary(fileName, fileBytes);

      final imageUrl = _supabase.storage
          .from('event-images')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      print('Error uploading event image: $e');
      // If RLS error, provide helpful message
      if (e.toString().contains('row-level security') ||
          e.toString().contains('403') ||
          e.toString().contains('Unauthorized')) {
        print(
          '⚠️ Storage RLS Policy Error: Make sure you have set up RLS policies for the event-images bucket in Supabase Dashboard',
        );
        print('   Go to: Storage > event-images > Policies');
        print(
          '   Add policies for INSERT and SELECT operations for authenticated users',
        );
      }
      return null;
    }
  }

  // Delete image from storage
  static Future<void> deleteImage(String imageUrl, String bucket) async {
    try {
      final fileName = path.basename(imageUrl);
      await _supabase.storage.from(bucket).remove([fileName]);
    } catch (e) {
      print('Error deleting image: $e');
    }
  }
}
