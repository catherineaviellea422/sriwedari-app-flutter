import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'api_exception.dart';

enum ApiScope { user, admin }

typedef TokenReader = Future<String?> Function();
typedef UnauthorizedCallback = Future<void> Function();

class ApiClient {
  ApiClient({
    required String baseUrl,
    required this.scope,
    required this.readToken,
    this.onUnauthorized,
    Dio? dioOverride,
  }) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    _dio = dioOverride ??
        Dio(
          BaseOptions(
            baseUrl: '$normalizedBase/api',
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['X-Sriwedari-Scope'] = scope.name;
          handler.next(options);
        },
        onError: (err, handler) async {
          if (err.response?.statusCode == 401 && onUnauthorized != null) {
            await onUnauthorized!();
          }
          handler.next(err);
        },
      ),
    );
  }

  final ApiScope scope;
  final TokenReader readToken;
  final UnauthorizedCallback? onUnauthorized;
  late final Dio _dio;

  Dio get rawDio => _dio;

  String get scopePrefix => scope == ApiScope.admin ? '/admin' : '/user';

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return _unwrapResponse(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<String> getRawText(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<String>(
        path,
        queryParameters: queryParameters,
        options: Options(responseType: ResponseType.plain),
      );
      return response.data ?? '';
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _unwrapResponse(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _unwrapResponse(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _unwrapResponse(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _unwrapResponse(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> uploadBytes({
    required Uint8List bytes,
    required String filename,
    String prefix = 'upload',
  }) async {
    try {
      final formData = FormData.fromMap({
        'prefix': prefix,
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post<dynamic>(
        '/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return _unwrapResponse(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Map<String, dynamic> _unwrapResponse(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data['success'] == false) {
        throw ApiException(
          message: (data['error'] ?? data['message'] ?? 'Permintaan gagal').toString(),
          statusCode: response.statusCode,
          details: data,
        );
      }
      return data;
    }
    return {'success': true, 'data': data};
  }
}
