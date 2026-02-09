import 'dart:convert';
import 'package:tobeque/constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:tobeque/data/network/network_api_sarvices.dart'; // for /users/me (cookies handled here)


class OrdersController extends GetxController {
  final loading = true.obs;
  final error   = RxnString();
  final orders  = <Map<String, dynamic>>[].obs;

  late final NetworkApi _net; // your existing client for cookie-auth calls
  late final Dio _wc;         // separate Dio to hit wc/v3 with ck/cs

  @override
  void onInit() {
    super.onInit();

    _net = NetworkApi();

    // --- Woo v3 client ---
    _wc = Dio(BaseOptions(
      baseUrl: 'https://tobeque.com/wp-json/wc/v3/',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: const { 'Accept': 'application/json' },
    ));

    // Add HTTP Basic auth header from ck/cs on every request
    final basic = base64Encode(utf8.encode('${ApiConstant.consumerKey}:${ApiConstant.consumerSecret}'));
    _wc.interceptors.add(InterceptorsWrapper(onRequest: (opt, h) {
      opt.headers['Authorization'] = 'Basic $basic';
      h.next(opt);
    }));

    fetchOrders();
  }


void onCancelOrder(Map<String, dynamic> order) {
  // You can show a confirmation dialog, then call your API to cancel
  final id = order['id'] ?? order['number'];
  Get.defaultDialog(
    title: "Cancel Order",
    middleText: "Are you sure you want to cancel order #$id?",
    textConfirm: "Yes, Cancel",
    textCancel: "No",
    onConfirm: () {
     cancelOrderApi(id);
       Get.back();
    
      
     

      // Optionally refresh orders after cancel
      fetchOrders();
      Get.snackbar('Order Cancelled', 'Order #$id has been cancelled.');
    },
  );
}

void onReturnOrder(Map<String, dynamic> order) {
  // Confirm return request, or redirect to return process
  final id = order['id'] ?? order['number'];
  Get.defaultDialog(
    title: "Return Order",
    middleText: "Do you want to initiate a return for order #$id?",
    textConfirm: "Yes, Return",
    textCancel: "No",
    onConfirm: () {
    returnOrderApi(id);
      Get.back();
      fetchOrders();
      Get.snackbar('Return Initiated', 'Return process started for order #$id.');
    },
  );
}


Future<void> cancelOrderApi(int orderId) async {
  try {
    loading(true);

    final res = await _wc.put(
      'orders/$orderId',
      data: { 'status': 'cancelled' },
    );

    final updated = Map<String, dynamic>.from(res.data);

    // Update local list
    final idx = orders.indexWhere((o) => o['id'] == orderId);
    if (idx != -1) {
      orders[idx] = updated;
    }

    Get.snackbar('Order Cancelled', 'Order #$orderId has been cancelled.');
  } on DioException catch (e) {
    print(e);
    error.value = e.response?.data?.toString() ?? 'Cancel failed';
    Get.snackbar('Error', error.value ?? 'Cancel failed');
  } finally {
    loading(false);
  }
}

Future<void> returnOrderApi(int orderId) async {
  try {
    loading(true);

    // Option 1: simply mark order as refunded
    final res = await _wc.put(
      'orders/$orderId',
      data: { 'status': 'refunded' },
    );

    final updated = Map<String, dynamic>.from(res.data);

    final idx = orders.indexWhere((o) => o['id'] == orderId);
    if (idx != -1) {
      orders[idx] = updated;
    }

    Get.snackbar('Return Initiated', 'Return started for order #$orderId.');
  } on DioException catch (e) {
    error.value = e.response?.data?.toString() ?? 'Return failed';
    Get.snackbar('Error', error.value ?? 'Return failed');
  } finally {
    loading(false);
  }
}

  Future<void> fetchOrders() async {
    loading(true);
    error.value = null;
    try {
      // 1) Who am I? (cookie/JWT based — you already have this working)
      final me = await _net.getApi('https://tobeque.com/wp-json/wp/v2/users/me') as Map;
      final uid = (me['id'] as num).toInt();

      // 2) Pull this user’s orders via Woo v3 using ck/cs
      final res = await _wc.get('orders', queryParameters: {
        'customer': uid,
        'per_page': 20,
        'orderby' : 'date',
        'order'   : 'desc',
        // 'status': 'any', // optional
      });

      final list = (res.data as List?) ?? const [];
      final mapped = list.whereType<Map>().map((raw) {
        final m = Map<String, dynamic>.from(raw);

        // Enrich: add a total_html the UI expects
        final currency = (m['currency'] ?? '').toString();
        final totalStr = (m['total'] ?? '').toString();
        m['total_html']  = '${_symbol(currency)}$totalStr';
        m['currency_symbol'] = _symbol(currency);

        // Keep dates consistent with your fmtDate
        m['date_created'] = (m['date_created'] ?? m['date_created_gmt'] ?? '').toString();

        // line_items already present; keep as-is
        return m;
      }).toList();

      orders.assignAll(mapped);
      if (orders.isEmpty) {
        error.value = 'No orders found.';
      }
    } on DioException catch (e) {
      // Common issues: wrong keys (401), keys lack permissions (403)
      final sc = e.response?.statusCode;
      if (sc == 401 || sc == 403) {
        error.value = 'WooCommerce API auth failed (HTTP $sc). Check consumer key/secret permissions.';
      } else {
        error.value = e.response?.data?.toString() ?? 'Failed to load orders.';
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading(false);
    }
  }
  
  /* ---------------- UI helpers (same signatures you already use) ---------------- */

  String fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('MMM d, yyyy • h:mm a').format(dt.toLocal());
  }

  String statusLabel(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'processing': return 'Processing';
      case 'completed' : return 'Completed';
      case 'pending'   :
      case 'pending payment': return 'Pending';
      case 'on-hold'   : return 'On hold';
      case 'cancelled' : return 'Cancelled';
      case 'refunded'  : return 'Refunded';
      case 'failed'    : return 'Failed';
      default: return s ?? '—';
    }
  }

  String totalText(Map<String, dynamic> o) {
    // Prefer the enriched total_html
    final tHtml = (o['total_html'] ?? '').toString();
    if (tHtml.isNotEmpty) return tHtml;

    final t = (o['total'] ?? '').toString();
    if (t.isNotEmpty) {
      final sym = _symbol((o['currency'] ?? '').toString());
      return '$sym$t';
    }
    return '';
  }

  String _symbol(String code) {
    switch (code.toUpperCase()) {
      case 'INR': return '₹';
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'AUD': return 'A\$';
      case 'CAD': return 'C\$';
      case 'JPY': return '¥';
      default:    return ''; // fallback: empty → UI will show just the number
    }
  }
}
