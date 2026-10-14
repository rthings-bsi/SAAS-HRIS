class NotificationModel {
  final int idNotifications;
  final int idCompanies;
  final int idUsers;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final String? readAt;
  final String? createdAt;

  NotificationModel({
    required this.idNotifications,
    required this.idCompanies,
    required this.idUsers,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    this.readAt,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      idNotifications: json['id_notifications'] as int? ?? 0,
      idCompanies: json['id_companies'] as int? ?? 0,
      idUsers: json['id_users'] as int? ?? 0,
      type: json['type'] as String? ?? 'system',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  NotificationModel copyWith({
    bool? isRead,
    String? readAt,
  }) {
    return NotificationModel(
      idNotifications: idNotifications,
      idCompanies: idCompanies,
      idUsers: idUsers,
      type: type,
      title: title,
      message: message,
      data: data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}
