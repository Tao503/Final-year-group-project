import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_model.dart';
import '../services/supabase_service.dart';

class ChatController extends GetxController {
  final _supabase = SupabaseService.client;
  final _uuid = const Uuid();

  final RxList<ConversationModel> conversations = <ConversationModel>[].obs;
  final RxMap<String, List<MessageModel>> messages =
      <String, List<MessageModel>>{}.obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> currentConversationId = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchConversations();
    setupRealtimeListeners();
  }

  @override
  void onClose() {
    _supabase.removeAllChannels();
    super.onClose();
  }

  Future<void> fetchConversations() async {
    isLoading.value = true;
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        conversations.value = [];
        return;
      }

      // Fetch conversations where user is user1 or user2
      final response = await _supabase
          .from('conversations')
          .select('*')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .order('updated_at', ascending: false);

      // Fetch user profiles for other users
      final userIds = <String>{};
      for (var conv in response) {
        if (conv['user1_id'] == userId) {
          userIds.add(conv['user2_id']);
        } else {
          userIds.add(conv['user1_id']);
        }
      }

      final profilesMap = <String, Map<String, dynamic>>{};
      if (userIds.isNotEmpty) {
        try {
          final profilesResponse = await _supabase
              .from('user_profiles')
              .select('id, full_name, avatar_url')
              .inFilter('id', userIds.toList());

          for (var profile in profilesResponse) {
            profilesMap[profile['id']] = profile;
          }
        } catch (e) {
          print(
            '⚠️ Warning: Could not fetch user profiles for conversations: $e',
          );
        }
      }

      // Map conversations with other user info
      conversations.value = (response as List).map((json) {
        final otherUserId = json['user1_id'] == userId
            ? json['user2_id']
            : json['user1_id'];
        final profile = profilesMap[otherUserId];
        final unreadCount = json['user1_id'] == userId
            ? json['user1_unread_count'] ?? 0
            : json['user2_unread_count'] ?? 0;

        return ConversationModel.fromJson({
          ...json,
          'other_user_id': otherUserId,
          'other_user_name': profile?['full_name'] ?? 'Unknown',
          'other_user_avatar': profile?['avatar_url'],
          'unread_count': unreadCount,
        });
      }).toList();

      print('✅ Fetched ${conversations.length} conversations');
    } catch (e) {
      print('❌ Error fetching conversations: $e');
      conversations.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> getOrCreateConversation(String otherUserId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // Check if conversation exists
      final existing = await _supabase
          .from('conversations')
          .select()
          .or(
            'and(user1_id.eq.$userId,user2_id.eq.$otherUserId),and(user1_id.eq.$otherUserId,user2_id.eq.$userId)',
          )
          .maybeSingle();

      if (existing != null) {
        return existing['id'];
      }

      // Create new conversation
      final conversationId = _uuid.v4();
      await _supabase.from('conversations').insert({
        'id': conversationId,
        'user1_id': userId,
        'user2_id': otherUserId,
      });

      await fetchConversations();
      return conversationId;
    } catch (e) {
      print('❌ Error getting/creating conversation: $e');
      return null;
    }
  }

  Future<void> fetchMessages(String conversationId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      // Fetch sender profiles
      final senderIds = (response as List)
          .map((m) => m['sender_id'] as String)
          .toSet()
          .toList();

      final profilesMap = <String, Map<String, dynamic>>{};
      if (senderIds.isNotEmpty) {
        try {
          final profilesResponse = await _supabase
              .from('user_profiles')
              .select('id, full_name, avatar_url')
              .inFilter('id', senderIds);

          for (var profile in profilesResponse) {
            profilesMap[profile['id']] = profile;
          }
        } catch (e) {
          print('⚠️ Warning: Could not fetch sender profiles: $e');
        }
      }

      messages[conversationId] = (response as List).map((json) {
        final senderProfile = profilesMap[json['sender_id']];
        return MessageModel.fromJson({
          ...json,
          'sender_name': senderProfile?['full_name'] ?? 'Unknown',
          'sender_avatar': senderProfile?['avatar_url'],
        });
      }).toList();
    } catch (e) {
      print('❌ Error fetching messages: $e');
      messages[conversationId] = [];
    }
  }

  Future<bool> sendMessage(String conversationId, String content) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Get receiver ID from conversation
      final conversation = await _supabase
          .from('conversations')
          .select('user1_id, user2_id')
          .eq('id', conversationId)
          .single();

      final receiverId = conversation['user1_id'] == userId
          ? conversation['user2_id']
          : conversation['user1_id'];

      final messageId = _uuid.v4();

      await _supabase.from('messages').insert({
        'id': messageId,
        'conversation_id': conversationId,
        'sender_id': userId,
        'receiver_id': receiverId,
        'content': content,
      });

      // Fetch updated messages
      await fetchMessages(conversationId);
      await fetchConversations();
      return true;
    } catch (e) {
      print('❌ Error sending message: $e');
      return false;
    }
  }

  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .eq('receiver_id', userId)
          .eq('is_read', false);

      // Reset unread count in conversation
      final conversation = conversations.firstWhereOrNull(
        (c) => c.id == conversationId,
      );

      if (conversation != null) {
        final userIdStr = userId.toString();
        if (conversation.user1Id == userIdStr) {
          await _supabase
              .from('conversations')
              .update({'user1_unread_count': 0})
              .eq('id', conversationId);
        } else {
          await _supabase
              .from('conversations')
              .update({'user2_unread_count': 0})
              .eq('id', conversationId);
        }
      }

      await fetchConversations();
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  void setupRealtimeListeners() {
    // Listen to new messages
    _supabase
        .channel('messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final conversationId =
                payload.newRecord['conversation_id'] as String;
            if (currentConversationId.value != null &&
                currentConversationId.value == conversationId) {
              fetchMessages(conversationId);
            }
            fetchConversations();
          },
        )
        .subscribe();

    // Listen to conversation updates
    _supabase
        .channel('conversations')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          callback: (payload) {
            fetchConversations();
          },
        )
        .subscribe();
  }
}
