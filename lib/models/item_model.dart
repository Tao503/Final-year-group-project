class ItemModel {
  final String id;
  final String userId;
  final String userName;
  final String type; 
  final String title;
  final String description;
  final String category;
  final String color;
  final String? imageUrl;
  final String? location;
  final String? detectedLabel; 
  final String? detectedColor; 
  final String status; 
  final DateTime? dateFound; 
  final DateTime createdAt;

  ItemModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    required this.color,
    this.imageUrl,
    this.location,
    this.detectedLabel,
    this.detectedColor,
    required this.status,
    this.dateFound,
    required this.createdAt,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? 'Unknown',
      type: json['type'],
      title: json['title'],
      description: json['description'],
      category: json['category'] ?? '',
      color: json['detected_color'] ?? json['color'] ?? '',
      imageUrl: json['image_url'],
      location: json['location'],
      detectedLabel: json['detected_label'],
      detectedColor: json['detected_color'],
      status: json['status'] ?? 'open',
      dateFound: json['date_found'] != null
          ? (json['date_found'] is String
                ? DateTime.parse(json['date_found'])
                : DateTime.parse(json['date_found'].toString()))
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'type': type,
      'title': title,
      'description': description,
      'category': category,
      'color': color,
      'image_url': imageUrl,
      'location': location,
      'detected_label': detectedLabel,
      'detected_color': detectedColor,
      'status': status,
      'date_found': dateFound?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
