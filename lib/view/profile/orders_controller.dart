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

  Future<void> fetchOrders() async {
    loading(true);
    error.value = null;
    try {
      String? userPhone;
      try {
        final profileRes = await _net.getApi(ApiConstant.userProfile);
        if (profileRes is Map) {
          final u = (profileRes['user'] as Map?) ?? profileRes;
          userPhone = u['phone']?.toString();
        }
      } catch (_) {}

      final res = await _net.getApi(ApiConstant.userOrders);
      List list = [];
      if (res is Map && res['orders'] is List) {
        list = res['orders'];
      } else if (res is List) {
        list = res;
      }

      if (userPhone != null && userPhone.trim().isNotEmpty) {
        final cleanPhone = userPhone.trim().replaceAll(RegExp(r'[^0-9]'), '');
        try {
          final phoneRes = await _net.getApi('${ApiConstant.userOrders}?phone=$cleanPhone&customerPhone=$cleanPhone');
          List phoneList = [];
          if (phoneRes is Map && phoneRes['orders'] is List) {
            phoneList = phoneRes['orders'];
          } else if (phoneRes is List) {
            phoneList = phoneRes;
          }

          final existingIds = list.map((e) => (e['_id'] ?? e['id'] ?? e['orderNumber'] ?? '').toString()).toSet();
          for (final item in phoneList) {
            final itemId = (item['_id'] ?? item['id'] ?? item['orderNumber'] ?? '').toString();
            if (itemId.isNotEmpty && !existingIds.contains(itemId)) {
              list.add(item);
              existingIds.add(itemId);
            }
          }
        } catch (_) {}
      }

      final mapped = list.map((raw) {
        final m = Map<String, dynamic>.from(raw as Map);
        final num totalNum = (m['totalAmount'] ?? m['total'] ?? m['grandTotal'] ?? 0) as num;
        m['total_html'] = '₹${NumberFormat.decimalPattern('en_IN').format(totalNum.round())}';
        m['currency_symbol'] = '₹';
        m['date_created'] = (m['createdAt'] ?? m['date'] ?? '').toString();
        m['display_id'] = (m['orderNumber'] ?? m['order_number'] ?? m['_id'] ?? m['id'] ?? '').toString();
        m['id_str'] = (m['_id'] ?? m['id'] ?? m['orderNumber'] ?? '').toString();
        return m;
      }).toList();

      orders.assignAll(mapped);
    } catch (e) {
      error.value = e.toString().replaceAll('Exception: ', '').replaceAll('FatchDataException: ', '');
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
      default: return s ?? 'Pending';
    }
  }

  String totalText(Map<String, dynamic> o) {
    final tHtml = (o['total_html'] ?? '').toString();
    if (tHtml.isNotEmpty) return tHtml;
    final t = (o['totalAmount'] ?? o['total'] ?? '').toString();
    if (t.isNotEmpty) return '₹$t';
    return '₹0';
  }

  void onCancelOrder(Map<String, dynamic> order) {
    final id = order['display_id'] ?? order['id_str'] ?? '';
    Get.defaultDialog(
      title: "Cancel Order",
      middleText: "Are you sure you want to cancel order #$id?",
      textConfirm: "Yes, Cancel",
      textCancel: "No",
      onConfirm: () {
        cancelOrderApi((order['id_str'] ?? id).toString());
        Get.back();
      },
    );
  }

  void onReturnOrder(Map<String, dynamic> order) {
    final id = order['display_id'] ?? order['id_str'] ?? '';
    Get.defaultDialog(
      title: "Return Order",
      middleText: "Do you want to initiate a return for order #$id?",
      textConfirm: "Yes, Return",
      textCancel: "No",
      onConfirm: () {
        returnOrderApi((order['id_str'] ?? id).toString());
        Get.back();
      },
    );
  }

  Future<void> cancelOrderApi(String orderId) async {
    try {
      loading(true);
      await _net.putApi({'status': 'cancelled'}, '${ApiConstant.userOrders}/$orderId');
      await fetchOrders();
      Get.snackbar('Order Cancelled', 'Order has been cancelled successfully.');
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''));
    } finally {
      loading(false);
    }
  }

  Future<void> returnOrderApi(String orderId) async {
    try {
      loading(true);
      await _net.postApi({'orderId': orderId, 'reason': 'Customer requested return'}, 'refund-requests');
      await fetchOrders();
      Get.snackbar('Return Initiated', 'Return request submitted successfully.');
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''));
    } finally {
      loading(false);
    }
  }
}

