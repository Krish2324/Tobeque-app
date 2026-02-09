// lib/data/dio_client.dart
import 'package:dio/dio.dart';

class DioClient {
  static Dio build() {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ));
    return dio;
  }
}
