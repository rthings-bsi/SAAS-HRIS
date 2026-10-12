import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/network_provider.dart';
import '../data/overtime_models.dart';
import '../data/overtime_repository.dart';

final overtimeRepositoryProvider = Provider<OvertimeRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return OvertimeRepository(client);
});

final overtimeStatusFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

final myOvertimeListProvider =
    FutureProvider.autoDispose.family<List<OvertimeRequestModel>, String?>((ref, status) async {
  final repo = ref.watch(overtimeRepositoryProvider);
  return repo.getMyRequests(status: status);
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

  void reset() {
    state = const OvertimeActionState();
  }
}

final overtimeActionProvider =
    StateNotifierProvider.autoDispose<OvertimeActionNotifier, OvertimeActionState>((ref) {
  final repo = ref.watch(overtimeRepositoryProvider);
  return OvertimeActionNotifier(repo, ref);
});
