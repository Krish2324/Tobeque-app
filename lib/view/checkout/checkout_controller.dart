// lib/view/checkout/checkout_controller.dart
import 'dart:async';
import 'dart:math';
import 'package:tobeque/view/checkout/checkout_sucess_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:tobeque/data/network/network_api_sarvices.dart';
import 'package:tobeque/view/profile/profile_controller.dart'; // for local cached addresses (optional)

class CheckoutController extends GetxController {
  final api = NetworkApi();
// currency meta (filled from cart->totals)
int currencyMinorUnit = 2;
String currencySymbol = '';
String decimalSep = '.';
String thousandSep = ',';

  // ----- state -----
  final loading = true.obs;
  final mutating = false.obs;
  final error = RxnString();

  final items = <Map<String, dynamic>>[].obs;
  final totals = <String, dynamic>{}.obs;
  final appliedCoupons = <String>[].obs;

  // user (login or guest)
  final me = Rxn<Map<String, dynamic>>();

  // ----- saved addresses (from Cart Store API or Auth cache) -----
  final savedBilling  = <String, dynamic>{}.obs;
  final savedShipping = <String, dynamic>{}.obs;

  /// -1 none, 0 = Billing, 1 = Shipping (for radio selection)
  final selectedSaved = RxnInt();

  // ----- billing form -----
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

  // shipping = billing toggle
  final shipToDifferent = false.obs;

  // shipping section
  final shippingRates = <Map<String, dynamic>>[].obs; // {package_id, rate_id, name, description, price}
  final selectedShippingKey = RxnString(); // "$packageId|$rateId"

  // payment section
  final paymentMethods = <Map<String, dynamic>>[].obs; // {id,title,description}
  final selectedPaymentId = ''.obs;

