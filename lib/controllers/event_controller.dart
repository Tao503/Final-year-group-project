import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';
import '../services/supabase_service.dart';
import '../services/image_upload_service.dart';
import 'dart:io';

class EventController extends GetxController {
  final _supabase = SupabaseService.client;
  final _uuid = const Uuid();

  final RxList<EventModel> events = <EventModel>[].obs;
  final RxMap<String, List<EventComment>> eventComments =
      <String, List<EventComment>>{}.obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> currentEventId = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchEvents();
    setupRealtimeListeners();
  }

  @override
  void onClose() {
    _supabase.removeAllChannels();
    super.onClose();
  }

  Future<void> fetchEvents() async {
    isLoading.value = true;
    try {
      final userId = _supabase.auth.currentUser?.id;

      // Fetch events with join to user_profiles
      final response = await _supabase
          .from('events')
          .select('*, user_profiles(full_name)')
          .order('event_date', ascending: true);

      // Fetch all likes and map by event_id
      final likesMap = <String, List<Map<String, dynamic>>>{};
      try {
        final likesResponse = await _supabase
            .from('event_likes')
            .select('event_id, user_id');

        for (var like in likesResponse) {
          final eventId = like['event_id'] as String;
          if (!likesMap.containsKey(eventId)) {
            likesMap[eventId] = [];
          }
          likesMap[eventId]!.add(like);
        }
      } catch (e) {
        print('Warning: Could not fetch likes: $e');
      }

      // Fetch all all comments and count by event_id
      final commentsMap = <String, int>{};
      try {
        final commentsResponse = await _supabase
            .from('event_comments')
            .select('event_id');

        for (var comment in commentsResponse) {
          final eventId = comment['event_id'] as String;
          commentsMap[eventId] = (commentsMap[eventId] ?? 0) + 1;
        }
      } catch (e) {
        print('Warning: Could not fetch comments: $e');
      }

      // Map events with user names, likes, and comments
      events.value = (response as List).map((json) {
        final eventId = json['id'] as String;

        // Get user name from join
        final userName = json['user_profiles']?['full_name'] ?? 'Unknown';

        // Get likes for this event
        final eventLikes = likesMap[eventId] ?? [];
        final likesCount = eventLikes.length;

        // Check if current user liked it
        final isLiked =
            userId != null &&
            eventLikes.any((like) => like['user_id'] == userId);

        // Get comments count
        final commentsCount = commentsMap[eventId] ?? 0;

        return EventModel.fromJson({
          ...json,
          'user_name': userName,
          'likes_count': likesCount,
          'is_liked': isLiked,
          'comments_count': commentsCount,
        });
      }).toList();
    } catch (e) {
      print('Error fetching events: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> postEvent({
    required String title,
    required String description,
    required DateTime eventDate,
    DateTime? endDate,
    required String location,
    String? category,
    File? imageFile,
  }) async {
    isLoading.value = true;
    try {
      String? imageUrl;

      if (imageFile != null) {
        imageUrl = await ImageUploadService.uploadEventImage(imageFile);
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final eventId = _uuid.v4();

      // Build insert data (only include category if it exists in schema)
      final insertData = <String, dynamic>{
        'id': eventId,
        'title': title,
        'description': description,
        'event_date': eventDate.toIso8601String(),
        'location': location,
        'user_id': userId,
      };

      // Add optional fields
      if (endDate != null) {
        insertData['end_date'] = endDate.toIso8601String();
      }
      if (imageUrl != null) {
        insertData['image_url'] = imageUrl;
      }
      // Only add category if it's not null (and column exists)
      if (category != null && category.isNotEmpty) {
        insertData['category'] = category;
      }

      await _supabase.from('events').insert(insertData);

      await fetchEvents();
      return true;
    } catch (e) {
      print('Error posting event: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> likeEvent(String eventId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Check if already liked
      final existingLike = await _supabase
          .from('event_likes')
          .select()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _supabase
            .from('event_likes')
            .delete()
            .eq('event_id', eventId)
            .eq('user_id', userId);
      } else {
        // Like - let id auto-generate
        await _supabase.from('event_likes').insert({
          'id': _uuid.v4(), // Generate UUID for id
          'event_id': eventId,
          'user_id': userId,
        });
      }

      await fetchEvents();
      return true;
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  Future<bool> commentOnEvent(String eventId, String content) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Fetch user's name from user_profiles
      String userName = 'Unknown';
      try {
        final profileResponse = await _supabase
            .from('user_profiles')
            .select('full_name')
            .eq('id', userId)
            .maybeSingle();

        if (profileResponse != null) {
          userName = profileResponse['full_name'] ?? 'Unknown';
        }
      } catch (e) {
        print('⚠️ Warning: Could not fetch user name for comment: $e');
      }

      final commentId = _uuid.v4();

      await _supabase.from('event_comments').insert({
        'id': commentId,
        'event_id': eventId,
        'user_id': userId,
        'user_name': userName, // Add user_name if table has this column
        'content': content,
      });

      await fetchComments(eventId);
      await fetchEvents();
      return true;
    } catch (e) {
      print('Error commenting: $e');
      return false;
    }
  }

  Future<void> fetchComments(String eventId) async {
    try {
      // Fetch comments with join to user_profiles
      final response = await _supabase
          .from('event_comments')
          .select('*, user_profiles(full_name)')
          .eq('event_id', eventId)
          .order('created_at', ascending: true);

      eventComments[eventId] = (response as List)
          .map(
            (json) => EventComment.fromJson({
          ...json,
          'user_name': json['user_profiles']?['full_name'] ?? 'Unknown',
        }),
      )
          .toList();
    } catch (e) {
      print('Error fetching comments: $e');
    }
  }

  Future<bool> deleteComment(String commentId) async {
    try {
      await _supabase.from('event_comments').delete().eq('id', commentId);

      final eventId = currentEventId.value;
      if (eventId != null) {
        await fetchComments(eventId);
      }
      await fetchEvents();
      return true;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  // Event Registration Methods
  Future<bool> registerForEvent(String eventId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Check if already registered
      final existing = await _supabase
          .from('event_registrations')
          .select()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Already registered
        return true;
      }

      // Register
      await _supabase.from('event_registrations').insert({
        'id': _uuid.v4(),
        'event_id': eventId,
        'user_id': userId,
      });

      // Update event attendees count
      await _updateEventAttendeesCount(eventId);

      await fetchEvents();
      return true;
    } catch (e) {
      print('Error registering for event: $e');
      return false;
    }
  }

  Future<bool> unregisterFromEvent(String eventId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('event_registrations')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);

      // Update event attendees count
      await _updateEventAttendeesCount(eventId);

      await fetchEvents();
      return true;
    } catch (e) {
      print('Error unregistering from event: $e');
      return false;
    }
  }

  Future<bool> isRegisteredForEvent(String eventId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final registration = await _supabase
          .from('event_registrations')
          .select()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      return registration != null;
    } catch (e) {
      print('Error checking registration: $e');
      return false;
    }
  }

  Future<List<String>> getRegisteredEventIds() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('event_registrations')
          .select('event_id')
          .eq('user_id', userId);

      return (response as List).map((r) => r['event_id'] as String).toList();
    } catch (e) {
      print('Error fetching registered events: $e');
      return [];
    }
  }

  Future<void> _updateEventAttendeesCount(String eventId) async {
    try {
      final countResponse = await _supabase
          .from('event_registrations')
          .select('id')
          .eq('event_id', eventId);

      final count = countResponse.length;

      await _supabase
          .from('events')
          .update({'attendees': count})
          .eq('id', eventId);
    } catch (e) {
      print('Error updating attendees count: $e');
    }
  }

  // Event Edit/Delete Methods
  Future<bool> updateEvent({
    required String eventId,
    String? title,
    String? description,
    DateTime? eventDate,
    DateTime? endDate,
    String? location,
    String? category,
    File? imageFile,
  }) async {
    isLoading.value = true;
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Verify ownership
      final event = await _supabase
          .from('events')
          .select('user_id')
          .eq('id', eventId)
          .maybeSingle();

      if (event == null || event['user_id'] != userId) {
        print('❌ User does not own this event');
        return false;
      }

      // Upload image if provided
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await ImageUploadService.uploadEventImage(imageFile);
        if (imageUrl == null) {
          print('⚠️ Image upload failed, continuing without image');
        }
      }

      // Build update data
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (eventDate != null)
        updateData['event_date'] = eventDate.toIso8601String();
      if (endDate != null) {
        updateData['end_date'] = endDate.toIso8601String();
      } else if (endDate == null && updateData.containsKey('event_date')) {
        // If updating event_date but not end_date, keep existing end_date
        // (don't set it to null)
      }
      if (location != null) updateData['location'] = location;
      if (category != null && category.isNotEmpty) {
        updateData['category'] = category;
      }
      if (imageUrl != null) updateData['image_url'] = imageUrl;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('events').update(updateData).eq('id', eventId);

      await fetchEvents();
      return true;
    } catch (e) {
      print('Error updating event: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    isLoading.value = true;
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Verify ownership
      final event = await _supabase
          .from('events')
          .select('user_id')
          .eq('id', eventId)
          .maybeSingle();

      if (event == null || event['user_id'] != userId) {
        print('❌ User does not own this event');
        return false;
      }

      await _supabase.from('events').delete().eq('id', eventId);

      await fetchEvents();
      return true;
    } catch (e) {
      print('Error deleting event: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void setupRealtimeListeners() {
    // Listen to likes changes
    _supabase
        .channel('event_likes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_likes',
          callback: (payload) {
            fetchEvents();
          },
        )
        .subscribe();

    // Listen to comments changes
    _supabase
        .channel('event_comments')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_comments',
          callback: (payload) {
            fetchEvents();
            final eventId = currentEventId.value;
            if (eventId != null) {
              fetchComments(eventId);
            }
          },
        )
        .subscribe();
  }
}
