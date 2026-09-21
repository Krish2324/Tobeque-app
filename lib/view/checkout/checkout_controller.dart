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
  final gstNumber = TextEditingController();
  final country   = TextEditingController(text: 'IN');
  final address1  = TextEditingController();
  final address2  = TextEditingController();
  final city      = TextEditingController();
  final state     = TextEditingController();
  final postcode  = TextEditingController();
  final phone     = TextEditingController();
  final email     = TextEditingController();

  final hasCompany = false.obs;

  final shipToDifferent = false.obs;

  final shippingRates = <Map<String, dynamic>>[].obs;
  final selectedShippingKey = RxnString();
  final shippingCost = 0.0.obs;

  final codFee = 0.0.obs; // COD extra charge fetched from admin settings

  final paymentMethods = <Map<String, dynamic>>[
    {'id': 'cod', 'title': 'Cash on Delivery', 'description': 'Pay with cash upon delivery'},
    {'id': 'razorpay', 'title': 'Online Payment (Razorpay)', 'description': 'UPI, Cards, Netbanking'},
  ].obs;
  final selectedPaymentId = 'cod'.obs;

  final couponCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  // Coupon state
  final couponLoading = false.obs;
  final couponError  = RxnString();
  final couponSuccess = RxnString();
  final isFreeShippingCoupon = false.obs;

  final fetchingPincode = false.obs;
  final pincodeStatusMsg = RxnString();
  final pincodeValid = RxnBool();
  final availableAreas = <Map<String, dynamic>>[].obs;
  final selectedArea = Rxn<Map<String, dynamic>>();

  void useSaved(bool isBilling) {
    final addr = isBilling ? savedBilling : savedShipping;
    if (addr.isEmpty) return;
    firstName.text = (addr['first_name'] ?? addr['name'] ?? '').toString();
    address1.text = (addr['address_1'] ?? addr['street'] ?? '').toString();
    city.text = (addr['city'] ?? '').toString();
    state.text = (addr['state'] ?? '').toString();
    postcode.text = (addr['postcode'] ?? addr['zip'] ?? '').toString();
    phone.text = (addr['phone'] ?? '').toString();
    company.text = (addr['company'] ?? '').toString();
    gstNumber.text = (addr['gstNumber'] ?? '').toString();
    selectedSaved.value = isBilling ? 0 : 1;
    if (postcode.text.trim().length == 6) {
      lookupPincode(postcode.text.trim(), autoOpenModal: false);
    }
  }

  Future<void> lookupPincode(String code, {bool autoOpenModal = true}) async {
    final trimmed = code.trim();
    if (trimmed.length != 6 || int.tryParse(trimmed) == null) {
      pincodeValid.value = null;
      pincodeStatusMsg.value = null;
      availableAreas.clear();
      selectedArea.value = null;
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
            final list = poList.map((e) => (e as Map).cast<String, dynamic>()).toList();
            availableAreas.assignAll(list);

            final po = list.first;
            selectedArea.value = po;
            final fetchedCity = (po['District'] ?? po['Block'] ?? po['Name'] ?? '').toString();
            final fetchedState = (po['State'] ?? '').toString();
            final fetchedCountry = (po['Country'] ?? 'India').toString();

            if (fetchedCity.isNotEmpty) city.text = fetchedCity;
            if (fetchedState.isNotEmpty) state.text = fetchedState;
            if (fetchedCountry.isNotEmpty) country.text = fetchedCountry;

            pincodeValid.value = true;
            final areaName = (po['Name'] ?? '').toString();
            pincodeStatusMsg.value = '$areaName, $fetchedCity';

            if (autoOpenModal && list.isNotEmpty) {
              openAreaSelectionModal();
            }
            return;
          }
        }
      }
      pincodeValid.value = false;
      pincodeStatusMsg.value = 'Invalid or unserviceable pincode';
      availableAreas.clear();
      selectedArea.value = null;
    } catch (_) {
      pincodeValid.value = false;
      pincodeStatusMsg.value = 'Pincode lookup error';
      availableAreas.clear();
      selectedArea.value = null;
    } finally {
      fetchingPincode.value = false;
    }
  }

  void openAreaSelectionModal() {
    if (availableAreas.isEmpty) return;

    final searchCtrl = TextEditingController();
    final filteredAreas = <Map<String, dynamic>>[...availableAreas].obs;

    Get.bottomSheet(
      Builder(
        builder: (context) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 38, height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.location_on, color: Colors.black, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Locality / Area',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
                          ),
                          Text(
                            'PIN ${postcode.text} • ${availableAreas.length} area(s) found',
                            style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.of(context).pop();
                        } else {
                          Get.back();
                        }
                      },
                      icon: const Icon(Icons.close, size: 20, color: Colors.black54),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Search filter if more than 4 areas
                if (availableAreas.length > 4) ...[
                  TextField(
                    controller: searchCtrl,
                    onChanged: (q) {
                      final query = q.trim().toLowerCase();
                      if (query.isEmpty) {
                        filteredAreas.assignAll(availableAreas);
                      } else {
                        filteredAreas.assignAll(availableAreas.where((a) {
                          final name = (a['Name'] ?? '').toString().toLowerCase();
                          final dist = (a['District'] ?? '').toString().toLowerCase();
                          return name.contains(query) || dist.contains(query);
                        }).toList());
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Search locality name…',
                      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF6B7280)),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 6),

                // List of localities
                Flexible(
                  child: Obx(() {
                    if (filteredAreas.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No localities found', style: TextStyle(color: Colors.black54)),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: filteredAreas.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      itemBuilder: (_, index) {
                        final item = filteredAreas[index];
                        final areaName = (item['Name'] ?? '').toString();
                        final district = (item['District'] ?? item['Block'] ?? '').toString();
                        final stateName = (item['State'] ?? '').toString();
                        final branchType = (item['BranchType'] ?? 'Post Office').toString();

                        final isSelected = selectedArea.value != null
                            ? selectedArea.value!['Name'] == areaName
                            : index == 0;

                        return InkWell(
                          onTap: () {
                            selectArea(item);
                            if (Navigator.canPop(context)) {
                              Navigator.of(context).pop();
                            } else {
                              Get.back();
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.black : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.near_me,
                                    size: 16,
                                    color: isSelected ? Colors.white : Colors.black54,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        areaName,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                          fontSize: 13.5,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$branchType • $district, $stateName',
                                        style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle, color: Colors.black, size: 20)
                                else
                                  const Icon(Icons.chevron_right, color: Colors.black26, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  void selectArea(Map<String, dynamic> item) {
    selectedArea.value = item;
    final areaName = (item['Name'] ?? '').toString();
    final district = (item['District'] ?? item['Block'] ?? '').toString();
    final stateName = (item['State'] ?? '').toString();

    if (district.isNotEmpty) city.text = district;
    if (stateName.isNotEmpty) state.text = stateName;

    address2.text = areaName;
    pincodeStatusMsg.value = '$areaName, $district';
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
    company.addListener(() {
      hasCompany.value = company.text.trim().isNotEmpty;
    });
    // Recalculate totals whenever payment method or free shipping coupon changes
    ever(selectedPaymentId, (_) => _recalculateTotals());
    ever(isFreeShippingCoupon, (_) => _recalculateTotals());
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    loading(true);
    error.value = null;
    try {
      await _fetchPublicSettings();
      await _loadCartItems();
      await _whoAmI();
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading(false);
    }
  }

  Future<void> _fetchPublicSettings() async {
    try {
      final res = await api.getApi(ApiConstant.publicSettings) as Map;
      final settings = (res['settings'] as Map?)?.cast<String, dynamic>() ?? {};
      final fee = double.tryParse(settings['codFee']?.toString() ?? '0') ?? 0.0;
      codFee.value = fee;
    } catch (_) {
      // Non-critical: just leave codFee at 0
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
    // When a free-shipping coupon is applied, waive BOTH the shipping cost AND the COD handling fee
    final bool freeShip = isFreeShippingCoupon.value;
    final appliedCodFee = (selectedPaymentId.value == 'cod' && !freeShip) ? codFee.value : 0.0;
    final appliedShipping = freeShip ? 0.0 : shippingCost.value;
    final finalTotal = (subtotalVal + appliedShipping + appliedCodFee - discountAmount.value).clamp(0.0, double.infinity);

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
        lookupPincode(postcode.text.trim(), autoOpenModal: false);
      }
    } catch (_) {
      me.value = null;
    }
  }

  Map<String, dynamic> _buildAddress() {
    final comp = company.text.trim();
    final gst = gstNumber.text.trim();
    return {
      'name': '${firstName.text.trim()} ${lastName.text.trim()}'.trim(),
      'phone': phone.text.trim(),
      'email': email.text.trim(),
      'street': address1.text.trim(),
      'street2': address2.text.trim(),
      'locality': selectedArea.value?['Name'] ?? address2.text.trim(),
      'company': comp,
      'gstNumber': comp.isNotEmpty ? gst : '',
      'city': city.text.trim(),
      'state': state.text.trim(),
      'zip': postcode.text.trim(),
      'country': country.text.trim().isNotEmpty ? country.text.trim() : 'India',
    };
  }

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
    // Dismiss keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    final rawCode = couponCtrl.text.trim();
    final code = rawCode.toUpperCase();
    if (code.isEmpty) {
      couponError.value = 'Please enter a coupon code.';
      couponSuccess.value = null;
      return;
    }
    if (appliedCoupons.isNotEmpty) {
      couponError.value = 'Remove the current coupon before applying a new one.';
      couponSuccess.value = null;
      return;
    }

    couponLoading.value = true;
    couponError.value  = null;
    couponSuccess.value = null;

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
        final String type = (couponData['type'] ?? 'fixed').toString().toLowerCase();
        final num discValue = (couponData['discountValue'] as num?) ?? 0;

        double computedDiscount = 0.0;
        if (type == 'percentage') {
          computedDiscount = (subtotalVal * discValue.toDouble()) / 100.0;
        } else {
          // handles both 'fixed' and 'flat'
          computedDiscount = discValue.toDouble();
        }
        if (computedDiscount > subtotalVal) computedDiscount = subtotalVal;

        discountAmount.value = computedDiscount;
        final fs = couponData['freeShipping'];
        isFreeShippingCoupon.value = (fs == true || fs == 'true' || fs == 1);
        appliedCoupons.assignAll([couponCodeStr]);
        _recalculateTotals();

        final savedStr = formatPrice(computedDiscount);
        couponSuccess.value = 'Coupon "$couponCodeStr" applied! You save $savedStr.';
        couponCtrl.clear();
      } else {
        couponError.value = 'Coupon could not be applied. Please try again.';
      }
    } catch (e) {
      final msg = e.toString()
          .replaceAll('Exception: ', '')
          .replaceAll('FatchDataException: ', '')
          .replaceAll('InvalidInputException: ', '');
      couponError.value = msg;
    } finally {
      couponLoading.value = false;
    }
  }

  Future<void> removeCoupon(String code) async {
    appliedCoupons.remove(code);
    discountAmount.value = 0.0;
    isFreeShippingCoupon.value = false;
    couponSuccess.value = null;
    couponError.value  = null;
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
          'shippingCost':    isFreeShippingCoupon.value ? 0.0 : shippingCost.value,
          'codFee':          isFreeShippingCoupon.value ? 0.0 : codFee.value,
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
        'shippingCost': isFreeShippingCoupon.value ? 0.0 : shippingCost.value,
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
        'shippingCost':    isFreeShippingCoupon.value ? 0.0 : shippingCost.value,
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
    firstName.dispose(); lastName.dispose(); company.dispose(); gstNumber.dispose(); country.dispose();
    address1.dispose(); address2.dispose(); city.dispose(); state.dispose();
    postcode.dispose(); phone.dispose(); email.dispose();
    couponCtrl.dispose(); noteCtrl.dispose();
    super.onClose();
  }
}




