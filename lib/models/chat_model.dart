class ConversationModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final String? lastMessageText;
  final DateTime? lastMessageTime;
  final int user1UnreadCount;
  final int user2UnreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed fields
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.lastMessageText,
    this.lastMessageTime,
    this.user1UnreadCount = 0,
    this.user2UnreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      user1Id: json['user1_id'],
      user2Id: json['user2_id'],
      lastMessageText: json['last_message_text'],
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'])
          : null,
      user1UnreadCount: json['user1_unread_count'] ?? 0,
      user2UnreadCount: json['user2_unread_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      otherUserId: json['other_user_id'],
      otherUserName: json['other_user_name'],
      otherUserAvatar: json['other_user_avatar'],
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'last_message_text': lastMessageText,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'user1_unread_count': user1UnreadCount,
      'user2_unread_count': user2UnreadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  // Computed fields
  final String? senderName;
  final String? senderAvatar;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      content: json['content'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      senderName: json['sender_name'],
      senderAvatar: json['sender_avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
