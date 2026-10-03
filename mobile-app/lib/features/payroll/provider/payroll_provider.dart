import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/network_provider.dart';
import '../data/payroll_models.dart';
import '../data/payroll_repository.dart';

final payrollRepositoryProvider = Provider<PayrollRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return PayrollRepository(client);
});

final myPayrollSlipsProvider = FutureProvider.autoDispose<List<PayrollSlipModel>>((ref) async {
  final repo = ref.watch(payrollRepositoryProvider);
  return repo.getMySlips();
});

// Alias for backwards compatibility
final mySlipsProvider = myPayrollSlipsProvider;

class PayrollDownloadState {
  final bool isLoading;
  final bool isSuccess;
  final String? resultMessage;
  final String? errorMessage;

  const PayrollDownloadState({
    this.isLoading = false,
    this.isSuccess = false,
    this.resultMessage,
    this.errorMessage,
  });
}

class PayrollDownloadNotifier extends StateNotifier<PayrollDownloadState> {
  final PayrollRepository _repository;

  PayrollDownloadNotifier(this._repository) : super(const PayrollDownloadState());

  Future<bool> downloadSlipPdf(int slipId) async {
    state = const PayrollDownloadState(isLoading: true);
    try {
      final result = await _repository.downloadSlipPdf(slipId);
      state = PayrollDownloadState(
        isSuccess: true,
        resultMessage: result,
      );
      return true;
    } catch (e) {
      final msg = e is ApiException
          ? e.userFriendlyMessage
          : e.toString().replaceFirst('Exception: ', '');
      state = PayrollDownloadState(
        errorMessage: msg,
      );
      return false;
    }
  }

  void reset() {
    state = const PayrollDownloadState();
  }
}

final payrollDownloadNotifierProvider =
    StateNotifierProvider.autoDispose<PayrollDownloadNotifier, PayrollDownloadState>((ref) {
  final repo = ref.watch(payrollRepositoryProvider);
  return PayrollDownloadNotifier(repo);
});

// Alias matching prompt name
final payrollDownloadProvider = payrollDownloadNotifierProvider;
