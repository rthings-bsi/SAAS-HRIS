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
  final String? timeAgo;

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
    this.timeAgo,
  });

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  static String? _parseStringOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static Map<String, dynamic>? _parseDataMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      idNotifications: _parseInt(json['id_notifications']),
      idCompanies: _parseInt(json['id_companies']),
      idUsers: _parseInt(json['id_users']),
      type: _parseStringOrNull(json['type']) ?? 'system',
      title: _parseStringOrNull(json['title']) ?? '',
      message: _parseStringOrNull(json['message']) ?? '',
      data: _parseDataMap(json['data']),
      isRead: _parseBool(json['is_read']),
      readAt: _parseStringOrNull(json['read_at']),
      createdAt: _parseStringOrNull(json['created_at']),
      timeAgo: _parseStringOrNull(json['time_ago']),
    );
  }

  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'leave':
        return 'CUTI';
      case 'overtime':
        return 'LEMBUR';
      case 'payroll':
        return 'PENGGAJIAN';
      case 'attendance':
        return 'PRESENSI';
      case 'performance':
        return 'KINERJA';
      default:
        return 'SISTEM';
    }
  }

  String get displayTime {
    if (timeAgo != null && timeAgo!.trim().isNotEmpty) {
      return timeAgo!.trim();
    }
    if (createdAt == null || createdAt!.trim().isEmpty) {
      return '';
    }
    final parsed = DateTime.tryParse(createdAt!)?.toLocal();
    if (parsed == null) return '';

    final diff = DateTime.now().difference(parsed);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    return '$day/$month/${parsed.year}';
  }

  NotificationModel copyWith({
    bool? isRead,
    String? readAt,
    String? timeAgo,
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
      timeAgo: timeAgo ?? this.timeAgo,
    );
  }
}
