import 'dart:async';
import 'package:intl/intl.dart';
import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/view/checkout/checkout_sucess_screen.dart';
import 'package:tobeque/view/profile/profile_screen.dart';
import 'package:tobeque/view/cart/cart_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tobeque/data/network/network_api_sarvices.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

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

  final fetchingPincode = false.obs;
  final pincodeStatusMsg = RxnString();
  final pincodeValid = RxnBool();

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
    if (postcode.text.trim().length == 6) {
      lookupPincode(postcode.text.trim());
    }
  }

  Future<void> lookupPincode(String code) async {
    final trimmed = code.trim();
    if (trimmed.length != 6 || int.tryParse(trimmed) == null) {
      pincodeValid.value = null;
      pincodeStatusMsg.value = null;
      return;
    }

    fetchingPincode.value = true;
    pincodeStatusMsg.value = 'Fetching location details…';
    pincodeValid.value = null;

    try {
      final response = await api.getApi('https://api.postalpincode.in/pincode/$trimmed');
      if (response is List && response.isNotEmpty) {
        final resObj = response.first;
        if (resObj is Map && resObj['Status'] == 'Success') {
          final poList = resObj['PostOffice'] as List?;
          if (poList != null && poList.isNotEmpty) {
            final po = poList.first as Map;
            final fetchedCity = (po['District'] ?? po['Block'] ?? po['Name'] ?? '').toString();
            final fetchedState = (po['State'] ?? '').toString();
            final fetchedCountry = (po['Country'] ?? 'India').toString();

            if (fetchedCity.isNotEmpty) city.text = fetchedCity;
            if (fetchedState.isNotEmpty) state.text = fetchedState;
            if (fetchedCountry.isNotEmpty) country.text = fetchedCountry;

            pincodeValid.value = true;
            pincodeStatusMsg.value = '$fetchedCity, $fetchedState ($fetchedCountry)';
            return;
          }
        }
      }
      pincodeValid.value = false;
      pincodeStatusMsg.value = 'Invalid or unserviceable pincode';
    } catch (_) {
      pincodeValid.value = false;
      pincodeStatusMsg.value = 'Pincode lookup error';
    } finally {
      fetchingPincode.value = false;
    }
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
      await _loadCartItems();
      await _whoAmI();
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading(false);
    }
  }

  Future<void> _loadCartItems() async {
    final cartService = Get.isRegistered<CartService>()
        ? Get.find<CartService>()
        : Get.put(CartService(), permanent: true);

    await cartService.restoreCart();

    final list = <Map<String, dynamic>>[];
    for (final i in cartService.items) {
      final priceNum = double.tryParse(i.price.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      final lineTotal = priceNum * i.quantity;
      list.add({
        'key': i.cartId,
        'id': i.productId,
        'productId': i.productId,
        'name': i.name,
        'price': i.price,
        'quantity': i.quantity,
        'image': i.image,
        'selectedSize': i.selectedSize,
        'selectedColor': i.selectedColor,
        'totals': {
          'line_total': lineTotal,
          'line_total_rendered': '₹${NumberFormat.decimalPattern('en_IN').format(lineTotal.round())}',
        }
      });
    }

    items.assignAll(list);
    _recalculateTotals();
  }

  void _recalculateTotals() {
    final cartService = Get.isRegistered<CartService>()
        ? Get.find<CartService>()
        : Get.put(CartService(), permanent: true);

    final subtotalVal = cartService.totalPrice;
    final finalTotal = (subtotalVal + shippingCost.value - discountAmount.value).clamp(0.0, double.infinity);

    totals.value = {
      'subtotal': subtotalVal,
      'total': finalTotal,
      'subtotal_price': subtotalVal,
      'total_price': finalTotal,
    };
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
      if (postcode.text.trim().length == 6) {
        lookupPincode(postcode.text.trim());
      }
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
        'country': country.text.trim().isNotEmpty ? country.text.trim() : 'India',
      };

  List<Map<String, dynamic>> _buildOrderItems() {
    final cartService = Get.isRegistered<CartService>()
        ? Get.find<CartService>()
        : Get.put(CartService(), permanent: true);

    final result = <Map<String, dynamic>>[];
    for (final item in cartService.items) {
      final rawPriceStr = item.price.toString().replaceAll(RegExp(r'[^0-9.]'), '');
      final double parsedPrice = double.tryParse(rawPriceStr) ?? 0.0;

      result.add({
        'productId': item.productId,
        'price': parsedPrice,
        'quantity': item.quantity,
        'variantDetails': {
          'size': item.selectedSize,
          'color': item.selectedColor,
        },
      });
    }
    return result;
  }

  Future<void> applyCoupon() async {
    final code = couponCtrl.text.trim();
    if (code.isEmpty) return;
    mutating(true);
    try {
      final cartService = Get.isRegistered<CartService>()
          ? Get.find<CartService>()
          : Get.put(CartService(), permanent: true);
      final subtotalVal = cartService.totalPrice;

      final res = await api.postApi({
        'code': code,
        'cartTotal': subtotalVal,
      }, ApiConstant.validateCoupon) as Map;

      if (res['coupon'] != null) {
        final couponData = res['coupon'] as Map;
        final String couponCodeStr = (couponData['code'] ?? code).toString();
        final String type = (couponData['type'] ?? 'fixed').toString();
        final num discValue = (couponData['discountValue'] as num?) ?? 0;

        double computedDiscount = 0.0;
        if (type == 'percentage') {
          computedDiscount = (subtotalVal * discValue.toDouble()) / 100.0;
        } else {
          computedDiscount = discValue.toDouble();
        }
        if (computedDiscount > subtotalVal) {
          computedDiscount = subtotalVal;
        }

        discountAmount.value = computedDiscount;
        appliedCoupons.assignAll([couponCodeStr]);
        _recalculateTotals();

        Get.snackbar('Coupon Applied', 'Coupon $couponCodeStr applied successfully!');
      }
    } catch (e) {
      Get.snackbar('Coupon Error', e.toString().replaceAll('Exception: ', ''));
    } finally {
      mutating(false);
    }
  }

  Future<void> removeCoupon(String code) async {
    appliedCoupons.remove(code);
    discountAmount.value = 0.0;
    _recalculateTotals();
    couponCtrl.clear();
  }

  // ── Razorpay ──────────────────────────────────────────────────────────────
  Razorpay? _razorpay;
  String?   _rzpOrderId;
  Map<String, dynamic>? _pendingRazorpayOrderPayload;

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR,   _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final verifyPayload = {
        ...?_pendingRazorpayOrderPayload,
        'razorpay_order_id': response.orderId ?? _rzpOrderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      };
      await _verifyAndFinalizeRazorpayOrder(verifyPayload);
    } catch (e) {
      mutating(false);
      Get.snackbar(
        'Payment Verification Failed',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      _razorpay?.clear();
    }
  }

  Future<void> _verifyAndFinalizeRazorpayOrder(Map<String, dynamic> verifyPayload) async {
    final res = await api.postApi(verifyPayload, ApiConstant.razorpayVerify);
    final orderId = (res is Map)
        ? (res['order']?['_id'] ?? res['order']?['id'] ?? res['orderId'])?.toString()
        : null;

    if (Get.isRegistered<CartService>()) {
      Get.find<CartService>().clear();
    }
    mutating(false);
    Get.off(() => CheckoutSuccessScreen(orderId: orderId, redirectUrl: null));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _razorpay?.clear();
    mutating(false);
    Get.snackbar(
      'Payment Failed',
      response.message ?? 'Payment was not completed. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFE53935),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _razorpay?.clear();
    mutating(false);
    Get.snackbar(
      'External Wallet',
      'Redirecting to ${response.walletName}…',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> placeOrder() async {
    // 1. Check login status
    if (me.value == null) {
      Get.snackbar(
        'Login Required',
        'Please log in to your account before placing an order.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1976D2),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      Get.to(() => const ProfileScreen());
      return;
    }

    // 2. Validate delivery form fields
    if (!(formKey.currentState?.validate() ?? false)) {
      Get.snackbar(
        'Incomplete Details',
        'Please fill in all required delivery fields (name, phone, email, pincode, address, city, state).',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    mutating(true);

    try {
      final addr = _buildAddress();
      final formattedItems = _buildOrderItems();

      if (formattedItems.isEmpty) {
        mutating(false);
        Get.snackbar('Empty Cart', 'Your shopping bag is empty.');
        return;
      }

      final appliedCouponCode = appliedCoupons.isNotEmpty ? appliedCoupons.first : null;

      // ── COD path ─────────────────────────────────────────────────────────
      if (selectedPaymentId.value == 'cod') {
        final body = {
          'customerName':    addr['name'],
          'customerPhone':   addr['phone'],
          'shippingAddress': addr,
          'billingAddress':  addr,
          'items':           formattedItems,
          'couponCode':      appliedCouponCode,
          'paymentMethod':   'cod',
          'notes':           noteCtrl.text.trim(),
          'shippingCost':    shippingCost.value,
        };

        final res     = await api.postApi(body, ApiConstant.placeOrder);
        final orderId = (res is Map) ? (res['order']?['_id'] ?? res['order']?['id'] ?? res['orderId'])?.toString() : null;
        if (Get.isRegistered<CartService>()) {
          Get.find<CartService>().clear();
        }
        mutating(false);
        Get.off(() => CheckoutSuccessScreen(orderId: orderId, redirectUrl: null));
        return;
      }

      // ── Razorpay path ────────────────────────────────────────────────────
      // 1. Fetch Razorpay key
      String rzpKey = '';
      try {
        final cfgRes = await api.getApi(ApiConstant.razorpayConfig) as Map;
        rzpKey = (cfgRes['key'] ?? cfgRes['razorpayKeyId'] ?? '').toString();
      } catch (_) {}

      // 2. Create Razorpay order on backend
      final rzpPayload = {
        'items':        formattedItems,
        'couponCode':   appliedCouponCode,
        'shippingCost': shippingCost.value,
      };

      final rzpOrderRes = await api.postApi(rzpPayload, ApiConstant.razorpayCreateOrder) as Map;

      _pendingRazorpayOrderPayload = {
        'customerName':    addr['name'],
        'customerPhone':   addr['phone'],
        'shippingAddress': addr,
        'billingAddress':  addr,
        'items':           formattedItems,
        'couponCode':      appliedCouponCode,
        'notes':           noteCtrl.text.trim(),
        'shippingCost':    shippingCost.value,
      };

      // Check if zero amount order (e.g. 100% coupon discount)
      if (rzpOrderRes['isZeroAmount'] == true) {
        await _verifyAndFinalizeRazorpayOrder({
          ...?_pendingRazorpayOrderPayload,
          'razorpay_payment_id': 'pay_zero_discount',
          'razorpay_order_id':   'order_zero_discount',
          'razorpay_signature':  'zero_discount',
        });
        return;
      }

      _rzpOrderId = (rzpOrderRes['orderId'] ?? rzpOrderRes['id'])?.toString();
      final int amountInPaise = ((rzpOrderRes['amount'] as num?) ?? (totals['total'] ?? 0) * 100).toInt();

      // 3. Open Razorpay SDK
      _initRazorpay();
      _razorpay!.open({
        'key':         rzpKey,
        'amount':      amountInPaise,
        'order_id':    _rzpOrderId,
        'currency':    'INR',
        'name':        'Tobeque',
        'description': 'Fashion Order',
        'prefill': {
          'contact': addr['phone'],
          'email':   email.text.trim(),
          'name':    addr['name'],
        },
        'theme': {'color': '#0D0D0D'},
      });
      // payment result arrives asynchronously via _handlePaymentSuccess
    } catch (e) {
      mutating(false);
      final cleanMsg = e.toString()
          .replaceAll('Exception: ', '')
          .replaceAll('InvalidInputException: ', '')
          .replaceAll('FatchDataException: ', '');
      Get.snackbar(
        'Order Failed',
        cleanMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  String formatPrice(dynamic value) {
    if (value == null) return '₹0';
    if (value is String && value.startsWith('₹')) return value;
    final numVal = double.tryParse(value.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    return '₹${NumberFormat.decimalPattern('en_IN').format(numVal.round())}';
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
    _razorpay?.clear();
    firstName.dispose(); lastName.dispose(); company.dispose(); country.dispose();
    address1.dispose(); address2.dispose(); city.dispose(); state.dispose();
    postcode.dispose(); phone.dispose(); email.dispose();
    couponCtrl.dispose(); noteCtrl.dispose();
    super.onClose();
  }
}




