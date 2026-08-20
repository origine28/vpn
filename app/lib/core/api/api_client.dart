import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({Dio? dio}) : _dio = dio ?? _createDio();

  final Dio _dio;

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.apiTimeout,
        receiveTimeout: AppConfig.apiTimeout,
        sendTimeout: AppConfig.apiTimeout,
        headers: const {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (object) => debugPrint('[api] $object'),
      ),
    );
    return dio;
  }

  Future<dynamic> get(String path) async {
    try {
      final response = await _dio.get<dynamic>(path);
      return response.data;
    } on DioException catch (error) {
      throw ApiException(
        _messageFor(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post<dynamic>(path, data: data);
      return response.data;
    } on DioException catch (error) {
      throw ApiException(
        _messageFor(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  String _messageFor(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return "Délai d'attente dépassé";
      case DioExceptionType.connectionError:
        return 'Impossible de joindre le serveur';
      case DioExceptionType.badResponse:
        return 'Réponse du serveur invalide (${error.response?.statusCode})';
      default:
        return error.message ?? 'Erreur réseau inconnue';
    }
  }
}
