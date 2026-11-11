import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/network_provider.dart';
import '../../attendance/data/attendance_models.dart';
import '../../attendance/provider/attendance_provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../data/overtime_draft_service.dart';
import '../data/overtime_models.dart';
import '../data/overtime_repository.dart';

final overtimeDraftServiceProvider = Provider<OvertimeDraftService>((ref) {
  return OvertimeDraftService();
});

final localOvertimeDraftsProvider =
    FutureProvider.autoDispose<List<OvertimeDraftModel>>((ref) async {
  final auth = ref.watch(authStateProvider);
  final rawUserId = auth.user?['id_users'] ?? auth.user?['id'] ?? 0;
  final userId = rawUserId is int
      ? rawUserId
      : int.tryParse(rawUserId.toString()) ?? 0;
  if (userId <= 0) return [];
  final service = ref.watch(overtimeDraftServiceProvider);
  return service.loadDrafts(userId);
});

class OvertimeDayContext {
  final String? shiftName;
  final String? shiftStart;
  final String? shiftEnd;
  final Map<String, AttendanceRecord> attendanceByDate;

  const OvertimeDayContext({
    this.shiftName,
    this.shiftStart,
    this.shiftEnd,
    this.attendanceByDate = const {},
  });

  String? get formattedShiftRange {
    if (shiftStart == null || shiftEnd == null) return null;
    if (shiftStart!.isEmpty || shiftEnd!.isEmpty) return null;
    return '[$shiftStart - $shiftEnd]';
  }
}

final overtimeDayContextProvider = FutureProvider.autoDispose
    .family<OvertimeDayContext, ({String startDate, String endDate})>(
        (ref, range) async {
  final auth = ref.watch(authStateProvider);
  final attendanceRepo = ref.watch(attendanceRepositoryProvider);

  String? shiftName;
  String? shiftStart;
  String? shiftEnd;

  final empShift = auth.employee?['shift'];
  if (empShift is Map) {
    shiftName = empShift['name']?.toString();
    final rawStart = empShift['start_time']?.toString();
    final rawEnd = empShift['end_time']?.toString();
    shiftStart = rawStart != null && rawStart.length >= 5
        ? rawStart.substring(0, 5)
        : rawStart;
    shiftEnd =
        rawEnd != null && rawEnd.length >= 5 ? rawEnd.substring(0, 5) : rawEnd;
  }

  final byDate = <String, AttendanceRecord>{};

  try {
    final results = await Future.wait<dynamic>([
      attendanceRepo.getTodayAttendance(),
      attendanceRepo.getAttendanceHistoryRange(
        startDate: range.startDate,
        endDate: range.endDate,
      ),
    ]);

    final todayMap = results[0] as Map<String, dynamic>;
    if (todayMap.isNotEmpty) {
      final todayData = TodayAttendanceData.fromMap(todayMap);
      shiftName ??= todayData.shiftName;
      shiftStart ??= todayData.startTime;
      shiftEnd ??= todayData.endTime;

      final todayDateKey = todayData.date.length >= 10
          ? todayData.date.substring(0, 10)
          : todayData.date;
      if (todayData.hasClockedIn || todayData.hasClockedOut) {
        byDate[todayDateKey] = AttendanceRecord(
          date: todayDateKey,
          clockIn: todayData.clockInTime,
          clockOut: todayData.clockOutTime,
          status: todayData.status,
          lateDurationMinutes: todayData.lateDurationMinutes,
        );
      }
    }

    final historyList = results[1] as List<dynamic>;
    for (final raw in historyList) {
      if (raw is Map<String, dynamic>) {
        final rec = AttendanceRecord.fromMap(raw);
        final key =
            rec.date.length >= 10 ? rec.date.substring(0, 10) : rec.date;
        if (key.isNotEmpty) {
          byDate[key] = rec;
        }
      } else if (raw is Map) {
        final rec = AttendanceRecord.fromMap(Map<String, dynamic>.from(raw));
        final key =
            rec.date.length >= 10 ? rec.date.substring(0, 10) : rec.date;
        if (key.isNotEmpty) {
          byDate[key] = rec;
        }
      }
    }
  } catch (_) {
    // Tetap tampilkan informasi shift dari profil jika endpoint riwayat presensi gagal
  }

  return OvertimeDayContext(
    shiftName: shiftName,
    shiftStart: shiftStart,
    shiftEnd: shiftEnd,
    attendanceByDate: byDate,
  );
});

