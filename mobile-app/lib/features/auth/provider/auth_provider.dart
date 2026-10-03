import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_interceptor.dart';
import '../../../core/network/network_provider.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthRepository(client);
});

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final Map<String, dynamic>? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    Map<String, dynamic>? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  String? get role => user?['role'] as String?;
  bool get hasEmployeeProfile => user?['employee'] != null;
  bool get isAdministrator =>
      role == 'owner' || role == 'hr' || role == 'superadmin';
  bool get isEmployee => role == 'employee' && hasEmployeeProfile;

  String get roleLabel {
    switch (role) {
      case 'owner':
        return 'Owner / Direktur';
      case 'hr':
        return 'HR Administrator';
      case 'superadmin':
        return 'Platform Superadmin';
      case 'employee':
        return 'Karyawan';
      default:
        return role != null && role!.isNotEmpty ? role! : 'Karyawan';
    }
  }

  String get userName => user?['name'] as String? ?? 'Karyawan';
  String get userEmail => user?['email'] as String? ?? '';
  String get companyName {
    final company = user?['company'];
    if (company is Map) {
      return company['name'] as String? ?? 'Perusahaan';
    }
    return 'HR Hub Workspace';
  }

  Map<String, dynamic>? get employee =>
      user?['employee'] as Map<String, dynamic>?;
  String? get employeeNik => employee?['nik'] as String?;
  String? get departmentName {
    final dept = employee?['department'];
    if (dept is Map) return dept['name'] as String?;
    return null;
  }
  String? get jobPositionName {
    final job = employee?['job_position'] ?? employee?['jobPosition'];
    if (job is Map) return job['name'] as String?;
    return null;
  }
  String? get branchName {
    final branch = employee?['branch'];
    if (branch is Map) return branch['name'] as String?;
    return null;
  }
  String? get employeePhone => employee?['phone'] as String?;
  String? get employeeGender {
    final g = employee?['gender'] as String?;
    if (g == 'male') return 'Laki-laki';
    if (g == 'female') return 'Perempuan';
    return g;
  }
  String? get employmentStatusLabel {
    final st = employee?['employment_status'] as String?;
    switch (st) {
      case 'permanent':
        return 'Karyawan Tetap';
      case 'contract':
        return 'Karyawan Kontrak';
      case 'probation':
        return 'Masa Percobaan';
      case 'internship':
        return 'Magang';
      default:
        return st ?? 'Karyawan';
    }
  }
  String? get hireDate => employee?['hire_date'] as String?;
  String? get bankName => employee?['bank_name'] as String?;
  String? get bankAccountNumber => employee?['bank_account_number'] as String?;
  String? get bankAccountHolder => employee?['bank_account_holder'] as String?;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;
  static const String userKey = 'auth_user';

  AuthNotifier(this._repository, this._ref) : super(const AuthState());

  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final prefs = await _ref.read(sharedPreferencesProvider.future);
      final token = prefs.getString(AuthInterceptor.tokenKey);
      if (token == null || token.isEmpty) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
        return;
      }

      Map<String, dynamic>? cachedUser;
      final cachedUserStr = prefs.getString(userKey);
      if (cachedUserStr != null && cachedUserStr.isNotEmpty) {
        try {
          cachedUser = jsonDecode(cachedUserStr) as Map<String, dynamic>?;
        } catch (_) {}
      }

      try {
        final profile = await _repository.getProfile();
        await prefs.setString(userKey, jsonEncode(profile));
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: profile,
          isLoading: false,
        );
      } on UnauthorizedException {
        await prefs.remove(AuthInterceptor.tokenKey);
        await prefs.remove(userKey);
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
      } catch (_) {
        if (cachedUser != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: cachedUser,
            isLoading: false,
          );
        } else {
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            isLoading: false,
          );
        }
      }
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _repository.login(email: email, password: password);
      final token = (data['access_token'] ?? data['token']) as String?;

      final prefs = await _ref.read(sharedPreferencesProvider.future);
      if (token != null && token.isNotEmpty) {
        await prefs.setString(AuthInterceptor.tokenKey, token);
      }

      final user = data['user'] as Map<String, dynamic>?;
      if (user != null) {
        await prefs.setString(userKey, jsonEncode(user));
      }

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
      return true;
    } catch (e) {
      String msg = 'Gagal masuk akun. Periksa email dan kata sandi Anda.';
      if (e is ApiException) {
        if (e.errors != null && e.errors!.isNotEmpty) {
          final first = e.errors!.values.first;
          if (first is List && first.isNotEmpty) {
            msg = first.first.toString();
          } else {
            msg = first.toString();
          }
        } else {
          msg = e.message;
        }
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      final profile = await _repository.getProfile();
      final prefs = await _ref.read(sharedPreferencesProvider.future);
      await prefs.setString(userKey, jsonEncode(profile));
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: profile,
      );
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {}
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.remove(AuthInterceptor.tokenKey);
    await prefs.remove(userKey);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void resetAuth() {
    state = const AuthState(status: AuthStatus.unauthenticated);
    _ref.read(sharedPreferencesProvider.future).then((prefs) {
      prefs.remove(AuthInterceptor.tokenKey);
      prefs.remove(userKey);
    }).catchError((_) {});
  }

  void handleUnauthorized() => resetAuth();
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final interceptor = ref.watch(authInterceptorProvider);
  final repo = ref.watch(authRepositoryProvider);
  final notifier = AuthNotifier(repo, ref);
  interceptor.onUnauthorized = notifier.resetAuth;
  return notifier;
});
