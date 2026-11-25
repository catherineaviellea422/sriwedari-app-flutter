import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/admin_local_storage.dart';
import '../../../core/storage/user_local_storage.dart';
import '../../admin/domain/models/admin_account_model.dart';
import '../../user/domain/models/user_account_model.dart';

class AuthSessionSnapshot {
  const AuthSessionSnapshot({
    this.userAccount,
    this.adminAccount,
  });

  final UserAccountModel? userAccount;
  final AdminAccountModel? adminAccount;

  bool get hasAdmin => adminAccount != null;
  bool get hasUser => userAccount != null;
}

class AuthRepository {
  AuthRepository({
    required ApiClient userApiClient,
    required ApiClient adminApiClient,
    required this.userStorage,
    required this.adminStorage,
  })  : _userApi = userApiClient,
        _adminApi = adminApiClient;

  final ApiClient _userApi;
  final ApiClient _adminApi;
  final UserLocalStorage userStorage;
  final AdminLocalStorage adminStorage;

  Future<UserAccountModel> loginAsUser({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    final res = await _userApi.post(
      '/user/auth/login',
      data: {
        'email': email.trim(),
        'password': password.trim(),
        'role': 'user',
      },
    );

    final token = (res['token'] ?? '').toString();
    final rawUser = res['user'];
    if (token.isEmpty || rawUser is! Map<String, dynamic>) {
      throw const ApiException(message: 'Respons login pengguna tidak valid.');
    }

    final user = UserAccountModel.fromJson(rawUser);
    await userStorage.saveToken(token);
    await userStorage.saveUserProfileJson(user.toJson());
    await userStorage.setRememberMe(rememberMe);
    return user;
  }

  Future<AdminAccountModel> loginAsAdmin({
    required String email,
    required String password,
  }) async {
    final res = await _adminApi.post(
      '/admin/auth/login',
      data: {
        'email': email.trim(),
        'password': password.trim(),
        'role': 'admin',
      },
    );

    final token = (res['token'] ?? '').toString();
    final rawAdmin = res['user'];
    if (token.isEmpty || rawAdmin is! Map<String, dynamic>) {
      throw const ApiException(message: 'Respons login administrator tidak valid.');
    }

    final admin = AdminAccountModel.fromJson(rawAdmin);
    if (!admin.isAdmin) {
      throw const ApiException(
        message: 'Akun ini tidak memiliki wewenang Kurator / Administrator.',
        statusCode: 403,
      );
    }

    await adminStorage.saveToken(token);
    await adminStorage.saveAdminProfileJson(admin.toJson());
    return admin;
  }

  Future<UserAccountModel> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final res = await _userApi.post(
      '/user/auth/register',
      data: {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password.trim(),
      },
    );

    final token = (res['token'] ?? '').toString();
    final rawUser = res['user'];
    if (token.isEmpty || rawUser is! Map<String, dynamic>) {
      throw const ApiException(message: 'Respons registrasi tidak valid.');
    }

    final user = UserAccountModel.fromJson(rawUser);
    await userStorage.saveToken(token);
    await userStorage.saveUserProfileJson(user.toJson());
    return user;
  }

  Future<({bool found, String message, String? resetCode})> requestPasswordReset(
    String identifier,
  ) async {
    final res = await _userApi.post(
      '/user/auth/forgot-password',
      data: {'identifier': identifier.trim()},
    );
    return (
      found: res['found'] == true,
      message: (res['message'] ?? 'Instruksi pemulihan telah dikirim.').toString(),
      resetCode: res['resetCode']?.toString(),
    );
  }

  Future<String> confirmPasswordReset({
    required String identifier,
    required String code,
    required String newPassword,
  }) async {
    final res = await _userApi.post(
      '/user/auth/reset-password',
      data: {
        'identifier': identifier.trim(),
        'code': code.trim(),
        'newPassword': newPassword.trim(),
      },
    );
    return (res['message'] ?? 'Kata sandi berhasil diperbarui.').toString();
  }

  Future<void> logoutUser() async {
    try {
      await _userApi.post('/user/auth/logout');
    } on ApiException catch (_) {
      // Tetap lanjut bersihkan sesi lokal walau jaringan offline
    } on DioException catch (_) {
      // Tetap lanjut bersihkan sesi lokal
    } finally {
      await userStorage.clearSession();
    }
  }

  Future<void> logoutAdmin() async {
    try {
      await _adminApi.post('/admin/auth/logout');
    } on ApiException catch (_) {
      // Tetap lanjut bersihkan sesi lokal walau jaringan offline
    } on DioException catch (_) {
      // Tetap lanjut bersihkan sesi lokal
    } finally {
      await adminStorage.clearSession();
    }
  }

  Future<AuthSessionSnapshot> restoreSession() async {
    final adminToken = await adminStorage.getToken();
    if (adminToken != null && adminToken.isNotEmpty) {
      try {
        final res = await _adminApi.get('/admin/auth/me');
        final raw = res['user'];
        if (raw is Map<String, dynamic>) {
          final admin = AdminAccountModel.fromJson(raw);
          await adminStorage.saveAdminProfileJson(admin.toJson());
          return AuthSessionSnapshot(adminAccount: admin);
        }
      } on ApiException catch (e) {
        if (e.isUnauthorized || e.isForbidden) {
          await adminStorage.clearSession();
        } else {
          final cached = await adminStorage.getAdminProfileJson();
          if (cached != null) {
            return AuthSessionSnapshot(
              adminAccount: AdminAccountModel.fromJson(cached),
            );
          }
        }
      }
    }

    final userToken = await userStorage.getToken();
    if (userToken != null && userToken.isNotEmpty) {
      try {
        final res = await _userApi.get('/user/auth/me');
        final raw = res['user'];
        if (raw is Map<String, dynamic>) {
          final user = UserAccountModel.fromJson(raw);
          await userStorage.saveUserProfileJson(user.toJson());
          return AuthSessionSnapshot(userAccount: user);
        }
      } on ApiException catch (e) {
        if (e.isUnauthorized || e.isForbidden) {
          await userStorage.clearSession();
        } else {
          final cached = await userStorage.getUserProfileJson();
          if (cached != null) {
            return AuthSessionSnapshot(
              userAccount: UserAccountModel.fromJson(cached),
            );
          }
        }
      }
    }

    return const AuthSessionSnapshot();
  }
}