final overtimeRepositoryProvider = Provider<OvertimeRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return OvertimeRepository(client);
});

final overtimeStatusFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

final overtimeDateFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

final overtimeApprovalFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

final overtimeApprovalDateFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

final overtimeViewTabProvider = StateProvider.autoDispose<String?>((ref) => null);

final myOvertimeListProvider =
    FutureProvider.autoDispose.family<List<OvertimeRequestModel>, String?>((ref, status) async {
  final repo = ref.watch(overtimeRepositoryProvider);
  return repo.getMyRequests(status: status);
});

final overtimeApprovalsProvider =
    FutureProvider.autoDispose.family<List<OvertimeRequestModel>, String?>((ref, status) async {
  final repo = ref.watch(overtimeRepositoryProvider);
  return repo.getApprovals(status: status);
});

class OvertimeActionState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final String? successMessage;

  const OvertimeActionState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.successMessage,
  });
}

class OvertimeActionNotifier extends StateNotifier<OvertimeActionState> {
  final OvertimeRepository _repository;
  final Ref _ref;

  OvertimeActionNotifier(this._repository, this._ref)
      : super(const OvertimeActionState());

  Future<bool> applyOvertime({
    required String date,
    required String startTime,
    required String endTime,
    required String reason,
  }) async {
    state = const OvertimeActionState(isLoading: true);
    try {
      final res = await _repository.applyOvertime(
        date: date,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
      );
      _ref.invalidate(myOvertimeListProvider);
      _ref.invalidate(overtimeApprovalsProvider);
      final msg = res['message'] as String? ?? 'Permohonan lembur berhasil diajukan.';
      state = OvertimeActionState(isSuccess: true, successMessage: msg);
      return true;
    } catch (e) {
      final String errorMsg;
      if (e is ApiException) {
        errorMsg = e.userFriendlyMessage;
      } else {
        errorMsg = e.toString().replaceFirst('Exception: ', '');
      }
      state = OvertimeActionState(isLoading: false, errorMessage: errorMsg);
      return false;
    }
  }

  Future<bool> applyOvertimeBatch({
    required List<Map<String, dynamic>> entries,
    required String reason,
  }) async {
    state = const OvertimeActionState(isLoading: true);
    try {
      final res = await _repository.applyOvertimeBatch(
        entries: entries,
        reason: reason,
      );
      _ref.invalidate(myOvertimeListProvider);
      _ref.invalidate(overtimeApprovalsProvider);
      final msg = res['message'] as String? ?? 'Permohonan lembur berhasil diajukan.';
      state = OvertimeActionState(isSuccess: true, successMessage: msg);
      return true;
    } catch (e) {
      final String errorMsg;
      if (e is ApiException) {
        errorMsg = e.userFriendlyMessage;
      } else {
        errorMsg = e.toString().replaceFirst('Exception: ', '');
      }
      state = OvertimeActionState(isLoading: false, errorMessage: errorMsg);
      return false;
    }
  }

  Future<bool> submitOvertimeForm({
    required List<Map<String, dynamic>> entries,
    required String reason,
    String? overtimeType,
    String? reasonCategory,
    String? attachmentPath,
    Uint8List? attachmentBytes,
    String? attachmentName,
  }) async {
    state = const OvertimeActionState(isLoading: true);
    try {
      final res = await _repository.submitOvertimeForm(
        entries: entries,
        reason: reason,
        overtimeType: overtimeType,
        reasonCategory: reasonCategory,
        attachmentPath: attachmentPath,
        attachmentBytes: attachmentBytes,
        attachmentName: attachmentName,
      );
      _ref.invalidate(myOvertimeListProvider);
      _ref.invalidate(overtimeApprovalsProvider);
      final msg =
          res['message'] as String? ?? 'Permohonan lembur berhasil dikirim.';
      state = OvertimeActionState(isSuccess: true, successMessage: msg);
      return true;
    } catch (e) {
      final String errorMsg;
      if (e is ApiException) {
        errorMsg = e.userFriendlyMessage;
      } else {
        errorMsg = e.toString().replaceFirst('Exception: ', '');
      }
      state = OvertimeActionState(isLoading: false, errorMessage: errorMsg);
      return false;
    }
  }

