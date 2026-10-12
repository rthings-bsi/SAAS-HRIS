class ApiEndpoints {
  ApiEndpoints._();

  // Base URL (Override with --dart-define=BASE_URL=... if needed)
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  // Preset base URLs for quick switching during development/testing
  static const String defaultLanUrl = 'http://192.168.1.178:8000/api/v1';
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
}
