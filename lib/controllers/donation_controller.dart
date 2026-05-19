import 'dart:io';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/donation_model.dart';
import '../services/supabase_service.dart';
import '../services/ai_service.dart';
import '../services/image_upload_service.dart';

class DonationController extends GetxController {
  final _supabase = SupabaseService.client;
  final _uuid = const Uuid();

  final RxList<DonationModel> donations = <DonationModel>[].obs;
  final RxList<DonationModel> filteredDonations = <DonationModel>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> recommendedCategory = Rx<String?>(null);

  
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'All'.obs;
  final RxString selectedStatus = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDonations();
    
    ever(donations, (_) => _applyFilters());
  }

  Future<void> fetchDonations() async {
    isLoading.value = true;
    try {
      final response = await _supabase
          .from('donations')
          .select('*, user_profiles(full_name)')
          .order('created_at', ascending: false);

      donations.value = (response as List)
          .map(
            (json) => DonationModel.fromJson({
          ...json,
          'user_name': json['user_profiles']?['full_name'] ?? 'Unknown',
        }),
      )
          .toList();

      _applyFilters();
    } catch (e) {
      print('Error fetching donations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void searchDonations(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void filterByCategory(String category) {
    selectedCategory.value = category;
    _applyFilters();
  }

  void filterByStatus(String status) {
    selectedStatus.value = status;
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = donations.toList();

    
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((donation) {
        return donation.title.toLowerCase().contains(query) ||
            donation.description.toLowerCase().contains(query) ||
            (donation.recommendedCategory?.toLowerCase().contains(query) ??
                false);
      }).toList();
    }

    
    if (selectedCategory.value != 'All') {
      filtered = filtered.where((donation) {
        return donation.recommendedCategory == selectedCategory.value;
      }).toList();
    }

    
    if (selectedStatus.value != 'All') {
      filtered = filtered.where((donation) {
        return donation.status == selectedStatus.value.toLowerCase();
      }).toList();
    }

    filteredDonations.value = filtered;
  }

  Future<bool> postDonation({
    required String title,
    required String description,
    File? imageFile,
    String? category,
  }) async {
    isLoading.value = true;
    recommendedCategory.value = null;
    try {
      String? imageUrl;
      String? detectedLabel;
      String? detectedColor;
      String? finalCategory = category;

      
      if (imageFile != null) {
        imageUrl = await ImageUploadService.uploadDonationImage(imageFile);
        detectedLabel = await AIService.detectItemLabel(imageFile);
        detectedColor = await AIService.detectColor(imageFile);

        
        finalCategory = category ?? 'General';
        recommendedCategory.value = finalCategory;
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final donationId = _uuid.v4();

      await _supabase.from('donations').insert({
        'id': donationId,
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'detected_label': detectedLabel,
        'detected_color': detectedColor,
        'recommended_category': finalCategory,
        'user_id': userId,
        'status': 'available',
      });

      await fetchDonations();
      return true;
    } catch (e) {
      print('Error posting donation: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<DonationModel>> getUserDonations(String userId) async {
    try {
      final response = await _supabase
          .from('donations')
          .select('*, user_profiles(full_name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (json) => DonationModel.fromJson({
          ...json,
          'user_name': json['user_profiles']?['full_name'] ?? 'Unknown',
        }),
      )
          .toList();
    } catch (e) {
      print('Error fetching user donations: $e');
      return [];
    }
  }

  Future<bool> deleteDonation(String donationId) async {
    try {
      
      final donation = donations.firstWhere((d) => d.id == donationId);
      if (donation.imageUrl != null) {
        await ImageUploadService.deleteImage(
          donation.imageUrl!,
          'donation-images',
        );
      }

      await _supabase.from('donations').delete().eq('id', donationId);
      await fetchDonations();
      return true;
    } catch (e) {
      print('Error deleting donation: $e');
      return false;
    }
  }

  Future<bool> requestDonation(String donationId) async {
    try {
      await _supabase
          .from('donations')
          .update({'status': 'claimed'})
          .eq('id', donationId);

      await fetchDonations();
      return true;
    } catch (e) {
      print('Error requesting donation: $e');
      return false;
    }
  }
}
