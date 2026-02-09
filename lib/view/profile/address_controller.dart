// lib/view/profile/address_controller.dart
import 'dart:convert';
import 'package:tobeque/constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:tobeque/view/profile/profile_controller.dart'; // AuthController
import 'package:tobeque/data/network/network_api_sarvices.dart';
 // <-- put your ck/cs here

class AddressController extends GetxController {
  late final AuthController auth;
  late final NetworkApi net;
  late final Dio wc;                   // wc/v3 client (ck/cs)
  final saving = false.obs;
  final hydrating = true.obs;

  // tabs
  final tabIndex = 0.obs;

  // billing
  final bFirst = TextEditingController();
  final bLast  = TextEditingController();
  final bCompany = TextEditingController();
  final bCountry = TextEditingController(text: 'IN');
  final bAddr1 = TextEditingController();
  final bAddr2 = TextEditingController();
  final bCity  = TextEditingController();
  final bState = TextEditingController();
  final bPost  = TextEditingController();
  final bPhone = TextEditingController();
  final bEmail = TextEditingController();

  // shipping
  final sFirst = TextEditingController();
  final sLast  = TextEditingController();
  final sCompany = TextEditingController();
  final sCountry = TextEditingController(text: 'IN');
  final sAddr1 = TextEditingController();
  final sAddr2 = TextEditingController();
  final sCity  = TextEditingController();
  final sState = TextEditingController();
  final sPost  = TextEditingController();
  final sPhone = TextEditingController();
  final sEmail = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    auth = Get.find<AuthController>();
    net  = NetworkApi();

