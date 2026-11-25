import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final dynamic details;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isNetworkError => statusCode == null;

  factory ApiException.fromDioException(DioException err) {
    final status = err.response?.statusCode;
    final data = err.response?.data;

    String? serverMessage;
    if (data is Map<String, dynamic>) {
      serverMessage = (data['error'] ?? data['message'])?.toString();
    }

    if (serverMessage != null && serverMessage.isNotEmpty) {
      return ApiException(
        message: serverMessage,
        statusCode: status,
        details: data,
      );
    }

    final fallbackMessage = switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Koneksi ke server Galeri Sriwedari habis waktu. Periksa jaringan Anda.',
      DioExceptionType.connectionError =>
        'Tidak dapat terhubung ke server Sriwedari. Pastikan backend aktif.',
      DioExceptionType.cancel => 'Permintaan dibatalkan.',
      DioExceptionType.badResponse => switch (status) {
          400 => 'Data permintaan tidak valid.',
          401 => 'Sesi berakhir atau tidak terautentikasi. Silakan masuk kembali.',
          403 => 'Anda tidak memiliki hak akses untuk tindakan ini.',
          404 => 'Data yang diminta tidak ditemukan.',
          409 => 'Terjadi konflik data (misal: email sudah terdaftar).',
          500 => 'Terjadi kesalahan pada server Sriwedari.',
          _ => 'Permintaan gagal dengan kode $status.',
        },
      _ => 'Terjadi gangguan koneksi yang tidak terduga.',
    };

    return ApiException(
      message: fallbackMessage,
      statusCode: status,
      details: data,
    );
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
