import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tobeque/constants/api_constants.dart';

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  static const _kTokenKey = 'auth_token';
  static const _kUserIdKey = 'user_id';

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

  Future<String?> getUserId() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kUserIdKey);
  }

  Future<void> saveUserId(String id) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kUserIdKey, id);
  }

  // ---------- Auth ----------
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final res = await _dio.post(ApiConstant.login, data: {
      'identifier': identifier,
      'email': identifier,
      'phone': identifier,
      'password': password,
    });
    final data = Map<String, dynamic>.from(res.data);
    if (data['token'] != null) {
      await saveToken(data['token'].toString());
    }
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final res = await _dio.post(ApiConstant.register, data: {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'password': password,
    });
    final data = Map<String, dynamic>.from(res.data);
    if (data['token'] != null) {
      await saveToken(data['token'].toString());
    }
    return data;
  }

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final res = await _dio.post(ApiConstant.sendOtp, data: {'phone': phone});
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final res = await _dio.post(ApiConstant.verifyOtp, data: {'phone': phone, 'otp': otp});
    final data = Map<String, dynamic>.from(res.data);
    if (data['token'] != null) {
      await saveToken(data['token'].toString());
    }
    return data;
  }

  Future<Map<String, dynamic>> fetchMe({String? token}) async {
    final jwt = token ?? await getToken();
    final res = await _dio.get(ApiConstant.userProfile, options: Options(headers: {
      if (jwt != null) 'Authorization': 'Bearer $jwt',
      'Accept': 'application/json',
    }));
    final data = Map<String, dynamic>.from(res.data);
    return (data['user'] as Map?)?.cast<String, dynamic>() ?? data;
  }

  Future<Map<String, dynamic>> updateCustomer({
    String? token,
    required Map<String, dynamic> payload,
  }) async {
    final jwt = token ?? await getToken();
    final res = await _dio.put(ApiConstant.userProfile, data: payload, options: Options(headers: {
      if (jwt != null) 'Authorization': 'Bearer $jwt',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    }));
    final data = Map<String, dynamic>.from(res.data);
    return (data['user'] as Map?)?.cast<String, dynamic>() ?? data;
  }

  // ---------- Orders ----------
  Future<List<Map<String, dynamic>>> fetchOrders({String? token}) async {
    final jwt = token ?? await getToken();
    final res = await _dio.get(ApiConstant.userOrders, options: Options(headers: {
      if (jwt != null) 'Authorization': 'Bearer $jwt',
      'Accept': 'application/json',
    }));
    final data = res.data;
    if (data is Map && data['orders'] is List) {
      return (data['orders'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } else if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }
}

