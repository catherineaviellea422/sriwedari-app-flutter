import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../admin/domain/models/admin_account_model.dart';
import '../../../user/domain/models/user_account_model.dart';
import '../../data/auth_repository.dart';

enum AuthStatus { unauthenticated, authenticatedUser, authenticatedAdmin }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.userAccount,
    this.adminAccount,
    this.isLoading = false,
    this.isInitialized = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserAccountModel? userAccount;
  final AdminAccountModel? adminAccount;
  final bool isLoading;
  final bool isInitialized;
  final String? errorMessage;

  bool get isAuthenticated => status != AuthStatus.unauthenticated;
  bool get isUser => status == AuthStatus.authenticatedUser;
  bool get isAdmin => status == AuthStatus.authenticatedAdmin;

  String get displayName {
    if (isAdmin && adminAccount != null) return adminAccount!.name;
    if (isUser && userAccount != null) return userAccount!.name;
    return 'Tamu Budaya';
  }

  String get displayEmail {
    if (isAdmin && adminAccount != null) return adminAccount!.email;
    if (isUser && userAccount != null) return userAccount!.email;
    return 'Pengunjung Umum';
  }

  AuthState copyWith({
    AuthStatus? status,
    UserAccountModel? userAccount,
    AdminAccountModel? adminAccount,
    bool clearUser = false,
    bool clearAdmin = false,
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      userAccount: clearUser ? null : (userAccount ?? this.userAccount),
      adminAccount: clearAdmin ? null : (adminAccount ?? this.adminAccount),
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        userAccount,
        adminAccount,
        isLoading,
        isInitialized,
        errorMessage,
      ];
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    userApiClient: ref.watch(userApiClientProvider),
    adminApiClient: ref.watch(adminApiClientProvider),
    userStorage: ref.watch(userLocalStorageProvider),
    adminStorage: ref.watch(adminLocalStorageProvider),
  );
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    ref.listen<int>(sessionExpiredSignalProvider, (_, next) {
      if (next > 0 && state.isAuthenticated) {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          isInitialized: true,
          errorMessage: 'Sesi Anda telah berakhir. Silakan masuk kembali.',
        );
      }
    });
    return const AuthState();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> restoreSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final snapshot = await _repo.restoreSession();
      if (snapshot.hasAdmin) {
        state = AuthState(
          status: AuthStatus.authenticatedAdmin,
          adminAccount: snapshot.adminAccount,
          isInitialized: true,
        );
      } else if (snapshot.hasUser) {
        state = AuthState(
          status: AuthStatus.authenticatedUser,
          userAccount: snapshot.userAccount,
          isInitialized: true,
        );
      } else {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          isInitialized: true,
        );
      }
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        isInitialized: true,
      );
    }
  }

  Future<bool> loginAsUser({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Pastikan sesi admin sebelumnya dibersihkan saat beralih ke sesi user
      await _repo.logoutAdmin();
      final user = await _repo.loginAsUser(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );
      state = AuthState(
        status: AuthStatus.authenticatedUser,
        userAccount: user,
        isInitialized: true,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: 'Gagal masuk. Periksa koneksi Anda.',
      );
      return false;
    }
  }

  Future<bool> loginAsAdmin({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Pastikan sesi user sebelumnya dibersihkan saat beralih ke panel admin
      await _repo.logoutUser();
      final admin = await _repo.loginAsAdmin(email: email, password: password);
      state = AuthState(
        status: AuthStatus.authenticatedAdmin,
        adminAccount: admin,
        isInitialized: true,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: 'Gagal masuk sebagai Admin. Periksa koneksi Anda.',
      );
      return false;
    }
  }

  Future<bool> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.logoutAdmin();
      final user = await _repo.registerUser(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      state = AuthState(
        status: AuthStatus.authenticatedUser,
        userAccount: user,
        isInitialized: true,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: 'Pendaftaran akun gagal.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    final wasAdmin = state.isAdmin;
    state = state.copyWith(isLoading: true, clearError: true);
    if (wasAdmin) {
      await _repo.logoutAdmin();
    } else {
      await _repo.logoutUser();
    }
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      isInitialized: true,
    );
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  void updateUserAccount(UserAccountModel updated) {
    if (state.isUser) {
      state = state.copyWith(userAccount: updated);
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Listenable bridge untuk GoRouter.refreshListenable.
class AuthRouterNotifier extends ChangeNotifier {
  AuthRouterNotifier(this.ref) {
    ref.listen<AuthState>(authProvider, (_, _) {
      notifyListeners();
    });
  }

  final Ref ref;
}

final authRouterRefreshProvider = Provider<AuthRouterNotifier>((ref) {
  final notifier = AuthRouterNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});
