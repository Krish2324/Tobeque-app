import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'orders_binding.dart';
import 'orders_controller.dart';
import 'order_view_screen.dart';

class OrdersScreen extends GetView<OrdersController> {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    OrdersBinding().dependencies();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        }
        if (controller.error.value != null && controller.orders.isEmpty) {
          return _ErrorCard(
            message: controller.error.value!,
            onRetry: controller.fetchOrders,
          );
        }

        if (controller.orders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.black38),
                  const SizedBox(height: 12),
                  const Text('No orders yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('When you place an order, it will appear here.', style: TextStyle(color: Colors.black54, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.fetchOrders,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                    child: const Text('Refresh Orders'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchOrders,
          color: Colors.black,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            itemCount: controller.orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final o = controller.orders[i];
              final orderIdStr = (o['id_str'] ?? o['display_id'] ?? '').toString();
              final displayId = (o['display_id'] ?? o['orderNumber'] ?? orderIdStr).toString();
              final date = controller.fmtDate(o['date_created']?.toString() ?? o['createdAt']?.toString());
              final status = controller.statusLabel(o['orderStatus']?.toString() ?? o['status']?.toString());
              final total  = controller.totalText(o);

              // extract items
              final items = (o['items'] as List?) ?? (o['line_items'] as List?) ?? const [];
              final firstItem = items.isNotEmpty ? (items.first as Map?) : null;
              final firstName = firstItem != null
                  ? (firstItem['productName'] ?? firstItem['name'] ?? (firstItem['product'] as Map?)?['name'] ?? '')
                  : '';
              final itemCount = items.length;

              return InkWell(
                onTap: () => Get.to(() => OrderViewScreen(order: o, orderId: orderIdStr)),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order #$displayId', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          _StatusChip(status: status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (firstName.toString().isNotEmpty) ...[
                        Text(
                          firstName.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                        ),
                        if (itemCount > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text('+ ${itemCount - 1} more item(s)', style: const TextStyle(color: Colors.black54, fontSize: 11)),
                          ),
                        const SizedBox(height: 6),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(date, style: const TextStyle(color: Colors.black54, fontSize: 11.5)),
                          Text(total, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.receipt_long_outlined, size: 42, color: Colors.black54),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ]),
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
