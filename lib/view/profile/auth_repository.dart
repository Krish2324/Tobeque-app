import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  static const _kTokenKey = 'auth_token';
  static const _kUserIdKey = 'wp_user_id';

  Future<String?> getToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kTokenKey);
    }

  Future<void> saveToken(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kTokenKey, token);
  }

  Future<void> clearToken() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kTokenKey);
    await sp.remove(_kUserIdKey);
  }

  Future<int?> getUserId() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kUserIdKey);
  }

  Future<void> saveUserId(int id) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kUserIdKey, id);
  }

  // ---------- Auth ----------
  Future<String> login({
    required String username,
    required String password,
    required String baseUrl,
  }) async {
    final url = '$baseUrl/wp-json/jwt-auth/v1/token';
    final res = await _dio.post(url, data: {
      'username': username,
      'password': password,
    });
    final data = res.data as Map<String, dynamic>;
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      throw 'Invalid credentials';
    }
    return token;
  }

  Future<Map<String, dynamic>> fetchMe({
    required String baseUrl,
    required String token,
  }) async {
    final url = '$baseUrl/wp-json/wp/v2/users/me';
    final res = await _dio.get(url, options: Options(headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    }));
    return Map<String, dynamic>.from(res.data);
  }

  // ---------- Woo Customer (addresses) ----------
  Future<Map<String, dynamic>> fetchCustomer({
    required String baseUrl,
    required int userId,
    required String token,
  }) async {
    final url = '$baseUrl/wp-json/wc/v3/customers/$userId';
    final res = await _dio.get(url, options: Options(headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    }));
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> updateCustomer({
    required String baseUrl,
    required int userId,
    required String token,
    Map<String, dynamic>? payload,
  }) async {
    final url = '$baseUrl/wp-json/wc/v3/customers/$userId';
    final res = await _dio.put(url, data: payload ?? {}, options: Options(headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    }));
    return Map<String, dynamic>.from(res.data);
  }

  // ---------- Orders ----------
  Future<List<Map<String, dynamic>>> fetchOrders({
    required String baseUrl,
    required int userId,
    required String token,
  }) async {
    final url = '$baseUrl/wp-json/wc/v3/orders?customer=$userId&orderby=date&order=desc';
    final res = await _dio.get(url, options: Options(headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    }));
    final list = res.data as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
