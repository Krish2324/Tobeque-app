// lib/view/profile/auth_controller.dart
import 'dart:convert';
import 'dart:math';
import 'package:tobeque/constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tobeque/services/shared_pref.dart';
import 'package:tobeque/services/fcm_service.dart';

/// Your site base
const _kBaseUrl = 'https://tobeque.com';

/// WooCommerce REST (consumer key/secret) — used for in-app SignUp/Reset.
const _wcCk = '';
const _wcCs = '';


/// Build WC v3 URL with CK/CS attached
Uri _wcUrl(String path, [Map<String, dynamic>? q]) {
  final base = Uri.parse('$_kBaseUrl/wp-json/wc/v3$path');
  final qp = <String, dynamic>{
    'consumer_key': _wcCk,
    'consumer_secret': _wcCs,
    if (q != null) ...q,
  };
  return base.replace(queryParameters: qp.map((k, v) => MapEntry(k, '$v')));
}

Future _wcGet(Dio dio, String path, [Map<String, String>? q]) =>
     dio.getUri(_wcUrl(path, q));
Future _wcPost(Dio dio, String path, Map body) =>
    dio.postUri(_wcUrl(path), data: body);
Future _wcPut(Dio dio, String path, Map body) =>
    dio.putUri(_wcUrl(path), data: body);

/// WP/JWT endpoints (for login tokens)
class _Endpoints {
  static String token() => '$_kBaseUrl/wp-json/jwt-auth/v1/token';
  static String me()    => '$_kBaseUrl/wp-json/wp/v2/users/me'; // optional
  // Optional legacy JSON endpoints if you enable plugins later:
  static String register()     => '$_kBaseUrl/wp-json/wp/v3/users/register';
  static String lostPassword() => '$_kBaseUrl/wp-json/wp/v2/users/lostpassword';
}

/// Local persistence keys
class _Keys {
  static const token = 'auth_token';
  static const name  = 'auth_name';
  static const email = 'auth_email';
  static const billing  = 'auth_billing_json';
  static const shipping = 'auth_shipping_json';
  static const staySignedIn = 'auth_stay';
}

