// lib/data/network/network_api_sarvices.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:tobeque/data/app_exception.dart';
import 'package:tobeque/data/network/base_api_sarvices.dart';
import 'package:tobeque/services/shared_pref.dart';

class NetworkApi extends BaseApiServices {

// put these inside the NetworkApi class

bool _isHtmlResponse(Response res) {
  final ct = res.headers.value('content-type')?.toLowerCase() ?? '';
  if (ct.contains('text/html')) return true;
  final data = res.data;
  if (data is String) {
    final s = data.trimLeft();
    if (s.startsWith('<!doctype html') || s.startsWith('<html')) return true;
  }
  return false;
}

String _htmlTitle(Response res) {
  final data = (res.data is String) ? (res.data as String) : '';
  final m = RegExp(r'<title>([^<]+)</title>', caseSensitive: false).firstMatch(data);
  return m?.group(1)?.trim() ?? 'Unexpected HTML response';
}

/// Run the request with 2 retries on 5xx or HTML pages (e.g. 502/503/504).
Future<Response<dynamic>> _withRetries(Future<Response<dynamic>> Function() run) async {
  DioException? last;
  const tries = 3;
  for (var attempt = 0; attempt < tries; attempt++) {
    try {
      final res = await run();

      // If server answered with HTML (error page), decide to retry/throw
      if (_isHtmlResponse(res)) {
        if (attempt < tries - 1) {
          await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
          continue;
        }
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
          error: _htmlTitle(res),
        );
      }

      // Retry on transient 5xx
      final sc = res.statusCode ?? 0;
      if (sc >= 500 && sc <= 599) {
        if (attempt < tries - 1) {
          await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
          continue;
        }
      }

      return res; // success
    } on DioException catch (e) {
      last = e;
      final sc = e.response?.statusCode ?? 0;
      final transient = sc >= 500 && sc <= 599;
      final htmlErr = (e.response != null) && _isHtmlResponse(e.response!);
      if (attempt < tries - 1 && (transient || htmlErr || e.type == DioExceptionType.receiveTimeout)) {
        await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
        continue;
      }
      rethrow;
    }
  }
  // should not reach; but in case
  throw last ?? DioException(requestOptions: RequestOptions(path: 'unknown'));
}




  late final Dio _dio;

  // Host + base paths
  static const _baseOrigin  = 'https://tobeque.com';
  static const _apiBasePath = 'https://tobeque.com/wp-json/wc/store/v1/';

  // Storage keys
  static const _kCartTokenKey = 'cart_token';
  static const _kNonceKey     = 'wc_nonce';
  static const _kCookiesKey   = 'wc_cookies';  // List<String> of Set-Cookie lines
  static const _kNonceTsKey   = 'wc_nonce_ts'; // epoch seconds
  static const _nonceSkewSec  = 50;            // refresh if older than 50s

  String? _nonce;
  String? _cartToken;

  NetworkApi() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _apiBasePath,
        connectTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
        headers: const {
          'Content-Type': 'application/json',
           'Accept': 'application/json',
          'Origin' : _baseOrigin,
          'Referer': '$_baseOrigin/',
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
        // Avoid recursion; skip ensureNonce for bootstrap /cart call
        final isBootstrap = options.extra['bootstrap'] == true;
        final method = options.method.toUpperCase();
        final isMutating = method == 'POST' || method == 'PUT' || method == 'PATCH' || method == 'DELETE';

        if (!isBootstrap && isMutating) {
          await _ensureNonce();
        }

        // Attach headers
        final headers = await _headers();
        options.headers.addAll(headers);

        // Attach cookies
        final cookieHeader = await _cookieHeader();
        if (cookieHeader != null && cookieHeader.isNotEmpty) {
          options.headers['Cookie'] = cookieHeader;
        }

        handler.next(options);
      },

      onResponse: (res, handler) async {
        // Persist fresh Nonce / Cart-Token if server sends them
        final newNonce =
            res.headers.value('X-WC-Store-API-Nonce') ?? res.headers.value('nonce');
        final newCartToken =
            res.headers.value('X-WC-Store-API-Cart-Token') ?? res.headers.value('cart-token');

        if (newNonce != null && newNonce.isNotEmpty) {
          _nonce = newNonce;
          await SharedPrefService.setString(_kNonceKey, newNonce);
        }
        if (newCartToken != null && newCartToken.isNotEmpty) {
          _cartToken = newCartToken;
          await SharedPrefService.setString(_kCartTokenKey, newCartToken);
        }

        // Persist nonce timestamp if present, else set "now"
        final ts = res.headers.value('nonce-timestamp');
        await SharedPrefService.setString(
          _kNonceTsKey,
          (ts != null && ts.isNotEmpty)
              ? ts
              : (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
        );

        // Persist cookies
        final setCookies = res.headers['set-cookie'];
        if (setCookies != null && setCookies.isNotEmpty) {
          final existing = await SharedPrefService.getStringList(_kCookiesKey) ?? <String>[];
          final merged = _mergeCookies(existing, setCookies);
          await SharedPrefService.setStringList(_kCookiesKey, merged);
        }

        handler.next(res);
      },

      onError: (e, handler) async {
        // Retry once when nonce is missing/expired
        final code = (e.response?.data is Map) ? (e.response?.data['code'] as String?) : null;
        final missingNonce = e.response?.statusCode == 401 &&
            (code == 'woocommerce_rest_missing_nonce' || code == 'woocommerce_store_api_missing_nonce');

        // Only retry if original request was NOT bootstrap
        if (missingNonce && e.requestOptions.extra['bootstrap'] != true) {
          try {
            _nonce = null; // force refresh
            await _ensureNonce();

            final clone = await _retry(e.requestOptions);
            return handler.resolve(clone);
          } on DioException catch (ee) {
            return handler.reject(ee);
          }
        }

        // Map to your app exceptions
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          return handler.reject(DioException(
            requestOptions: e.requestOptions,
            error: RequestTimeout(),
            type: e.type,
            response: e.response,
          ));
        } else if (e.type == DioExceptionType.badResponse) {
          return handler.reject(DioException(
            requestOptions: e.requestOptions,
            error: FatchDataException(e.response?.data.toString() ?? 'Server error'),
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

  // -------------------- Nonce / session bootstrap --------------------

  Future<void> _ensureNonce() async {
    // Use cached if present and still fresh
    if (_nonce != null && _cartToken != null) {
      final tsStr = await SharedPrefService.getString(_kNonceTsKey);
      if (_isNonceFresh(tsStr)) return;
    } else {
      // Try persisted first
      _nonce     ??= await SharedPrefService.getString(_kNonceKey);
      _cartToken ??= await SharedPrefService.getString(_kCartTokenKey);
      final tsStr = await SharedPrefService.getString(_kNonceTsKey);
      if (_nonce != null && _cartToken != null && _isNonceFresh(tsStr)) return;
    }

    // Bootstrap: GET /cart (bypass ensureNonce via extra flag)
  
final res = await _withRetries(() => _dio.get(
  'cart',
  options: Options(extra: {'bootstrap': true}),
));
    String? _h(String n) => res.headers.value(n) ?? res.headers.value(n.toLowerCase());

    _nonce     = _h('X-WC-Store-API-Nonce')      ?? _h('nonce');
    _cartToken = _h('X-WC-Store-API-Cart-Token') ?? _h('cart-token');

    if (_nonce != null)     await SharedPrefService.setString(_kNonceKey, _nonce!);
    if (_cartToken != null) await SharedPrefService.setString(_kCartTokenKey, _cartToken!);

    final ts = _h('nonce-timestamp');
    await SharedPrefService.setString(
      _kNonceTsKey,
      (ts != null && ts.isNotEmpty)
          ? ts
          : (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
    );

    // Save cookies
    final setCookies = res.headers['set-cookie'];
    if (setCookies != null && setCookies.isNotEmpty) {
      await SharedPrefService.setStringList(_kCookiesKey, setCookies);
    }
  }

  bool _isNonceFresh(String? tsStr) {
    if (tsStr == null || tsStr.isEmpty) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final ts  = int.tryParse(tsStr) ?? 0;
    return (now - ts) < _nonceSkewSec;
  }

  Future<Map<String, String>> _headers() async {
    final authToken = await SharedPrefService.getToken() ?? '';
    final nonce     = _nonce     ?? await SharedPrefService.getString(_kNonceKey)     ?? '';
    final cartToken = _cartToken ?? await SharedPrefService.getString(_kCartTokenKey) ?? '';

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Origin' : _baseOrigin,
      'Referer': '$_baseOrigin/',
    };

    if (nonce.isNotEmpty) {
      headers['X-WC-Store-API-Nonce'] = nonce;
      headers['Nonce'] = nonce; // some setups still check this
    }
    if (cartToken.isNotEmpty) {
      headers['X-WC-Store-API-Cart-Token'] = cartToken;
      headers['Cart-Token'] = cartToken;
    }
    if (authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  Future<String?> _cookieHeader() async {
    final setCookieLines = await SharedPrefService.getStringList(_kCookiesKey);
    if (setCookieLines == null || setCookieLines.isEmpty) return null;

    // Convert "name=value; Path=/; ..." → "name=value"
    final pairs = <String>[];
    for (final line in setCookieLines) {
      final firstSemi = line.indexOf(';');
      final main = firstSemi == -1 ? line : line.substring(0, firstSemi);
      if (main.contains('=')) pairs.add(main.trim());
    }
    return pairs.join('; ');
  }

  List<String> _mergeCookies(List<String> existing, List<String> incoming) {
    final map = <String, String>{};
    void addAll(List<String> src) {
      for (final s in src) {
        final firstSemi = s.indexOf(';');
        final main = firstSemi == -1 ? s : s.substring(0, firstSemi);
        final eq = main.indexOf('=');
        if (eq > 0) {
          final name = main.substring(0, eq).trim();
          map[name] = s; // keep full Set-Cookie line
        }
      }
    }
    addAll(existing);
    addAll(incoming); // incoming overrides
    return map.values.toList();
  }

  Future<Response<dynamic>> _retry(RequestOptions ro) {
    final options = Options(
      method: ro.method,
      headers: ro.headers,
      responseType: ro.responseType,
      contentType: ro.contentType,
      followRedirects: ro.followRedirects,
      sendTimeout: ro.sendTimeout,
      receiveTimeout: ro.receiveTimeout,
    );
    return _dio.request<dynamic>(
      ro.path,
      data: ro.data,
      queryParameters: ro.queryParameters,
      options: options,
      cancelToken: ro.cancelToken,
      onReceiveProgress: ro.onReceiveProgress,
      onSendProgress: ro.onSendProgress,
    );
  }

  // -------------------- BaseApiServices --------------------

// in getApi/postApi/putApi/delete, wrap the _dio call:

@override
Future<dynamic> getApi(String url) async {
  try {
    final res = await _withRetries(() => _dio.get(url));
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
    final res = await _withRetries(() => _dio.post(url, data: data));
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
    final res = await _withRetries(() => _dio.put(url, data: data));
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
    final res = await _withRetries(() => _dio.delete(url, data: data));
    return _returnResponse(res);
  } on SocketException {
    throw InternetException();
  } on DioException catch (e) {
    _handleDioError(e);
  }
}

dynamic _returnResponse(Response response) {
  // Block accidental HTML
  if (_isHtmlResponse(response)) {
    final title = _htmlTitle(response);
    throw FatchDataException(title.isEmpty ? 'Unexpected HTML from server' : title);
  }

  switch (response.statusCode) {
    case 200:
    case 201:
      return response.data;

      case 204:
        // Successful, but no body (e.g. DELETE cart item). Return a simple flag.
        return true;
    case 400:
      throw InvalidInputException(response.data.toString());
    case 401:
    case 403:
      throw ServerException(); // auth/nonce handled by interceptors
    case 502:
    case 503:
    case 504:
      throw FatchDataException('Server temporarily unavailable (${response.statusCode}). Please try again.');
    default:
      throw FatchDataException(response.data?.toString() ?? 'Server error');
  }
}

  // Make sure your AppException types all have a `message` ctor param.
Never _handleDioError(DioException e) {
  final res = e.response;
  String msg = e.message ?? 'Server error';

  if (res != null) {
    final data = res.data;
    if (data is Map && data['message'] != null) {
      msg = data['message'].toString();
    } else if (data is String && data.isNotEmpty) {
      msg = data;
    }

    switch (res.statusCode) {
      case 400:
        throw InvalidInputException(msg);
      case 401:
      case 403:
        // Let UI decide to show a “Log in” button based on this message
        throw FatchDataException(msg); // or a dedicated UnauthorizedException(msg)
      case 502:
      case 503:
      case 504:
        throw FatchDataException('Server temporarily unavailable (${res.statusCode}). Please try again.');
      default:
        throw FatchDataException(msg);
    }
  }

  // No response object (timeout, handshake, etc.)
  throw FatchDataException(msg);
}

  // -------------------- Helpers --------------------

  Future<void> clearWcSession() async {
    _nonce = null;
    _cartToken = null;
    await SharedPrefService.setString(_kNonceKey, '');
    await SharedPrefService.setString(_kCartTokenKey, '');
    await SharedPrefService.setString(_kNonceTsKey, '');
    await SharedPrefService.setStringList(_kCookiesKey, <String>[]);
  }
}
