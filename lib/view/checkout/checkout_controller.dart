// lib/view/checkout/checkout_controller.dart
import 'dart:async';
import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/view/checkout/checkout_sucess_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tobeque/data/network/network_api_sarvices.dart';

class CheckoutController extends GetxController {
  final api = NetworkApi();

  int currencyMinorUnit = 2;
  String currencySymbol = '₹';
  String decimalSep = '.';
  String thousandSep = ',';

  final loading = true.obs;
  final mutating = false.obs;
  final error = RxnString();

  final items = <Map<String, dynamic>>[].obs;
  final totals = <String, dynamic>{}.obs;
  final appliedCoupons = <String>[].obs;
  final discountAmount = 0.0.obs;

  final me = Rxn<Map<String, dynamic>>();

  final savedBilling  = <String, dynamic>{}.obs;
  final savedShipping = <String, dynamic>{}.obs;

  final selectedSaved = RxnInt();

  final formKey = GlobalKey<FormState>();
  final firstName = TextEditingController();
  final lastName  = TextEditingController();
  final company   = TextEditingController();
  final country   = TextEditingController(text: 'IN');
  final address1  = TextEditingController();
  final address2  = TextEditingController();
  final city      = TextEditingController();
  final state     = TextEditingController();
  final postcode  = TextEditingController();
  final phone     = TextEditingController();
  final email     = TextEditingController();

  final shipToDifferent = false.obs;

  final shippingRates = <Map<String, dynamic>>[].obs;
  final selectedShippingKey = RxnString();
  final shippingCost = 0.0.obs;

  final paymentMethods = <Map<String, dynamic>>[
    {'id': 'cod', 'title': 'Cash on Delivery', 'description': 'Pay with cash upon delivery'},
    {'id': 'razorpay', 'title': 'Online Payment (Razorpay)', 'description': 'UPI, Cards, Netbanking'},
  ].obs;
  final selectedPaymentId = 'cod'.obs;

  final couponCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  void useSaved(bool isBilling) {
    final addr = isBilling ? savedBilling : savedShipping;
    if (addr.isEmpty) return;
    firstName.text = (addr['first_name'] ?? addr['name'] ?? '').toString();
    address1.text = (addr['address_1'] ?? addr['street'] ?? '').toString();
    city.text = (addr['city'] ?? '').toString();
    state.text = (addr['state'] ?? '').toString();
    postcode.text = (addr['postcode'] ?? addr['zip'] ?? '').toString();
    phone.text = (addr['phone'] ?? '').toString();
    selectedSaved.value = isBilling ? 0 : 1;
  }

  String addressPretty(Map<String, dynamic> a) {
    final name = (a['first_name'] ?? a['name'] ?? '').toString();
    final street = (a['address_1'] ?? a['street'] ?? '').toString();
    final cityStr = (a['city'] ?? '').toString();
    final stateStr = (a['state'] ?? '').toString();
    final zipStr = (a['postcode'] ?? a['zip'] ?? '').toString();
    return [name, street, '$cityStr, $stateStr $zipStr'].where((s) => s.trim().isNotEmpty).join('\n');
  }

  Future<void> selectShipping(String key) async {
    selectedShippingKey.value = key;
  }

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    loading(true);
    error.value = null;
    try {
      await _whoAmI();
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading(false);
    }
  }

  Future<void> refreshAll() async {
    await _bootstrap();
  }

  Future<void> _whoAmI() async {
    try {
      final res = await api.getApi(ApiConstant.userProfile) as Map;
      final user = (res['user'] as Map?)?.cast<String, dynamic>() ?? res.cast<String, dynamic>();
      me.value = user;
      firstName.text = (user['firstName'] ?? '').toString();
      lastName.text = (user['lastName'] ?? '').toString();
      email.text = (user['email'] ?? '').toString();
      phone.text = (user['phone'] ?? '').toString();
      address1.text = (user['address'] ?? '').toString();
      city.text = (user['city'] ?? '').toString();
      state.text = (user['state'] ?? '').toString();
      postcode.text = (user['zipCode'] ?? '').toString();
    } catch (_) {
      me.value = null;
    }
  }

  Map<String, dynamic> _buildAddress() => {
        'name': '${firstName.text.trim()} ${lastName.text.trim()}'.trim(),
        'phone': phone.text.trim(),
        'street': address1.text.trim(),
        'city': city.text.trim(),
        'state': state.text.trim(),
        'zip': postcode.text.trim(),
        'country': 'India',
      };

  Future<void> applyCoupon() async {
    final code = couponCtrl.text.trim();
    if (code.isEmpty) return;
    mutating(true);
    try {
      final res = await api.postApi({'code': code}, ApiConstant.validateCoupon) as Map;
      if (res['coupon'] != null) {
        if (!appliedCoupons.contains(code)) {
          appliedCoupons.add(code);
        }
        Get.snackbar('Coupon Applied', 'Coupon $code applied successfully!');
      }
    } catch (e) {
      Get.snackbar('Coupon Error', e.toString());
    } finally {
      mutating(false);
    }
  }

  Future<void> removeCoupon(String code) async {
    appliedCoupons.remove(code);
    couponCtrl.clear();
  }

  Future<void> placeOrder() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    mutating(true);
    try {
      final addr = _buildAddress();
      final body = {
        'customerName': addr['name'],
        'customerPhone': addr['phone'],
        'shippingAddress': addr,
        'billingAddress': addr,
        'items': items,
        'couponCode': appliedCoupons.isNotEmpty ? appliedCoupons.first : null,
        'paymentMethod': selectedPaymentId.value,
        'notes': noteCtrl.text.trim(),
        'shippingCost': shippingCost.value,
      };

      final res = await api.postApi(body, ApiConstant.placeOrder);
      final orderId = (res is Map) ? (res['order']?['_id'] ?? res['order']?['id'] ?? res['orderId'])?.toString() : null;

      Get.off(() => CheckoutSuccessScreen(orderId: orderId, redirectUrl: null));
    } catch (e) {
      Get.snackbar('Checkout Failed', e.toString(),
          snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
    } finally {
      mutating(false);
    }
  }

  String formatPrice(dynamic value) {
    if (value == null) return '₹0';
    return '₹${value.toString()}';
  }

  String lineImage(Map<String, dynamic> item) {
    final url = item['image'] ?? item['featuredImage'];
    return ApiConstant.getImageUrl(url?.toString());
  }

  String attrText(Map<String, dynamic> item) {
    final size = item['selectedSize'] ?? item['size'];
    final color = item['selectedColor'] ?? item['color'];
    final parts = <String>[];
    if (size != null && size.toString().isNotEmpty) parts.add('Size: $size');
    if (color != null && color.toString().isNotEmpty) parts.add('Color: $color');
    return parts.join(' • ');
  }

  @override
  void onClose() {
    firstName.dispose(); lastName.dispose(); company.dispose(); country.dispose();
    address1.dispose(); address2.dispose(); city.dispose(); state.dispose();
    postcode.dispose(); phone.dispose(); email.dispose();
    couponCtrl.dispose(); noteCtrl.dispose();
    super.onClose();
  }
}




