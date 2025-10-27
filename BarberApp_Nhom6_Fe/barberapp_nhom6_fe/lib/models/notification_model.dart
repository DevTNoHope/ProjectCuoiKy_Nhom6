class NotificationModel {
  final int id;
  final String title;
  final String content; // hoặc body tuỳ backend
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? json['body'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      data: json['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
    'data': data,
  };

  /// ✅ Thêm hàm này để fix lỗi "copyWith"
  NotificationModel copyWith({
    int? id,
    String? title,
    String? content,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }
}
