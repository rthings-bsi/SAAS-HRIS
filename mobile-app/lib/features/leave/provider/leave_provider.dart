import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/network_provider.dart';
import '../data/leave_models.dart';
import '../data/leave_repository.dart';

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return LeaveRepository(client);
});

final leaveTypesProvider = FutureProvider.autoDispose<List<LeaveTypeModel>>((ref) async {
  final repo = ref.watch(leaveRepositoryProvider);
  return repo.getLeaveTypes();
});

final leaveBalanceProvider = FutureProvider.autoDispose<List<LeaveBalanceModel>>((ref) async {
  final repo = ref.watch(leaveRepositoryProvider);
  return repo.getLeaveBalance();
});

final leaveStatusFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

final leaveMyRequestsProvider = FutureProvider.autoDispose.family<List<LeaveRequestModel>, String?>((ref, status) async {
  final repo = ref.watch(leaveRepositoryProvider);
  return repo.getMyRequests(status: status);
});

class LeaveActionState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  const LeaveActionState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });
}

class LeaveActionNotifier extends StateNotifier<LeaveActionState> {
  final LeaveRepository _repository;
  final Ref _ref;

  LeaveActionNotifier(this._repository, this._ref) : super(const LeaveActionState());

  Future<bool> submitLeaveRequest({
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    String? attachmentPath,
    Uint8List? attachmentBytes,
  }) async {
    state = const LeaveActionState(isLoading: true);
    try {
      await _repository.submitLeaveRequest(
        leaveTypeId: leaveTypeId,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        attachmentPath: attachmentPath,
        attachmentBytes: attachmentBytes,
      );
      _ref.invalidate(leaveBalanceProvider);
      _ref.invalidate(leaveMyRequestsProvider);
      state = const LeaveActionState(isSuccess: true);
      return true;
    } catch (e) {
      final msg = e is ApiException
          ? e.userFriendlyMessage
          : e.toString().replaceFirst('Exception: ', '');
      state = LeaveActionState(errorMessage: msg);
      return false;
    }
  }

  void reset() {
    state = const LeaveActionState();
  }
}

final leaveActionProvider = StateNotifierProvider.autoDispose<LeaveActionNotifier, LeaveActionState>((ref) {
  final repo = ref.watch(leaveRepositoryProvider);
  return LeaveActionNotifier(repo, ref);
});