  Future<bool> updateOvertime({
    required int id,
    required String date,
    String? endDate,
    required String startTime,
    required String endTime,
    required String reason,
    List<Map<String, dynamic>>? entries,
    String? overtimeType,
    String? reasonCategory,
    String? attachmentPath,
    Uint8List? attachmentBytes,
    String? attachmentName,
    bool removeAttachment = false,
  }) async {
    state = const OvertimeActionState(isLoading: true);
    try {
      final res = await _repository.updateOvertime(
        id: id,
        date: date,
        endDate: endDate,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
        entries: entries,
        overtimeType: overtimeType,
        reasonCategory: reasonCategory,
        attachmentPath: attachmentPath,
        attachmentBytes: attachmentBytes,
        attachmentName: attachmentName,
        removeAttachment: removeAttachment,
      );
      _ref.invalidate(myOvertimeListProvider);
      _ref.invalidate(overtimeApprovalsProvider);
      final msg =
          res['message'] as String? ?? 'Permohonan lembur berhasil diperbarui.';
      state = OvertimeActionState(isSuccess: true, successMessage: msg);
      return true;
    } catch (e) {
      final String errorMsg;
      if (e is ApiException) {
        errorMsg = e.userFriendlyMessage;
      } else {
        errorMsg = e.toString().replaceFirst('Exception: ', '');
      }
      state = OvertimeActionState(isLoading: false, errorMessage: errorMsg);
      return false;
    }
  }

  Future<bool> cancelOvertime({
    required int id,
    String? reason,
  }) async {
    state = const OvertimeActionState(isLoading: true);
    try {
      final res = await _repository.cancelOvertime(
        id: id,
        reason: reason,
      );
      _ref.invalidate(myOvertimeListProvider);
      _ref.invalidate(overtimeApprovalsProvider);
      final msg = res['message'] as String? ?? 'Permohonan lembur berhasil dibatalkan.';
      state = OvertimeActionState(isSuccess: true, successMessage: msg);
      return true;
    } catch (e) {
      final String errorMsg;
      if (e is ApiException) {
        errorMsg = e.userFriendlyMessage;
      } else {
        errorMsg = e.toString().replaceFirst('Exception: ', '');
      }
      state = OvertimeActionState(isLoading: false, errorMessage: errorMsg);
      return false;
    }
  }

  Future<bool> processApproval({
    required int id,
    required String action,
    String? notes,
  }) async {
    state = const OvertimeActionState(isLoading: true);
    try {
      final res = await _repository.takeApprovalAction(
        id: id,
        action: action,
        notes: notes,
      );
      _ref.invalidate(overtimeApprovalsProvider);
      _ref.invalidate(myOvertimeListProvider);
      final defaultMsg = action == 'approved'
          ? 'Pengajuan lembur berhasil disetujui.'
          : 'Pengajuan lembur telah ditolak.';
      final msg = res['message'] as String? ?? defaultMsg;
      state = OvertimeActionState(isSuccess: true, successMessage: msg);
      return true;
    } catch (e) {
      final String errorMsg;
      if (e is ApiException) {
        errorMsg = e.userFriendlyMessage;
      } else {
        errorMsg = e.toString().replaceFirst('Exception: ', '');
      }
      state = OvertimeActionState(isLoading: false, errorMessage: errorMsg);
      return false;
    }
  }

  void reset() {
    state = const OvertimeActionState();
  }
}

final overtimeActionProvider =
    StateNotifierProvider.autoDispose<OvertimeActionNotifier, OvertimeActionState>((ref) {
  final repo = ref.watch(overtimeRepositoryProvider);
  return OvertimeActionNotifier(repo, ref);
});
