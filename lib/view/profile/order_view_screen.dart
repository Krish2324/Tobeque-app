import 'package:tobeque/view/prodduct_details/product_detail_binding.dart';
import 'package:tobeque/view/prodduct_details/product_details_page.dart';
import 'package:tobeque/view/profile/orders_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';



class OrderViewScreen extends StatelessWidget {
  const OrderViewScreen({super.key, required this.orderId, required Map<String, dynamic> order});
  final int orderId;

  @override
  Widget build(BuildContext context) {
    final OrdersController controller = Get.find<OrdersController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$orderId'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Obx(() {
        final order = controller.orders.firstWhereOrNull((o) => o['id'] == orderId);
        if (order == null) return const Center(child: Text('Order not found'));

        final status = (order['status'] ?? '').toString();
        final total  = (order['total_html'] ?? order['total'] ?? '').toString();
        final items  = (order['line_items'] as List?) ?? const [];
        final billing  = (order['billing_address'] ?? order['billing']) as Map? ?? {};
        final shipping = (order['shipping_address'] ?? order['shipping']) as Map? ?? {};

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            Row(
              children: [
                const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w700)),
                Text(status),
                const Spacer(),
                Text(total, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            const Text('Items', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),

            ...items.map((it) {
              final m = (it as Map).cast<String, dynamic>();
              final name = (m['name'] ?? '').toString();
              final qty  = (m['quantity'] as num?)?.toInt() ?? 1;
              final subt = (m['total_html'] ?? m['total'] ?? '').toString();

              // Extract image
              String? imageUrl;
              if (m.containsKey('images') && (m['images'] as List).isNotEmpty) {
                final firstImage = (m['images'] as List).first;
                if (firstImage is Map && firstImage.containsKey('src')) {
                  imageUrl = firstImage['src']?.toString();
                }
              } else if (m.containsKey('image') && m['image'] is Map && m['image'].containsKey('src')) {
                imageUrl = m['image']['src']?.toString();
              }

              final productId = m['product_id'] ?? m['id'];

              return InkWell(
                onTap: productId != null
                    ? () {
                        Get.to(
                          () => ProductDetailPage(key: ValueKey(productId), productId: productId),
                          binding: ProductDetailBinding(productId),
                        );
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        Container(
                          width: 56,
                          height: 56,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 56,
                          height: 56,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      Expanded(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Text('x$qty'),
                      const SizedBox(width: 8),
                      Text(subt, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            }),

            const Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _AddrCard(title: 'Billing', m: billing.cast())),
                const SizedBox(width: 12),
                Expanded(child: _AddrCard(title: 'Shipping', m: shipping.cast())),
              ],
            ),

            if (status.toLowerCase() == 'processing' || status.toLowerCase() == 'pending')
              TextButton(
                onPressed: () => controller.onCancelOrder(order),
                child: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
              ),
            if (status.toLowerCase() == 'completed')
              TextButton(
                onPressed: () => controller.onReturnOrder(order),
                child: const Text('Return Order', style: TextStyle(color: Colors.orange)),
              ),
          ],
        );
      }),
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
      '${line('first_name')} ${line('last_name')}'.trim(),
      line('company'),
      line('address_1'),
      line('address_2'),
      '${line('city')} ${line('state')} ${line('postcode')}'.trim(),
      line('country'),
      line('phone'),
      line('email'),
    ].where((s) => s.isNotEmpty).toList();

    return Card(
      elevation: 0, color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          ...lines.map((s) => Text(s)),
        ]),
      ),
    );
  }
}
