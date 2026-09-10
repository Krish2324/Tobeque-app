import 'package:tobeque/constants/api_constants.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:tobeque/data/network/network_api_sarvices.dart';

class OrdersController extends GetxController {
  final loading = true.obs;
  final error   = RxnString();
  final orders  = <Map<String, dynamic>>[].obs;

  late final NetworkApi _net;

  @override
  void onInit() {
    super.onInit();
    _net = NetworkApi();
    fetchOrders();
  }

  void onCancelOrder(Map<String, dynamic> order) {
    final id = order['_id'] ?? order['id'] ?? order['orderId'] ?? order['number'];
    Get.defaultDialog(
      title: "Cancel Order",
      middleText: "Are you sure you want to cancel order #$id?",
      textConfirm: "Yes, Cancel",
      textCancel: "No",
      onConfirm: () {
        cancelOrderApi(id.toString());
        Get.back();
      },
    );
  }

  void onReturnOrder(Map<String, dynamic> order) {
    final id = order['_id'] ?? order['id'] ?? order['orderId'] ?? order['number'];
    Get.defaultDialog(
      title: "Return Order",
      middleText: "Do you want to initiate a return for order #$id?",
      textConfirm: "Yes, Return",
      textCancel: "No",
      onConfirm: () {
        returnOrderApi(id.toString());
        Get.back();
      },
    );
  }

  Future<void> cancelOrderApi(String orderId) async {
    try {
      loading(true);
      await _net.putApi({'status': 'cancelled'}, '${ApiConstant.userOrders}/$orderId');
      fetchOrders();
      Get.snackbar('Order Cancelled', 'Order has been cancelled.');
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', error.value ?? 'Cancel failed');
    } finally {
      loading(false);
    }
  }

  Future<void> returnOrderApi(String orderId) async {
    try {
      loading(true);
      await _net.postApi({'orderId': orderId, 'reason': 'Customer requested return'}, 'refund-requests');
      fetchOrders();
      Get.snackbar('Return Initiated', 'Return request submitted.');
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', error.value ?? 'Return failed');
    } finally {
      loading(false);
    }
  }

  Future<void> fetchOrders() async {
    loading(true);
    error.value = null;
    try {
      final res = await _net.getApi(ApiConstant.userOrders);
      List list = [];
      if (res is Map && res['orders'] is List) {
        list = res['orders'];
      } else if (res is List) {
        list = res;
      }

      final mapped = list.map((raw) {
        final m = Map<String, dynamic>.from(raw as Map);
        final total = m['total'] ?? m['totalAmount'] ?? m['grandTotal'] ?? 0;
        m['total_html'] = '₹$total';
        m['currency_symbol'] = '₹';
        m['date_created'] = (m['createdAt'] ?? m['date'] ?? '').toString();
        return m;
      }).toList();

      orders.assignAll(mapped);
      if (orders.isEmpty) {
        error.value = 'No orders found.';
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading(false);
    }
  }

  String fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('MMM d, yyyy • h:mm a').format(dt.toLocal());
  }

  String statusLabel(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'processing': return 'Processing';
      case 'completed' :
      case 'delivered' : return 'Delivered';
      case 'pending'   : return 'Pending';
      case 'shipped'   : return 'Shipped';
      case 'cancelled' : return 'Cancelled';
      case 'refunded'  : return 'Refunded';
      default: return s ?? '—';
    }
  }

  String totalText(Map<String, dynamic> o) {
    final tHtml = (o['total_html'] ?? '').toString();
    if (tHtml.isNotEmpty) return tHtml;
    final t = (o['total'] ?? o['totalAmount'] ?? '').toString();
    if (t.isNotEmpty) return '₹$t';
    return '';
  }
}

