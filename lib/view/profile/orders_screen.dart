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
      appBar: AppBar(
        title: const Text('My Orders'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null && controller.orders.isEmpty) {
          return _ErrorCard(
            message: controller.error.value!,
            onRetry: controller.fetchOrders,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchOrders,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: controller.orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final o = controller.orders[i];
            final id = ((o['id'] ?? o['number']) as num).toInt();
              final date = controller.fmtDate(o['date_created']?.toString() ?? o['date_created_gmt']?.toString());
              final status = controller.statusLabel(o['status']?.toString());
              final total  = controller.totalText(o);

              // item preview
              final items = (o['line_items'] as List?) ?? (o['items'] as List?) ?? const [];
              final firstName = (items.isNotEmpty)
                  ? ((items.first as Map)['name']?.toString() ?? '')
                  : '';
return InkWell(
  onTap: () => Get.to(() => OrderViewScreen(order: o, orderId: id,)),
  child: Card(
    elevation: 0,
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
             // CircleAvatar(radius: 22, child: Text('#${!id ? '?' : id}')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstName.isEmpty ? 'Order #$id' : firstName,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(date, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _StatusChip(status: status),
                        const Spacer(),
                        Text(total, style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Action buttons row
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.end,
          //   children: [
          //     // Show Cancel if status is 'processing' or 'pending'
          //     if (status.toLowerCase() == 'processing' || status.toLowerCase() == 'pending')
          //       TextButton(
          //         onPressed: () =>controller.onCancelOrder(o),
          //         child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          //       ),
          //     // Show Return if status is 'completed'
          //     if (status.toLowerCase() == 'completed')
          //       TextButton(
          //         onPressed: () => controller.onReturnOrder(o),
          //         child: const Text('Return', style: TextStyle(color: Colors.orange)),
          //       ),
          //   ],
          // ),
        ],
      ),
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
    if (s.contains('complete')) return const Color(0xffe8f5e9);
    if (s.contains('process')) return const Color(0xfffff8e1);
    if (s.contains('pending') || s.contains('hold')) return const Color(0xfffff3e0);
    if (s.contains('cancel') || s.contains('fail') || s.contains('refund')) return const Color(0xffffebee);
    return const Color(0xffeceff1);
    }
  Color _fg() {
    final s = status.toLowerCase();
    if (s.contains('complete')) return const Color(0xff2e7d32);
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
