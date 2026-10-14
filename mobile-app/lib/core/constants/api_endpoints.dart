class ApiEndpoints {
  ApiEndpoints._();

  // Base URL paten domain API Cloudflare
  static const String baseUrl = 'https://api-hris.rickysatria.web.id/api/v1';

  // Preset live domain URL
  static const String defaultTunnelUrl = 'https://api-hris.rickysatria.web.id/api/v1';
  static const String defaultLocalhostUrl = 'http://127.0.0.1:8000/api/v1';
  static const String defaultLanUrl = 'http://192.168.5.9:8000/api/v1';
  static const String defaultUsbUrl = 'http://127.0.0.1:8000/api/v1';
  static const String defaultEmulatorUrl = 'http://10.0.2.2:8000/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Attendance
  static const String attendanceToday = '/attendance/today';
  static const String attendanceClockIn = '/attendance/clock-in';
  static const String attendanceClockOut = '/attendance/clock-out';
  static const String attendanceHistory = '/attendance/history';
  static const String attendanceRecap = '/attendance/recap';

  // Leave
  static const String leaveTypes = '/leaves/types';
  static const String leaveBalance = '/leaves/balance';
  static const String leaveMyRequests = '/leaves/my-requests';
  static const String leaveRequest = '/leaves/request';
  static const String leaveApprovals = '/leaves/approvals';
  static String leaveAction(int id) => '/leaves/$id/action';

  // Overtime
  static const String myOvertimeRequests = '/overtime/my-requests';
  static const String applyOvertime = '/overtime/request';
  static const String overtimeApprovals = '/overtime/approvals';
  static String overtimeAction(int id) => '/overtime/approvals/$id/action';

  // Payroll
  static const String payrollMySlips = '/payroll/my-slips';
  static String payrollDownloadSlip(int id) => '/payroll/my-slips/$id/download';
  static String payrollMySlipDownload(int id) => '/payroll/my-slips/$id/download';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationUnreadCount = '/notifications/unread-count';
  static String notificationMarkAsRead(int id) => '/notifications/$id/read';
  static const String notificationMarkAllRead = '/notifications/read-all';
  static String notificationDelete(int id) => '/notifications/$id';
}
