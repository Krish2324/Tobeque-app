// lib/data/network/network_api_sarvices.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/data/app_exception.dart';
import 'package:tobeque/data/network/base_api_sarvices.dart';
import 'package:tobeque/services/shared_pref.dart';

class NetworkApi extends BaseApiServices {
  late final Dio _dio;

  NetworkApi() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstant.apiBase,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
      ));
    }

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SharedPrefService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (res, handler) {
        handler.next(res);
      },
      onError: (e, handler) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          return handler.reject(DioException(
            requestOptions: e.requestOptions,
            error: RequestTimeout(),
            type: e.type,
            response: e.response,
          ));
        } else if (e.type == DioExceptionType.badResponse) {
          final msg = _extractMessage(e.response);
          return handler.reject(DioException(
            requestOptions: e.requestOptions,
            error: FatchDataException(msg),
            type: e.type,
            response: e.response,
          ));
        } else if (e.type == DioExceptionType.unknown && e.error is SocketException) {
          return handler.reject(DioException(
            requestOptions: e.requestOptions,
            error: InternetException(),
            type: e.type,
          ));
        } else {
          return handler.reject(DioException(
            requestOptions: e.requestOptions,
            error: ServerException(),
            type: e.type,
            response: e.response,
          ));
        }
      },
    ));
  }

  static String _extractMessage(Response? res) {
    if (res == null || res.data == null) return 'Server error';
    final data = res.data;
    if (data is Map) {
      if (data['message'] != null) return data['message'].toString();
      if (data['error'] != null) return data['error'].toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return 'Server error (${res.statusCode})';
  }

  String _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('/')) {
      return '${ApiConstant.apiBase}$url';
    }
    return '${ApiConstant.apiBase}/$url';
  }

  @override
  Future<dynamic> getApi(String url) async {
    try {
      final res = await _dio.get(_resolveUrl(url));
      return _returnResponse(res);
    } on SocketException {
      throw InternetException();
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<dynamic> postApi(dynamic data, String url) async {
    try {
      final res = await _dio.post(_resolveUrl(url), data: data);
      return _returnResponse(res);
    } on SocketException {
      throw InternetException();
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<dynamic> putApi(dynamic data, String url) async {
    try {
      final res = await _dio.put(_resolveUrl(url), data: data);
      return _returnResponse(res);
    } on SocketException {
      throw InternetException();
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<dynamic> delete(dynamic data, String url) async {
    try {
      final res = await _dio.delete(_resolveUrl(url), data: data);
      return _returnResponse(res);
    } on SocketException {
      throw InternetException();
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  dynamic _returnResponse(Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return response.data;
      case 204:
        return true;
      case 400:
        throw InvalidInputException(_extractMessage(response));
      case 401:
      case 403:
        throw FatchDataException(_extractMessage(response));
      case 502:
      case 503:
      case 504:
        throw FatchDataException('Server temporarily unavailable (${response.statusCode}). Please try again.');
      default:
        throw FatchDataException(_extractMessage(response));
    }
  }

  Never _handleDioError(DioException e) {
    final res = e.response;
    final msg = _extractMessage(res);

    if (res != null) {
      switch (res.statusCode) {
        case 400:
          throw InvalidInputException(msg);
        case 401:
        case 403:
          throw FatchDataException(msg);
        default:
          throw FatchDataException(msg);
      }
    }
    throw FatchDataException(e.message ?? 'Server error');
  }

  Future<void> clearWcSession() async {
    await SharedPrefService.removeToken();
  }
}

