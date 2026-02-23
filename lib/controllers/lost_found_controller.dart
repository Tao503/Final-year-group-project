import 'dart:io';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/item_model.dart';
import '../services/supabase_service.dart';
import '../services/ai_service.dart';
import '../services/image_upload_service.dart';

class LostFoundController extends GetxController {
  final _supabase = SupabaseService.client;
  final _uuid = const Uuid();

  final RxList<ItemModel> items = <ItemModel>[].obs;
  final RxList<ItemModel> similarItems = <ItemModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final Rx<String?> selectedColor = Rx<String?>(null);
  final Rx<String?> selectedCategory = Rx<String?>(null);
  final Rx<String?> selectedLocation = Rx<String?>(null);
  final Rx<String?> selectedType = Rx<String?>(null); // 'lost' or 'found'
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchItems();
  }

  Future<void> fetchItems() async {
    isLoading.value = true;
    try {
      final response = await _supabase
          .from('items')
          .select('*, user_profiles(full_name)')
          .order('created_at', ascending: false);

      items.value = (response as List)
          .map(
            (json) => ItemModel.fromJson({
          ...json,
          'user_name': json['user_profiles']?['full_name'] ?? 'Unknown',
        }),
      )
          .toList();
    } catch (e) {
      print('Error fetching items: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchItems(String keyword) async {
    searchQuery.value = keyword;
    await _applyFilters();
  }

  Future<void> _applyFilters() async {
    isLoading.value = true;
    try {
      final response = await _supabase
          .from('items')
          .select('*, user_profiles(full_name)')
          .order('created_at', ascending: false);

      var filtered = (response as List)
          .map(
            (json) => ItemModel.fromJson({
          ...json,
          'user_name': json['user_profiles']?['full_name'] ?? 'Unknown',
        }),
      )
          .toList();

      // Apply search filter
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        filtered = filtered.where((item) {
          return item.title.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query);
        }).toList();
      }

      // Apply type filter (lost/found)
      if (selectedType.value != null) {
        filtered = filtered.where((item) {
          return item.type == selectedType.value;
        }).toList();
      }

      // Apply color filter
      if (selectedColor.value != null) {
        filtered = filtered.where((item) {
          return item.detectedColor == selectedColor.value;
        }).toList();
      }

      // Apply category filter
      if (selectedCategory.value != null) {
        filtered = filtered.where((item) {
          return item.category == selectedCategory.value;
        }).toList();
      }

      // Apply location filter
      if (selectedLocation.value != null) {
        filtered = filtered.where((item) {
          return item.location?.toLowerCase() == selectedLocation.value?.toLowerCase();
        }).toList();
      }

      // Apply date filter
      if (selectedDate.value != null) {
        final filterDate = selectedDate.value!;
        filtered = filtered.where((item) {
          final itemDate = item.createdAt;
          return itemDate.year == filterDate.year &&
              itemDate.month == filterDate.month &&
              itemDate.day == filterDate.day;
        }).toList();
      }

      items.value = filtered;
    } catch (e) {
      print('Error filtering items: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> filterByColor(String? color) async {
    selectedColor.value = color;
    await _applyFilters();
  }

  Future<void> filterByCategory(String? category) async {
    selectedCategory.value = category;
    await _applyFilters();
  }

  Future<void> filterByLocation(String? location) async {
    selectedLocation.value = location;
    await _applyFilters();
  }

  Future<void> filterByType(String? type) async {
    selectedType.value = type;
    await _applyFilters();
  }

  Future<void> filterByDate(DateTime? date) async {
    selectedDate.value = date;
    await _applyFilters();
  }

  void clearFilters() {
    selectedColor.value = null;
    selectedCategory.value = null;
    selectedLocation.value = null;
    selectedType.value = null;
    selectedDate.value = null;
    _applyFilters();
  }

  Future<void> findSimilarItems(String label, String color) async {
    try {
      final response = await _supabase
          .from('items')
          .select('*, user_profiles(full_name)')
          .or('detected_label.ilike.%$label%,detected_color.eq.$color')
          .order('created_at', ascending: false)
          .limit(5);

      similarItems.value = (response as List)
          .map(
            (json) => ItemModel.fromJson({
          ...json,
          'user_name': json['user_profiles']?['full_name'] ?? 'Unknown',
        }),
      )
          .toList();
    } catch (e) {
      print('Error finding similar items: $e');
    }
  }

  Future<bool> postItem({
    required String title,
    required String description,
    required String location,
    required String type,
    required String category,
    String? color,
    DateTime? dateFound,
    File? imageFile,
  }) async {
    isLoading.value = true;
    try {
      String? imageUrl;
      String? detectedLabel;
      String? detectedColor;

      // Upload image and run AI analysis
      if (imageFile != null) {
        imageUrl = await ImageUploadService.uploadItemImage(imageFile);
        detectedLabel = await AIService.detectItemLabel(imageFile);
        detectedColor = await AIService.detectColor(imageFile);
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final itemId = _uuid.v4();

      await _supabase.from('items').insert({
        'id': itemId,
        'title': title,
        'description': description,
        'location': location,
        'type': type,
        'category': category,
        'color':
        color ?? detectedColor, // Use selected color or AI-detected color
        'image_url': imageUrl,
        'detected_label': detectedLabel,
        'detected_color': detectedColor,
        'date_found': dateFound?.toIso8601String().split(
          'T',
        )[0], // Store as DATE (YYYY-MM-DD)
        'user_id': userId,
        'status': 'open',
      });

      await fetchItems();

      // Find similar items if AI detected something
      if (detectedLabel != null && detectedColor != null) {
        await findSimilarItems(detectedLabel, detectedColor);
      }

      return true;
    } catch (e) {
      print('Error posting item: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> markAsClaimed(String itemId) async {
    try {
      await _supabase
          .from('items')
          .update({'status': 'claimed'})
          .eq('id', itemId);

      await fetchItems();
      return true;
    } catch (e) {
      print('Error marking item as claimed: $e');
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      // Get item to delete image if exists
      final item = items.firstWhere((i) => i.id == itemId);
      if (item.imageUrl != null) {
        await ImageUploadService.deleteImage(item.imageUrl!, 'item-images');
      }

      await _supabase.from('items').delete().eq('id', itemId);
      await fetchItems();
      return true;
    } catch (e) {
      print('Error deleting item: $e');
      return false;
    }
  }

  Future<List<ItemModel>> getUserItems(String userId) async {
    try {
      final response = await _supabase
          .from('items')
          .select('*, user_profiles(full_name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (json) => ItemModel.fromJson({
          ...json,
          'user_name': json['user_profiles']?['full_name'] ?? 'Unknown',
        }),
      )
          .toList();
    } catch (e) {
      print('Error fetching user items: $e');
      return [];
    }
  }
}
