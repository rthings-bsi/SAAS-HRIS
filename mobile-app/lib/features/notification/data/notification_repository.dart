import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import 'notification_model.dart';

class NotificationRepository {
  final ApiClient _client;
  int? _lastUnreadCount;

  NotificationRepository(this._client);

  int? get lastUnreadCount => _lastUnreadCount;

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  // ApiClient._handleResponse already unwraps body['data'], while raw responses may still wrap it.
  static Map<String, dynamic>? _extractPayloadMap(dynamic response) {
    if (response is! Map) return null;
    final map = Map<String, dynamic>.from(response);
    if (map['data'] is Map) {
      return Map<String, dynamic>.from(map['data'] as Map);
    }
    return map;
  }

  Future<int> getUnreadCount() async {
    final response = await _client.get(ApiEndpoints.notificationUnreadCount);
    final payload = _extractPayloadMap(response);
    if (payload != null) {
      return _parseInt(payload['unread_count']);
    }
    return 0;
  }

  Future<List<NotificationModel>> getNotifications({int perPage = 30}) async {
    final response = await _client.get(
      ApiEndpoints.notifications,
      queryParameters: {'per_page': perPage},
    );

    final payload = _extractPayloadMap(response);
    if (payload == null) {
      _lastUnreadCount = null;
      return [];
    }

    if (payload.containsKey('unread_count')) {
      _lastUnreadCount = _parseInt(payload['unread_count']);
    } else {
      _lastUnreadCount = null;
    }

    final rawList = payload['notifications'] as List? ?? const [];
    return rawList
        .whereType<Map>()
        .map((item) => NotificationModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> markAsRead(int id) async {
    await _client.put(ApiEndpoints.notificationMarkAsRead(id));
  }

  Future<void> markAllAsRead() async {
    await _client.put(ApiEndpoints.notificationMarkAllRead);
  }

  Future<void> deleteNotification(int id) async {
    await _client.delete(ApiEndpoints.notificationDelete(id));
  }
}