  // coupon + note
  final couponCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  // helpers
 String formatPrice(dynamic value) {
  if (value == null) return '';

  // If API already sent a pretty string like "₹4,500.00"
  final s = value.toString();
  if (s.contains(currencySymbol) || s.contains(decimalSep)) {
    // looks already formatted
    return s;
  }

  // Map format: { value: 450000, amount: "₹4,500.00" }
  if (value is Map) {
    final amt = value['amount']?.toString();
    if (amt != null && amt.isNotEmpty) return amt;
    final v = value['value'];
    if (v is num) return _formatMinor(v);
    final vs = v?.toString();
    if (vs != null) {
      final n = num.tryParse(vs);
      if (n != null) return _formatMinor(n);
    }
    return s;
  }

  // Raw number or numeric string
  final n = num.tryParse(s);
  if (n == null) return s;

  // Heuristic: integers from Store API totals are in minor units.
  // If there is no decimal point, treat as minor-units.
  final bool looksMinor = !s.contains('.');
  return looksMinor ? _formatMinor(n) : _formatMajor(n);
}

String _formatMinor(num minor) {
  final major = minor / (pow(10, currencyMinorUnit));
  return _formatWithSymbol(major);
}

String _formatMajor(num major) {
  return _formatWithSymbol(major);
}

String _formatWithSymbol(num major) {
  // simple formatting without bringing in intl:
  final fixed = major.toStringAsFixed(currencyMinorUnit);
  // add thousands separators
  final parts = fixed.split('.');
  String intPart = parts[0];
  String fracPart = parts.length > 1 ? parts[1] : '';
  final buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    final fromRight = intPart.length - i;
    buf.write(intPart[i]);
    if (fromRight > 1 && fromRight % 3 == 1) buf.write(thousandSep);
  }
  final withSep = buf.toString();
  final dec = currencyMinorUnit > 0 ? '$decimalSep$fracPart' : '';
  return '$currencySymbol$withSep$dec';
}


  // (optional) access cached addresses if you hydrated them in AuthController earlier
  AuthController? get _authOrNull =>
      Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    loading(true);
    error.value = null;
    try {
      await _fetchCart();                 // picks saved addresses from cart
      await _whoAmI();
      await _loadPaymentMethods();
      await _updateCustomerAndLoadRates(); // needs country for quote
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading(false);
    }
  }

  Future<void> refreshAll() async {
    await _bootstrap();
  }

  /* --------------------------- Load cart + addresses --------------------------- */
  Future<void> _fetchCart() async {
    final data = await api.getApi('cart') as Map<String, dynamic>;

    final li = (data['items'] as List?) ?? const [];
    items.value = li.map((e) => (e as Map).cast<String, dynamic>()).toList();

    final tt = (data['totals'] as Map?)?.cast<String, dynamic>() ?? {};
    totals.assignAll(tt);
currencyMinorUnit = (tt['currency_minor_unit'] as num?)?.toInt() ?? 2;
currencySymbol    = (tt['currency_symbol'] ?? '').toString();
decimalSep        = (tt['currency_decimal_separator'] ?? '.').toString();
thousandSep       = (tt['currency_thousand_separator'] ?? ',').toString();

    // coupons (if any)
    final coupons = (data['coupons'] as List?) ?? const [];
    appliedCoupons.value = coupons
        .whereType<Map>()
        .map((m) => (m['code'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toList();

    // ---- pull saved addresses from cart payload (Blocks Store API) ----
    Map<String, dynamic> _addrFromCart(String key) {
      final top = (data[key] as Map?)?.cast<String, dynamic>();
      if (top != null) return top;
      final cust = (data['customer'] as Map?)?.cast<String, dynamic>();
      final under = (cust?[key] as Map?)?.cast<String, dynamic>();
      return under ?? <String, dynamic>{};
    }

    final bill = _addrFromCart('billing_address');
    final ship = _addrFromCart('shipping_address');

    // If cart didn’t have them yet, try cached from AuthController (optional)
    if (bill.isEmpty && _authOrNull?.billing.isNotEmpty == true) {
      savedBilling.assignAll(_authOrNull!.billing);
    } else {
      savedBilling.assignAll(bill);
    }

    if (ship.isEmpty && _authOrNull?.shipping.isNotEmpty == true) {
      savedShipping.assignAll(_authOrNull!.shipping);
    } else {
      savedShipping.assignAll(ship);
    }

    // If form is empty, prefill from billing (best effort)
    if ((firstName.text + lastName.text + address1.text).trim().isEmpty &&
        savedBilling.isNotEmpty) {
      _fillFormFrom(savedBilling);
    }
  }

  /* ------------------------------ Identity ------------------------------ */
  Future<void> _whoAmI() async {
    try {
      final res = await api.getApi('https://tobeque.com/wp-json/wp/v2/users/me');
      me.value = (res as Map).cast<String, dynamic>();
      // prefill email / name if present
      final fn = (res['first_name'] ?? '').toString();
      final ln = (res['last_name'] ?? '').toString();
      final em = (res['email'] ?? '').toString();
      if (fn.isNotEmpty) firstName.text = fn;
      if (ln.isNotEmpty) lastName.text = ln;
      if (em.isNotEmpty) email.text = em;
    } on DioException catch (e) {
      if ((e.response?.statusCode ?? 0) != 401) rethrow; // not guest
      me.value = null;
    }
  }

  /* --------------------------- Payment from CART --------------------------- */
  Future<void> _loadPaymentMethods() async {
    final cart = await api.getApi('cart') as Map;
    final ids = ((cart['payment_methods'] as List?) ?? const [])
        .whereType<String>()
        .toList();

    String titleFor(String id) {
      switch (id) {
        case 'cod': return 'Cash on delivery';
        case 'bacs': return 'Direct bank transfer';
        case 'cheque': return 'Check payments';
        case 'razorpay': return 'Razorpay';
        case 'stripe': return 'Card (Stripe)';
        default: return id;
      }
    }

    paymentMethods.value = ids.map((id) => {
      'id': id,
      'title': titleFor(id),
      'description': '',
    }).toList();

    selectedPaymentId.value =
        ids.contains('cod') ? 'cod' : (ids.isNotEmpty ? ids.first : '');
  }

  /* -------------------------- Build + push address -------------------------- */
  Map<String, dynamic> _buildAddress() => {
        'first_name': firstName.text.trim(),
        'last_name': lastName.text.trim(),
        'company': company.text.trim(),
        'country': (country.text.trim().isEmpty ? 'IN' : country.text.trim()),
        'address_1': address1.text.trim(),
        'address_2': address2.text.trim(),
        'city': city.text.trim(),
        'state': state.text.trim(),
        'postcode': postcode.text.trim(),
        'phone': phone.text.trim(),
        'email': email.text.trim(),
      };

  Future<void> _updateCustomerAndLoadRates() async {
    mutating(true);
    try {
      final addr = _buildAddress();

      // Persist into current cart customer
      await api.postApi({
        'billing_address': addr,
        'shipping_address': shipToDifferent.value ? addr : addr,
        'shipping_same_as_billing': !shipToDifferent.value,
      }, 'cart/update-customer');

      // Fresh cart → rates are included nowadays
      final cart = await api.getApi('cart') as Map<String, dynamic>;

      shippingRates.clear();
      final pkgs = (cart['shipping_rates'] as List?) ?? const [];
      for (final p in pkgs.whereType<Map>()) {
        final pkgId = (p['package_id'] as num?)?.toInt() ?? 0;
        final rates = (p['rates'] as List?) ?? const [];
        for (final r in rates.whereType<Map>()) {
          shippingRates.add({
            'package_id': pkgId,
            'rate_id': r['rate_id']?.toString() ?? '',
            'name': r['name']?.toString() ?? '',
            'description': r['description']?.toString() ?? '',
            'price': r['price_html']?.toString() ?? r['price']?.toString() ?? '',
          });
        }
      }

      if (shippingRates.isNotEmpty) {
        final free = shippingRates.firstWhereOrNull(
            (e) => (e['rate_id'] as String).startsWith('free_shipping'));
        final chosen = free ?? shippingRates.first;
        final key = '${chosen['package_id']}|${chosen['rate_id']}';
        selectedShippingKey.value = key;
        await selectShipping(key);
      }

      await _fetchCart(); // refresh totals & saved addresses snapshot
    } finally {
      mutating(false);
    }
  }

  Future<void> selectShipping(String key) async {
    final parts = key.split('|');
    if (parts.length != 2) return;
    mutating(true);
    try {
      await api.postApi({
        'package_id': int.tryParse(parts[0]) ?? 0,
        'rate_id': parts[1],
      }, 'cart/select-shipping-rate');
      await _fetchCart();
    } finally {
      mutating(false);
    }
  }

  /* ------------------------- Use a saved address (UI) ------------------------ */
  void useSaved(bool isBilling) {
    final addr = isBilling ? savedBilling : savedShipping;
    if (addr.isEmpty) return;
    _fillFormFrom(addr);
    // After applying, re-quote shipping etc.
    _updateCustomerAndLoadRates();
    selectedSaved.value = isBilling ? 0 : 1;
  }

  void _fillFormFrom(Map<String, dynamic> a) {
    String _s(String k) => (a[k]?.toString() ?? '');
    firstName.text = _s('first_name');
    lastName.text  = _s('last_name');
    company.text   = _s('company');
    country.text   = _s('country').isEmpty ? (country.text.isEmpty ? 'IN' : country.text) : _s('country');
    address1.text  = _s('address_1');
    address2.text  = _s('address_2');
    city.text      = _s('city');
    state.text     = _s('state');
    postcode.text  = _s('postcode');
    phone.text     = _s('phone');
    email.text     = _s('email').isEmpty ? email.text : _s('email');
  }

  String addressPretty(Map<String, dynamic> a) {
    final parts = <String>[
      [a['first_name'], a['last_name']].whereType<String>().where((s)=>s.trim().isNotEmpty).join(' ').trim(),
      [a['address_1'], a['address_2']].whereType<String>().where((s)=>s.trim().isNotEmpty).join(', ').trim(),
      [a['city'], a['state'], a['postcode']].whereType<String>().where((s)=>s.trim().isNotEmpty).join(', ').trim(),
      (a['country'] ?? '').toString(),
      (a['phone'] ?? '').toString(),
    ].where((s) => s.isNotEmpty).toList();
    return parts.join('\n');
  }

  /* ------------------------------ Coupons etc. ------------------------------ */
  Future<void> applyCoupon() async {
  final code = couponCtrl.text.trim();
  if (code.isEmpty) return;
  mutating(true);
  try {
    await api.postApi({'code': code}, 'cart/apply-coupon');

    // update locally immediately
    if (!appliedCoupons.contains(code)) {
      appliedCoupons.add(code);
    }

    couponCtrl.clear();
    await _fetchCart(); // refresh totals & items
  } finally {
    mutating(false);
  }
}


Future<void> removeCoupon(String code) async {
  mutating(true);
  try {
    // Remove locally first for instant UI update
    appliedCoupons.remove(code);

    // Call API
    await api.delete(null, 'cart/remove-coupon?code=$code');

    // Only refetch cart if backend confirms removal
    await _fetchCart();
  } finally {
    mutating(false);
  }
}


  Future<void> placeOrder() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (selectedPaymentId.value.isEmpty) {
      selectedPaymentId.value = 'cod';
    }

    mutating(true);
    try {
      final addr = _buildAddress();
      final body = {
        'billing_address': addr,
        'shipping_address': shipToDifferent.value ? addr : addr,
        'customer_note': noteCtrl.text.trim(),
        'payment_method': selectedPaymentId.value,
        'payment_data': <String, dynamic>{},
        'extensions': <String, dynamic>{},
        'terms': true,
        'should_create_account': false,
      };

      final res = await api.postApi(body, 'checkout');
      final orderId  = (res is Map) ? res['order_id']?.toString() : null;
      final redirect = (res is Map) ? res['redirect_url']?.toString() : null;

      await _fetchCart(); // cart will be cleared
      Get.to(() => CheckoutSuccessScreen(orderId: orderId, redirectUrl: redirect));
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? 'Something went wrong';
      Get.snackbar('Checkout failed', msg,
          snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
    } finally {
      mutating(false);
    }
  }

  // ---- helpers for UI ----
  String lineImage(Map<String, dynamic> item) {
    final images = (item['images'] as List?) ?? const [];
    if (images.isNotEmpty) {
      final url = (images.first as Map)['src']?.toString() ?? '';
      return url;
    }
    return '';
  }

  String attrText(Map<String, dynamic> item) {
    final raw = (item['variation'] as List?) ?? (item['attributes'] as List?) ?? const [];
    final parts = <String>[];
    for (final v in raw.whereType<Map>()) {
      final m = v.cast<String, dynamic>();
      final n = (m['name'] ?? m['attribute'] ?? '')
          .toString()
          .replaceAll(RegExp(r'^pa_'), '')
          .replaceAll('_', ' ');
      final val = (m['value'] ?? '').toString();
      if (val.isNotEmpty) parts.add('${n.isEmpty ? '' : '${_titleCase(n)}: '}$val');
    }
    return parts.join('  •  ');
  }

  String _titleCase(String s) =>
      s.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');

  @override
  void onClose() {
    firstName.dispose(); lastName.dispose(); company.dispose(); country.dispose();
    address1.dispose(); address2.dispose(); city.dispose(); state.dispose();
    postcode.dispose(); phone.dispose(); email.dispose();
    couponCtrl.dispose(); noteCtrl.dispose();
    super.onClose();
  }
}



