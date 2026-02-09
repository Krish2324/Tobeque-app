// lib/di/app_di.dart
import 'package:tobeque/constants/api_constants.dart';
import 'package:dio/dio.dart';
import '../data/wp_service.dart';

class AppDI {
  static late final Dio dio;
  static late final WPService wp;

  static void init() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConstant.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ));
    wp = WPService(dio);
  }
}