    // wc/v3 client with Basic auth (ck/cs)
    wc = Dio(BaseOptions(
      baseUrl: 'https://tobeque.com/wp-json/wc/v3/',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'Accept': 'application/json'},
    ));
    final basic = base64Encode(utf8.encode('${ApiConstant.consumerKey}:${ApiConstant.consumerSecret}'));
    wc.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      o.headers['Authorization'] = 'Basic $basic';
      h.next(o);
    }));

    // 1) show whatever we already have locally
    _hydrateFromAuth();

    // 2) then fetch from server and overwrite with truth
    _hydrateFromServer();
  }

  /* --------------------------- Hydration (local) --------------------------- */
  void _hydrateFromAuth() {
    final b = auth.billing;
    final s = auth.shipping;

    void fill(Map m, TextEditingController c, String k) =>
        c.text = (m[k]?.toString() ?? '');

    // billing
    fill(b, bFirst,  'first_name');
    fill(b, bLast,   'last_name');
    fill(b, bCompany,'company');
    fill(b, bCountry,'country');
    fill(b, bAddr1,  'address_1');
    fill(b, bAddr2,  'address_2');
    fill(b, bCity,   'city');
    fill(b, bState,  'state');
    fill(b, bPost,   'postcode');
    fill(b, bPhone,  'phone');
    fill(b, bEmail,  'email');

    // shipping
    fill(s, sFirst,  'first_name');
    fill(s, sLast,   'last_name');
    fill(s, sCompany,'company');
    fill(s, sCountry,'country');
    fill(s, sAddr1,  'address_1');
    fill(s, sAddr2,  'address_2');
    fill(s, sCity,   'city');
    fill(s, sState,  'state');
    fill(s, sPost,   'postcode');
    fill(s, sPhone,  'phone');
    fill(s, sEmail,  'email');

    if (bEmail.text.isEmpty) bEmail.text = auth.email;
  }

  /* ------------------------- Hydration (server truth) ---------------------- */
  Future<void> _hydrateFromServer() async {
    hydrating(true);
    try {
      // who am i (cookie/JWT)
      final me = await net.getApi('https://tobeque.com/wp-json/wp/v2/users/me') as Map;
      final uid = (me['id'] as num).toInt();
      final email = (me['email'] ?? '').toString();

      Map<String, dynamic>? customer;

      // try /customers/<id> first (WP user id == customer id)
      try {
        final res = await wc.get('customers/$uid');
        customer = (res.data as Map).cast<String, dynamic>();
      } on DioException catch (e) {
        if (e.response?.statusCode == 404 && email.isNotEmpty) {
          // fall back: search by email
          final res = await wc.get('customers', queryParameters: {'email': email});
          final list = (res.data as List?) ?? const [];
          if (list.isNotEmpty) {
            customer = (list.first as Map).cast<String, dynamic>();
          }
        } else {
          rethrow;
        }
      }

      if (customer == null) {
        hydrating(false);
        return; // no customer yet (new account) → keep whatever is local
      }

      final billing  = (customer['billing']  as Map?)?.cast<String, dynamic>() ?? {};
      final shipping = (customer['shipping'] as Map?)?.cast<String, dynamic>() ?? {};

      // fill controllers
      void fill(Map m, TextEditingController c, String k) =>
          c.text = (m[k]?.toString() ?? '');
      // billing
      fill(billing, bFirst, 'first_name');
      fill(billing, bLast, 'last_name');
      fill(billing, bCompany, 'company');
      fill(billing, bCountry, 'country');
      fill(billing, bAddr1, 'address_1');
      fill(billing, bAddr2, 'address_2');
      fill(billing, bCity, 'city');
      fill(billing, bState, 'state');
      fill(billing, bPost, 'postcode');
      fill(billing, bPhone, 'phone');
      fill(billing, bEmail, 'email');

      // shipping
      fill(shipping, sFirst, 'first_name');
      fill(shipping, sLast, 'last_name');
      fill(shipping, sCompany, 'company');
      fill(shipping, sCountry, 'country');
      fill(shipping, sAddr1, 'address_1');
      fill(shipping, sAddr2, 'address_2');
      fill(shipping, sCity, 'city');
      fill(shipping, sState, 'state');
      fill(shipping, sPost, 'postcode');
      fill(shipping, sPhone, 'phone');
      fill(shipping, sEmail, 'email');

      // also cache locally so Profile shows immediately next time
      await auth.updateAddress(isBilling: true,  map: billing,  billing: billing);
      await auth.updateAddress(isBilling: false, map: shipping, billing: shipping);

      update();
    } catch (_) {
      // ignore — UI stays with local values
    } finally {
      hydrating(false);
    }
  }

  /* ------------------------------- Builders ------------------------------- */
  Map<String, dynamic> _buildBilling() => {
    'first_name': bFirst.text.trim(),
    'last_name' : bLast.text.trim(),
    'company'   : bCompany.text.trim(),
    'country'   : (bCountry.text.trim().isEmpty ? 'IN' : bCountry.text.trim()),
    'address_1' : bAddr1.text.trim(),
    'address_2' : bAddr2.text.trim(),
    'city'      : bCity.text.trim(),
    'state'     : bState.text.trim(),
    'postcode'  : bPost.text.trim(),
    'phone'     : bPhone.text.trim(),
    'email'     : bEmail.text.trim(),
  };

  Map<String, dynamic> _buildShipping() => {
    'first_name': sFirst.text.trim(),
    'last_name' : sLast.text.trim(),
    'company'   : sCompany.text.trim(),
    'country'   : (sCountry.text.trim().isEmpty ? 'IN' : sCountry.text.trim()),
    'address_1' : sAddr1.text.trim(),
    'address_2' : sAddr2.text.trim(),
    'city'      : sCity.text.trim(),
    'state'     : sState.text.trim(),
    'postcode'  : sPost.text.trim(),
    'phone'     : sPhone.text.trim(),
    'email'     : sEmail.text.trim(),
  };

  /* ------------------------------- Actions -------------------------------- */
  Future<void> saveBilling() async {
    await _saveToServer(isBilling: true);
  }

  Future<void> saveShipping() async {
    await _saveToServer(isBilling: false);
  }

  Future<void> _saveToServer({required bool isBilling}) async {
    saving(true);
    try {
      // who am i
      final me = await net.getApi('https://tobeque.com/wp-json/wp/v2/users/me') as Map;
      final uid = (me['id'] as num).toInt();

      final body = <String, dynamic>{};
      final bill = _buildBilling();
      final ship = _buildShipping();

      // send both sections so the server stays consistent
      body['billing']  = bill;
      body['shipping'] = ship;

      await wc.put('customers/$uid', data: body);

      // cache locally for Profile
      await auth.updateAddress(isBilling: true,  map: bill,  billing: bill);
      await auth.updateAddress(isBilling: false, map: ship, billing: ship);

      Get.snackbar('Saved', isBilling ? 'Billing address updated' : 'Shipping address updated',
          snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
    } on DioException catch (e) {
      Get.snackbar('Failed', e.response?.data?.toString() ?? 'Could not update address',
          snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 3));
    } finally {
      saving(false);
    }
  }

  /// Push addresses into the active cart (Blocks Store API) for shipping quotes.
  Future<void> pushToCart() async {
    saving(true);
    try {
      final bill = _buildBilling();
      final ship = _buildShipping();

      await net.postApi({
        'billing_address' : bill,
        'shipping_address': ship,
        'shipping_same_as_billing': false,
      }, 'cart/update-customer');

      Get.snackbar('Updated', 'Cart shipping updated',
          snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
    } catch (e) {
      Get.snackbar('Failed', 'Could not update cart: $e',
          snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 3));
    } finally {
      saving(false);
    }
  }

  @override
  void onClose() {
    bFirst.dispose(); bLast.dispose(); bCompany.dispose(); bCountry.dispose();
    bAddr1.dispose(); bAddr2.dispose(); bCity.dispose(); bState.dispose();
    bPost.dispose(); bPhone.dispose(); bEmail.dispose();

    sFirst.dispose(); sLast.dispose(); sCompany.dispose(); sCountry.dispose();
    sAddr1.dispose(); sAddr2.dispose(); sCity.dispose(); sState.dispose();
    sPost.dispose(); sPhone.dispose(); sEmail.dispose();
    super.onClose();
  }
}
