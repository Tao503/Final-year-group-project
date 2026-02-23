class DonationModel {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String description;
  final String? imageUrl;
  final String? detectedLabel;
  final String? detectedColor;
  final String? recommendedCategory; // AI-recommended
  final String status; // 'available' or 'claimed'
  final DateTime createdAt;

  DonationModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.description,
    this.imageUrl,
    this.detectedLabel,
    this.detectedColor,
    this.recommendedCategory,
    required this.status,
    required this.createdAt,
  });

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    return DonationModel(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? 'Unknown',
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      detectedLabel: json['detected_label'],
      detectedColor: json['detected_color'],
      recommendedCategory: json['recommended_category'],
      status: json['status'] ?? 'available',
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
      'detected_label': detectedLabel,
      'detected_color': detectedColor,
      'recommended_category': recommendedCategory,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