class AuthController extends GetxController {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: const {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      // Helps some WP setups:
      'Origin': _kBaseUrl,
      'Referer': _kBaseUrl,
    },
  ));

  // reactive state
  final loading   = false.obs;
  final loggedIn  = false.obs;
  final error     = RxnString();

  // Full user profile data map
  final userProfileData = <String, dynamic>{}.obs;

  // simple profile fields the UI uses
  String _name = '';
  String _email = '';
  String get displayName {
    final fn = userProfileData['firstName']?.toString() ?? '';
    final ln = userProfileData['lastName']?.toString() ?? '';
    final full = '$fn $ln'.trim();
    if (full.isNotEmpty) return full;
    if (_name.isNotEmpty) return _name;
    final ph = userProfileData['phone']?.toString() ?? '';
    if (ph.isNotEmpty) return ph;
    return 'User';
  }
  String get email => (userProfileData['email']?.toString() ?? '').isNotEmpty
      ? userProfileData['email'].toString()
      : _email;

  String get phone => userProfileData['phone']?.toString() ?? '';
  String get firstName => userProfileData['firstName']?.toString() ?? '';
  String get lastName => userProfileData['lastName']?.toString() ?? '';
  String get gender => userProfileData['gender']?.toString() ?? '';
  String get profilePhoto {
    final photo = userProfileData['profilePhoto']?.toString() ?? '';
    if (photo.isEmpty) return '';
    return ApiConstant.getImageUrl(photo);
  }

  String get address => userProfileData['address']?.toString() ?? '';
  String get city => userProfileData['city']?.toString() ?? '';
  String get state => userProfileData['state']?.toString() ?? '';
  String get zipCode => userProfileData['zipCode']?.toString() ?? '';

  String get shippingAddress => userProfileData['shippingAddress']?.toString() ?? '';
  String get shippingCity => userProfileData['shippingCity']?.toString() ?? '';
  String get shippingState => userProfileData['shippingState']?.toString() ?? '';
  String get shippingZipCode => userProfileData['shippingZipCode']?.toString() ?? '';

  // addresses stored locally
  Map<String, dynamic> _billing  = {};
  Map<String, dynamic> _shipping = {};
  Map<String, dynamic> get billing  => _billing;
  Map<String, dynamic> get shipping => _shipping;

  String? _token;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _restore();
  }

  /* ------------------------------------------------------------------------
   * FETCH USER PROFILE (backend sync)
   * --------------------------------------------------------------------- */
  Future<void> fetchUserProfile() async {
    if (_token == null || _token!.isEmpty) return;
    try {
      final res = await dio.get(
        '${ApiConstant.apiBase}/user-auth/profile',
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );
      if (res.data is Map && res.data['user'] != null) {
        final u = Map<String, dynamic>.from(res.data['user'] as Map);
        userProfileData.value = u;
        final fn = (u['firstName'] ?? '').toString();
        final ln = (u['lastName'] ?? '').toString();
        _name = '$fn $ln'.trim();
        _email = (u['email'] ?? '').toString();

        final sp = await SharedPreferences.getInstance();
        await sp.setString('cached_user_profile', json.encode(u));
        if (_name.isNotEmpty) await sp.setString(_Keys.name, _name);
        if (_email.isNotEmpty) await sp.setString(_Keys.email, _email);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        logout();
        error.value = _prettyError(e) ?? 'Your session has expired due to inactivity. Please log in again.';
      } else {
        print('fetchUserProfile dio error: ${e.message}');
      }
    } catch (e) {
      print('fetchUserProfile error: $e');
    }
  }

  /* ------------------------------------------------------------------------
   * UPDATE USER PROFILE
   * --------------------------------------------------------------------- */
  Future<bool> updateUserProfile(Map<String, dynamic> payload) async {
    if (_token == null || _token!.isEmpty) return false;
    loading.value = true;
    error.value = null;
    try {
      final res = await dio.put(
        '${ApiConstant.apiBase}/user-auth/profile',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );
      if (res.data is Map && res.data['user'] != null) {
        final u = Map<String, dynamic>.from(res.data['user'] as Map);
        userProfileData.value = u;
        final fn = (u['firstName'] ?? '').toString();
        final ln = (u['lastName'] ?? '').toString();
        _name = '$fn $ln'.trim();
        _email = (u['email'] ?? '').toString();

        final sp = await SharedPreferences.getInstance();
        if (_name.isNotEmpty) await sp.setString(_Keys.name, _name);
        if (_email.isNotEmpty) await sp.setString(_Keys.email, _email);
        return true;
      }
      return false;
    } on DioException catch (e) {
      error.value = _prettyError(e) ?? 'Could not update profile';
      return false;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      loading.value = false;
    }
  }

  /* ------------------------------------------------------------------------
   * UPLOAD PROFILE PHOTO
   * --------------------------------------------------------------------- */
  Future<bool> uploadProfilePhoto(String filePath) async {
    if (_token == null || _token!.isEmpty) {
      error.value = 'User not logged in';
      return false;
    }
    loading.value = true;
    error.value = null;
    try {
      final fileName = filePath.split('/').last.split('\\').last;
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });
      final res = await dio.post(
        '${ApiConstant.apiBase}/user-auth/profile/photo',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
          contentType: 'multipart/form-data',
        ),
      );
      if (res.data is Map && res.data['user'] != null) {
        final u = Map<String, dynamic>.from(res.data['user'] as Map);
        userProfileData.value = u;

        final sp = await SharedPreferences.getInstance();
        await sp.setString('cached_user_profile', json.encode(u));
        return true;
      }
      return false;
    } on DioException catch (e) {
      error.value = _prettyError(e) ?? 'Failed to upload photo';
      return false;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      loading.value = false;
    }
  }

  Future<bool> pickAndUploadProfilePhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (picked != null) {
        return await uploadProfilePhoto(picked.path);
      }
    } catch (e) {
      error.value = 'Failed to pick image: $e';
    }
    return false;
  }

  /* ------------------------------------------------------------------------
   * SEND OTP (Phone Number Login — Step 1)
   * --------------------------------------------------------------------- */
  Future<void> sendOtp(String phone) async {
    loading.value = true;
    error.value = null;
    try {
      await dio.post('${ApiConstant.apiBase}/user-auth/send-otp', data: {'phone': phone});
    } on DioException catch (e) {
      error.value = _prettyError(e) ?? 'Failed to send OTP';
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  /* ------------------------------------------------------------------------
   * VERIFY OTP (Phone Number Login — Step 2)
   * --------------------------------------------------------------------- */
  Future<void> verifyOtp(String phone, String otp) async {
    loading.value = true;
    error.value = null;
    try {
      final res = await dio.post('${ApiConstant.apiBase}/user-auth/verify-otp', data: {
        'phone': phone,
        'otp': otp,
      });
      final data = res.data is Map ? res.data as Map : {};
      final token = data['token']?.toString();
      final user = data['user'];
      if (token != null && token.isNotEmpty) {
        _token = token;
        if (user is Map) {
          userProfileData.value = Map<String, dynamic>.from(user);
          final fn = (user['firstName'] ?? '').toString();
          final ln = (user['lastName'] ?? '').toString();
          _name = '$fn $ln'.trim();
          if (_name.isEmpty) _name = (user['name'] ?? '').toString();
          _email = (user['email'] ?? '').toString();
        }
        final sp = await SharedPreferences.getInstance();
        await sp.setString(_Keys.token, token);
        await SharedPrefService.setToken(token);
        await sp.setString(_Keys.name, _name);
        await sp.setString(_Keys.email, _email);
        loggedIn.value = true;
        FcmService.refreshTokenAfterLogin();
        fetchUserProfile();
      } else {
        error.value = 'OTP verification failed. Please try again.';
      }
    } on DioException catch (e) {
      error.value = _prettyError(e) ?? 'Invalid OTP';
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }


  Future<void> login(String user, String pass, {bool staySignedIn = false}) async {
    loading.value = true;
    error.value = null;
    final sp = await SharedPreferences.getInstance();
 
  await sp.setBool(_Keys.staySignedIn, staySignedIn); // still save it
    try {
      final res = await dio.post(_Endpoints.token(), data: {
        'username': user,
        'password': pass,
      });

      // Expected: { token, user_display_name, user_email }
      final data = res.data is Map
          ? res.data as Map
          : json.decode(res.data as String) as Map;

      _token = data['token']?.toString();
      _name  = (data['user_display_name'] ?? '').toString();
      _email = (data['user_email'] ?? '').toString();

      if (_token == null || _token!.isEmpty) {
        throw 'Invalid token response';
      }

      final sp = await SharedPreferences.getInstance();
      await sp.setString(_Keys.token, _token!);
      await sp.setString(_Keys.name,  _name);
      await sp.setString(_Keys.email, _email);
      await sp.setBool(_Keys.staySignedIn, staySignedIn);

      // Optional enrichment via /users/me (depends on your JWT config)
      try {
        final me = await dio.get(
          _Endpoints.me(),
          options: Options(headers: {'Authorization': 'Bearer $_token'}),
        );
        if (me.data is Map) {
          final m = me.data as Map;
          _name  = (m['name'] ?? _name).toString();
          _email = (m['email'] ?? _email).toString();
          await sp.setString(_Keys.name, _name);
          await sp.setString(_Keys.email, _email);
        }
      } catch (_) {}

      loggedIn.value = true;
    } on DioException catch (e) {
      error.value = _prettyError(e) ?? 'Login failed';
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  /* ------------------------------------------------------------------------
   * SIGN UP (IN-APP, via WooCommerce v3 + CK/CS) — NO REDIRECT, NO USER PASSWORD
   * 1) Generate temp password
   * 2) Create WC customer
   * 3) Auto-login with JWT
   * 4) (Optional) send reset link email so user can set their own password
   * --------------------------------------------------------------------- */
  String _randomPassword([int length = 16]) {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%^*()-_=+';
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<void> registerWithKeys({
    required String first,
    required String last,
    required String email,
    bool sendSetPasswordEmail = true,
  }) async {
    loading.value = true;
    error.value = null;
    try {
      final cleanEmail = email.trim();

      // Optional preflight: if already exists, send reset link & return
      try {
        final chk = await _wcGet(dio, '/customers', {'email': cleanEmail});
        if (chk.statusCode == 200 && chk.data is List && (chk.data as List).isNotEmpty) {
          if (sendSetPasswordEmail) {
            await resetPasswordWithKeys(cleanEmail);
            error.value =
                'An account with this email already exists. We’ve sent a reset link to set your password.';
          } else {
            error.value =
                'An account with this email already exists. Please log in or reset your password.';
          }
          return;
        }
      } catch (_) {
        // Non-fatal; proceed to create
      }

      final tempPwd = _randomPassword(18);

      await _wcPost(dio, '/customers', {
        'email': cleanEmail,
        'username': '${first.trim().toLowerCase()}_${last.trim().toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}', // simplest
        'password': tempPwd,    // so we can auto-login immediately
        'first_name': first.trim(),
        'last_name' : last.trim(),
      });

      // Auto-login with JWT
      await login(cleanEmail, tempPwd, staySignedIn: true);

      // Email reset link (best-effort)
      if (sendSetPasswordEmail) {
        try { await resetPasswordWithKeys(cleanEmail); } catch (_) {}
      }
    } on DioException catch (e) {
      final msg = _prettyWooError(e) ?? 'Sign up failed';
      if (msg.toLowerCase().contains('already') && msg.toLowerCase().contains('registered')) {
        try {
          await resetPasswordWithKeys(email.trim());
          error.value =
              'This email is already registered. We’ve sent a reset link to set your password.';
        } catch (_) {
          error.value = 'This email is already registered. Please reset your password.';
        }
      } else {
         print(e.toString());
        error.value = msg;
      }
    } catch (e) {
      print(e.toString());
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  /// Let the currently logged-in user set a new password fully in-app (CK/CS).
  Future<void> changeMyPasswordWithKeys(String newPassword) async {
    if (_email.isEmpty) {
      error.value = 'Not logged in';
      return;
    }
    loading.value = true;
    error.value = null;
    try {
      // Find Woo customer id by email
      final res = await _wcGet(dio, '/customers', {'email': _email});
      final list = (res.data is List) ? (res.data as List) : const [];
      if (list.isEmpty) {
        error.value = 'Account not found for $_email';
        return;
      }
      final id = (list.first as Map)['id'];

      // Update password
      await _wcPut(dio, '/customers/$id', {'password': newPassword});
    } on DioException catch (e) {
      error.value = _prettyWooError(e) ?? 'Could not update password';
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  /* ------------------------------------------------------------------------
   * RESET PASSWORD (IN-APP, headless) — sends email, no webview
   * Tries WP JSON endpoint first; if absent, posts wp-login form and
   * detects success by redirect or HTML message.
   * --------------------------------------------------------------------- */
  Future<void> resetPasswordWithKeys(String userOrEmail) async {
    loading.value = true;
    error.value = null;
    try {
      // Try REST endpoint if available
      try {
        await dio.post(
          _Endpoints.lostPassword(),
          data: {'user_login': userOrEmail},
        );
        return; // success – mail sent
      } on DioException catch (e) {
        if ((e.response?.statusCode ?? 0) != 404) rethrow; // other errors bubble
      }

      // Fallback: headless wp-login form post (no webview)
      final resp = await dio.post(
        '$_kBaseUrl/wp-login.php?action=lostpassword',
        data: {
          'user_login': userOrEmail,
          'redirect_to': '$_kBaseUrl/my-account',
          'wp-submit': 'Get New Password',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (s) => s != null && s < 500, // inspect 3xx/4xx bodies
        ),
      );

      final sc = resp.statusCode ?? 0;
      final headers = resp.headers.map;
      final loc = (headers['location'] ?? headers['Location'])?.first ?? '';
      final body = resp.data?.toString() ?? '';

      // Success by redirect
      if (sc >= 300 && sc < 400) {
        if (loc.isEmpty || loc.contains('checkemail=confirm')) return;
        // Some hosts rewrite Location; treat any 3xx as success
        return;
      }
      // Success by HTML message
      if (_htmlContainsCheckEmail(body) || _htmlHasSuccessMessage(body)) {
        return;
      }

      // Surface HTML error text if present
      final errMsg = _extractWpLoginError(body);
      if (errMsg != null && errMsg.isNotEmpty) {
        throw errMsg;
      }

      // Generic failure
      throw 'Could not request password reset. Please try again.';
    } on DioException catch (e) {
      error.value = _prettyWooError(e) ?? 'Failed to request password reset';
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  // ---------- HTML helpers ----------
  bool _htmlContainsCheckEmail(String html) =>
      html.toLowerCase().contains('checkemail=confirm');

  bool _htmlHasSuccessMessage(String html) {
    // Match either <div class="message">…</div> or <p class="message">…</p>
    final m = RegExp(r'<(div|p)[^>]*class="[^"]*message[^"]*"[^>]*>(.*?)</\1>',
            caseSensitive: false, dotAll: true)
        .firstMatch(html)
        ?.group(2);
    if (m == null) return false;
    final txt = _stripHtml(m).toLowerCase();
    return txt.contains('check your email') ||
        txt.contains('email has been sent') ||
        txt.contains('password reset') ||
        txt.contains('reset link');
  }

  String? _extractWpLoginError(String html) {
    final err = RegExp(r'<div id="login_error"[^>]*>(.*?)</div>',
            caseSensitive: false, dotAll: true)
        .firstMatch(html)
        ?.group(1);
    return err == null ? null : _stripHtml(err);
  }

  String _stripHtml(String s) => s
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .trim();

  /* ------------------------------------------------------------------------
   * Optional legacy JSON flows (if you enable those endpoints later)
   * --------------------------------------------------------------------- */
  Future<void> register({
    required String first,
    required String last,
    required String email,
    required bool agree,
  }) async {
    loading.value = true;
    error.value = null;
    try {
      final res = await dio.post(_Endpoints.register(), data: {
        'first_name': first,
        'last_name' : last,
        'email'     : email,
        'username'  : email,
      });
      if (res.statusCode == 200 || res.statusCode == 201) return;
      throw 'Unexpected register response (${res.statusCode})';
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        error.value =
            'Registration API not enabled. Use registerWithKeys() or enable /wp-json/wp/v3/users/register.';
      } else {
        error.value = _prettyError(e) ?? 'Sign up failed';
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> requestPasswordReset(String userOrEmail) async {
    loading.value = true;
    error.value = null;
    try {
      await dio.post(_Endpoints.lostPassword(), data: {'user_login': userOrEmail});
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        error.value =
            'Password reset API not enabled. Use resetPasswordWithKeys() or enable /wp-json/wp/v2/users/lostpassword.';
      } else {
        error.value = _prettyError(e) ?? 'Failed to send reset link';
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  /* ------------------------------- Addresses ------------------------------ */
  Future<void> updateAddress({
    required bool isBilling,
    required Map<String, dynamic> map,
    required Map<String, dynamic> billing,
  }) async {
    final sp = await SharedPreferences.getInstance();
    if (isBilling) {
      _billing = Map<String, dynamic>.from(map);
      await sp.setString(_Keys.billing, json.encode(_billing));
    } else {
      _shipping = Map<String, dynamic>.from(map);
      await sp.setString(_Keys.shipping, json.encode(_shipping));
    }
    update();
  }

  /* -------------------------------- Logout -------------------------------- */
  Future<void> logout() async {
    await FcmService.removeTokenOnLogout();
    _token = null;
    loggedIn.value = false;
    userProfileData.clear();
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_Keys.token);
    await sp.remove(_Keys.name);
    await sp.remove(_Keys.email);
    await sp.remove('cached_user_profile');
    await SharedPrefService.removeToken();
  }

  /* ------------------------------ Persistence ----------------------------- */
  Future<void> _restore() async {
    final sp = await SharedPreferences.getInstance();
    _token = sp.getString(_Keys.token);
    _name  = sp.getString(_Keys.name)  ?? '';
    _email = sp.getString(_Keys.email) ?? '';
    final b = sp.getString(_Keys.billing);
    final s = sp.getString(_Keys.shipping);
    final cachedProfile = sp.getString('cached_user_profile');

    if (cachedProfile != null && cachedProfile.isNotEmpty) {
      try {
        userProfileData.value = Map<String, dynamic>.from(json.decode(cachedProfile) as Map);
      } catch (_) {}
    }

    if (b != null) _billing  = json.decode(b) as Map<String, dynamic>;
    if (s != null) _shipping = json.decode(s) as Map<String, dynamic>;

    loggedIn.value = _token != null && _token!.isNotEmpty;
    if (loggedIn.value) {
      fetchUserProfile();
      FcmService.refreshTokenAfterLogin();
    }
  }
  /* --------------------------------- Utils -------------------------------- */

  /// Generic error pretty-printer (strips simple HTML returned by WP)
  String? _prettyError(DioException e) {
    final status = e.response?.statusCode;
    final data   = e.response?.data;
    String stripHtml(String s) => s.replaceAll(RegExp(r'<[^>]+>'), '').trim();

    if (data is Map) {
      final msg  = data['message']?.toString();
      if (msg != null && msg.isNotEmpty) return stripHtml(msg);
      final code = data['code']?.toString();
      if (code != null) return 'Error $code (${status ?? ''})'.trim();
    } else if (data is String && data.isNotEmpty) {
      return stripHtml(data);
    }
    if (status != null) return 'HTTP $status';
    return e.message;
  }

  /// WooCommerce-focused error pretty-printer
  String? _prettyWooError(DioException e) => _prettyError(e);
}
