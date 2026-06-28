class Advertisement {
  final String id;
  final String imageUrl;
  final String? actionUrl;
  final bool isActive;
  final DateTime createdAt;

  const Advertisement({
    required this.id,
    required this.imageUrl,
    this.actionUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory Advertisement.fromJson(Map<String, dynamic> json) => Advertisement(
        id:        json['id'] as String,
        imageUrl:  json['image_url'] as String,
        actionUrl: json['action_url'] as String?,
        isActive:  json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
