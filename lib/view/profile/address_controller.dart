// lib/view/profile/address_controller.dart
import 'package:tobeque/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:tobeque/view/profile/profile_controller.dart';
import 'package:tobeque/data/network/network_api_sarvices.dart';

class AddressController extends GetxController {
  late final AuthController auth;
  late final NetworkApi net;
  final saving = false.obs;
  final hydrating = true.obs;

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

    _hydrateFromAuth();
    _hydrateFromServer();
  }

  void _hydrateFromAuth() {
    final b = auth.billing;
    final s = auth.shipping;

    void fill(Map m, TextEditingController c, String k) =>
        c.text = (m[k]?.toString() ?? '');

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

  Future<void> _hydrateFromServer() async {
    hydrating(true);
    try {
      final data = await net.getApi(ApiConstant.userProfile) as Map;
      final user = (data['user'] as Map?)?.cast<String, dynamic>() ?? data.cast<String, dynamic>();

      bFirst.text = user['firstName'] ?? '';
      bLast.text = user['lastName'] ?? '';
      bPhone.text = user['phone'] ?? '';
      bEmail.text = user['email'] ?? '';
      bAddr1.text = user['address'] ?? '';
      bCity.text = user['city'] ?? '';
      bState.text = user['state'] ?? '';
      bPost.text = user['zipCode'] ?? '';

      sFirst.text = user['firstName'] ?? '';
      sLast.text = user['lastName'] ?? '';
      sAddr1.text = user['shippingAddress'] ?? user['address'] ?? '';
      sCity.text = user['shippingCity'] ?? user['city'] ?? '';
      sState.text = user['shippingState'] ?? user['state'] ?? '';
      sPost.text = user['shippingZipCode'] ?? user['zipCode'] ?? '';
    } catch (_) {
    } finally {
      hydrating(false);
    }
  }

  Future<void> saveBilling() async {
    await _saveToServer(isBilling: true);
  }

  Future<void> saveShipping() async {
    await _saveToServer(isBilling: false);
  }

  Future<void> _saveToServer({required bool isBilling}) async {
    saving(true);
    try {
      final payload = {
        'firstName': isBilling ? bFirst.text.trim() : sFirst.text.trim(),
        'lastName': isBilling ? bLast.text.trim() : sLast.text.trim(),
        'phone': isBilling ? bPhone.text.trim() : sPhone.text.trim(),
        'email': bEmail.text.trim(),
        if (isBilling) ...{
          'address': bAddr1.text.trim(),
          'city': bCity.text.trim(),
          'state': bState.text.trim(),
          'zipCode': bPost.text.trim(),
        } else ...{
          'shippingAddress': sAddr1.text.trim(),
          'shippingCity': sCity.text.trim(),
          'shippingState': sState.text.trim(),
          'shippingZipCode': sPost.text.trim(),
        }
      };

      await net.putApi(payload, ApiConstant.userProfile);
      await auth.fetchUserProfile();

      Get.snackbar('Saved', isBilling ? 'Billing address updated' : 'Shipping address updated',
          snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
    } catch (e) {
      Get.snackbar('Failed', 'Could not update address: $e',
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

