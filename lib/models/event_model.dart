class EventModel {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime eventDate;
  final DateTime? endDate;
  final String location;
  final String? category;
  final String? organizer;
  final List<String>? tags;
  final int likesCount;
  final int commentsCount;
  final bool isLiked; // Whether current user liked it
  final bool isFeatured;
  final int? attendees;
  final int? maxAttendees;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.eventDate,
    this.endDate,
    required this.location,
    this.category,
    this.organizer,
    this.tags,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    this.isFeatured = false,
    this.attendees,
    this.maxAttendees,
    required this.createdAt,
  });

  // Helper getter for backward compatibility
  DateTime get date => eventDate;

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? 'Unknown',
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      eventDate: DateTime.parse(json['event_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      location: json['location'],
      category: json['category'],
      organizer: json['organizer'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      attendees: json['attendees'],
      maxAttendees: json['max_attendees'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'event_date': eventDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'location': location,
      'category': category,
      'organizer': organizer,
      'tags': tags,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_liked': isLiked,
      'is_featured': isFeatured,
      'attendees': attendees,
      'max_attendees': maxAttendees,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class EventComment {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;

  EventComment({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory EventComment.fromJson(Map<String, dynamic> json) {
    return EventComment(
      id: json['id'],
      eventId: json['event_id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? 'Unknown',
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'user_name': userName,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

