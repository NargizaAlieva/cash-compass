import 'package:cash_compass/core/api/api_exception.dart';
import 'package:cash_compass/core/config.dart';
import 'package:cash_compass/core/storage/token_storage.dart';
import 'package:dio/dio.dart';

/// Sends HTTP requests to the server.
///
/// Adds the token to every request and turns network errors
/// into [ApiException].
class ApiClient {
  ApiClient(this._tokenStorage)
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            contentType: 'application/json',
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.read();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? data}) =>
      _send(() => _dio.post<dynamic>(path, data: data));

  Future<dynamic> put(String path, {Object? data}) =>
      _send(() => _dio.put<dynamic>(path, data: data));

  Future<dynamic> delete(String path) =>
      _send(() => _dio.delete<dynamic>(path));

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}