import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/view/prodduct_details/product_detail_binding.dart';
import 'package:tobeque/view/prodduct_details/product_details_page.dart';
import 'package:tobeque/view/profile/orders_controller.dart';

class OrderViewScreen extends StatelessWidget {
  const OrderViewScreen({super.key, required this.orderId, required this.order});
  final String orderId;
  final Map<String, dynamic> order;

  Map<String, dynamic> _parseAddress(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map) return raw.cast<String, dynamic>();
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = json.decode(raw);
        if (decoded is Map) return decoded.cast<String, dynamic>();
      } catch (_) {}
      return {'street': raw};
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final OrdersController controller = Get.find<OrdersController>();

    final liveOrder = controller.orders.firstWhereOrNull(
      (o) => (o['id_str'] == orderId || o['display_id'] == orderId || o['_id'] == orderId || o['orderNumber'] == orderId)
    ) ?? order;

    final displayId = (liveOrder['display_id'] ?? liveOrder['orderNumber'] ?? liveOrder['id_str'] ?? orderId).toString();
    final status = controller.statusLabel(liveOrder['orderStatus']?.toString() ?? liveOrder['status']?.toString());
    final total = controller.totalText(liveOrder);
    final date = controller.fmtDate(liveOrder['date_created']?.toString() ?? liveOrder['createdAt']?.toString());

    final items = (liveOrder['items'] as List?) ?? (liveOrder['line_items'] as List?) ?? const [];
    final billing = _parseAddress(liveOrder['billingAddress'] ?? liveOrder['billing_address'] ?? liveOrder['billing']);
    final shipping = _parseAddress(liveOrder['shippingAddress'] ?? liveOrder['shipping_address'] ?? liveOrder['shipping']);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text('Order #$displayId', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          // Order Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order #$displayId', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    _StatusChip(status: status),
                  ],
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Placed on $date', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(total, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // Items Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ordered Items', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 12),
                ...items.map((it) {
                  final m = (it as Map).cast<String, dynamic>();
                  final name = (m['productName'] ?? m['name'] ?? (m['product'] as Map?)?['name'] ?? 'Product').toString();
                  final qty = (m['quantity'] as num?)?.toInt() ?? 1;
                  final priceNum = (m['price'] as num?)?.toDouble() ?? 0.0;
                  final subt = '₹${NumberFormat.decimalPattern('en_IN').format((priceNum * qty).round())}';

                  // Extract image
                  String img = '';
                  final pObj = m['product'];
                  if (pObj is Map && pObj['thumbnail'] != null) {
                    img = ApiConstant.getImageUrl(pObj['thumbnail'].toString());
                  } else if (m['image'] != null) {
                    img = ApiConstant.getImageUrl(m['image'].toString());
                  }

                  final prodId = (m['productId'] ?? m['product']?['_id'] ?? m['product_id'] ?? m['id'])?.toString();

                  return InkWell(
                    onTap: prodId != null && prodId.isNotEmpty
                        ? () {
                            Get.to(
                              () => ProductDetailPage(key: ValueKey(prodId), productId: prodId),
                              binding: ProductDetailBinding(prodId),
                            );
                          }
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 52,
                              height: 58,
                              color: const Color(0xFFF5F5F5),
                              child: img.isEmpty
                                  ? const Icon(Icons.image_outlined, color: Colors.black26, size: 24)
                                  : Image.network(img, fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('Qty: $qty', style: const TextStyle(color: Colors.black54, fontSize: 11.5)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(subt, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // Delivery & Billing Address Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Address Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _AddrCard(title: 'Shipping Address', m: shipping)),
                    const SizedBox(width: 12),
                    Expanded(child: _AddrCard(title: 'Billing Address', m: billing)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          if (status.toLowerCase() == 'processing' || status.toLowerCase() == 'pending')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => controller.onCancelOrder(liveOrder),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                child: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddrCard extends StatelessWidget {
  const _AddrCard({required this.title, required this.m});
  final String title;
  final Map<String, dynamic> m;

  @override
  Widget build(BuildContext context) {
    String line(String k) => (m[k]?.toString() ?? '');
    final lines = <String>[
      '${line('name').isNotEmpty ? line('name') : '${line('first_name')} ${line('last_name')}'}'.trim(),
      line('company'),
      line('street').isNotEmpty ? line('street') : line('address_1'),
      line('address_2'),
      '${line('city')} ${line('state')} ${line('zip').isNotEmpty ? line('zip') : line('postcode')}'.trim(),
      line('country'),
      line('phone'),
      line('email'),
    ].where((s) => s.isNotEmpty).toList();

    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
            const SizedBox(height: 6),
            ...lines.map((s) => Text(s, style: const TextStyle(fontSize: 11.5, height: 1.3))),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  Color _bg() {
    final s = status.toLowerCase();
    if (s.contains('complete') || s.contains('deliver')) return const Color(0xffe8f5e9);
    if (s.contains('process')) return const Color(0xfffff8e1);
    if (s.contains('pending') || s.contains('hold')) return const Color(0xfffff3e0);
    if (s.contains('cancel') || s.contains('fail') || s.contains('refund')) return const Color(0xffffebee);
    return const Color(0xffeceff1);
  }

  Color _fg() {
    final s = status.toLowerCase();
    if (s.contains('complete') || s.contains('deliver')) return const Color(0xff2e7d32);
    if (s.contains('process')) return const Color(0xfff57c00);
    if (s.contains('pending') || s.contains('hold')) return const Color(0xffef6c00);
    if (s.contains('cancel') || s.contains('fail') || s.contains('refund')) return const Color(0xffc62828);
    return const Color(0xff37474f);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: _bg(), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: _fg(), fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
