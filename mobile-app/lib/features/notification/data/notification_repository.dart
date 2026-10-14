import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import 'notification_model.dart';

class NotificationRepository {
  final ApiClient _client;

  NotificationRepository(this._client);

  Future<int> getUnreadCount() async {
    final response = await _client.get(ApiEndpoints.notificationUnreadCount);
    if (response is Map && response['data'] is Map) {
      final data = response['data'] as Map;
      return data['unread_count'] as int? ?? 0;
    }
    return 0;
  }

  Future<List<NotificationModel>> getNotifications({int perPage = 30}) async {
    final response = await _client.get(
      ApiEndpoints.notifications,
      queryParameters: {'per_page': perPage},
    );

    if (response is Map && response['data'] is Map) {
      final data = response['data'] as Map;
      final rawList = data['notifications'] as List? ?? [];
      return rawList
          .map((item) => NotificationModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
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
