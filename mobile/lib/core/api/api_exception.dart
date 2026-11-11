import 'package:dio/dio.dart';

/// Error with a message that can be shown to the user.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    // FastAPI puts the error text into "detail"
    if (data is Map && data['detail'] is String) {
      return ApiException(data['detail'] as String, statusCode: statusCode);
    }
    if (statusCode == 422) {
      return ApiException(
        'Please check the entered data',
        statusCode: statusCode,
      );
    }
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('No connection to the server');
      default:
        return ApiException('Something went wrong', statusCode: statusCode);
    }
  }

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}