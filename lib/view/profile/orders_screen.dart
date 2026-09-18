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
      backgroundColor: const Color(0xFFF4F4F6),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MY ORDERS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                letterSpacing: 0.5,
              ),
            ),
            Obx(() => Text(
              controller.orders.isEmpty
                  ? 'No orders yet'
                  : '${controller.orders.length} order${controller.orders.length == 1 ? '' : 's'} found',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            )),
          ],
        ),
        actions: [
          IconButton(
            onPressed: controller.fetchOrders,
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh Orders',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() => _buildBody()),
    );
  }

  Widget _buildBody() {
    if (controller.loading.value) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
            SizedBox(height: 14),
            Text('Loading your orders…', style: TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
      );
    }

    if (controller.error.value != null && controller.orders.isEmpty) {
      return _EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Something went wrong',
        subtitle: controller.error.value!,
        actionLabel: 'Try Again',
        onAction: controller.fetchOrders,
      );
    }

    if (controller.orders.isEmpty) {
      return _EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'No orders yet',
        subtitle: 'Your placed orders will appear here.\nStart shopping and come back!',
        actionLabel: 'Refresh',
        onAction: controller.fetchOrders,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.fetchOrders,
      color: Colors.black,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: controller.orders.length,
        itemBuilder: (_, i) => _OrderCard(
          order: controller.orders[i],
          controller: controller,
          isFirst: i == 0,
          isLast: i == controller.orders.length - 1,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Order Card
// ─────────────────────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.controller,
    this.isFirst = false,
    this.isLast = false,
  });

  final Map<String, dynamic> order;
  final OrdersController controller;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final orderIdStr = (order['id_str'] ?? order['display_id'] ?? '').toString();
    final displayId = (order['display_id'] ?? order['orderNumber'] ?? orderIdStr).toString();
    final dateStr = controller.fmtDate(order['date_created']?.toString() ?? order['createdAt']?.toString());
    final status = controller.statusLabel(order['orderStatus']?.toString() ?? order['status']?.toString());
    final total = controller.totalText(order);
    final paymentMethod = (order['paymentMethod'] ?? 'cod').toString();
    final paymentStatus = (order['paymentStatus'] ?? 'pending').toString();
    final trackingNumber = order['trackingNumber']?.toString();
    final couponCode = order['couponCode']?.toString();
    final shippingCost = (order['shippingCost'] as num?)?.toDouble() ?? 0.0;

    final items = (order['items'] as List?) ?? (order['line_items'] as List?) ?? const [];

    final _StatusConfig cfg = _StatusConfig.fromStatus(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Get.to(() => OrderViewScreen(order: order, orderId: orderIdStr)),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // ── Coloured status stripe header ──────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: cfg.bg.withValues(alpha: 0.15),
                  border: Border(
                    left: BorderSide(color: cfg.fg, width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(cfg.icon, size: 16, color: cfg.fg),
                    const SizedBox(width: 8),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: cfg.fg,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              // ── Main body ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order number & total
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #$displayId',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14.5,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 3),
                              // Payment method badge
                              Row(
                                children: [
                                  _PaymentBadge(method: paymentMethod, paymentStatus: paymentStatus),
                                  if (couponCode != null && couponCode.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    _CouponBadge(code: couponCode),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              total,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: Colors.black,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (shippingCost > 0)
                              Text(
                                'incl. ₹${shippingCost.toStringAsFixed(0)} shipping',
                                style: const TextStyle(fontSize: 10.5, color: Colors.black45),
                              ),
                          ],
                        ),
                      ],
                    ),

                    if (items.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      const SizedBox(height: 12),
                      // Item thumbnails row
                      _ItemsPreview(items: items),
                    ],

                    if (trackingNumber != null && trackingNumber.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFD0FF)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined, size: 15, color: Color(0xFF3B4FBF)),
                            const SizedBox(width: 6),
                            const Text(
                              'Tracking: ',
                              style: TextStyle(fontSize: 12, color: Color(0xFF3B4FBF), fontWeight: FontWeight.w700),
                            ),
                            Expanded(
                              child: Text(
                                trackingNumber,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF3B4FBF), fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Footer ─────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF3F3F3))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chevron_right, size: 16, color: Colors.black38),
                    const SizedBox(width: 4),
                    const Text(
                      'View order details',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54),
                    ),
                    const Spacer(),
                    _ItemCountBadge(count: items.length),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item thumbnails preview row
// ─────────────────────────────────────────────────────────────────────────────
class _ItemsPreview extends StatelessWidget {
  const _ItemsPreview({required this.items});
  final List items;

  @override
  Widget build(BuildContext context) {
    final show = items.take(4).toList();
    final extra = items.length - show.length;

    return Row(
      children: [
        ...show.map((item) {
          final m = item as Map?;
          final name = (m?['productName'] ?? m?['name'] ?? (m?['product'] as Map?)?['name'] ?? '').toString();
          final thumb = (m?['thumbnail'] ?? m?['image'] ?? (m?['product'] as Map?)?['thumbnail'] ?? '').toString();
          final qty = (m?['quantity'] as num?)?.toInt() ?? 1;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 52,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: thumb.isNotEmpty
                            ? Image.network(thumb, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: Colors.black26, size: 20))
                            : Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black26),
                                ),
                              ),
                      ),
                    ),
                    if (qty > 1)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '×$qty',
                            style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 52,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9.5, color: Colors.black54, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }),
        if (extra > 0)
          Container(
            width: 52,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '+$extra',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black45),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment Method Badge
// ─────────────────────────────────────────────────────────────────────────────
class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.method, required this.paymentStatus});
  final String method;
  final String paymentStatus;

  @override
  Widget build(BuildContext context) {
    final isCod = method.toLowerCase() == 'cod';
    final isPaid = paymentStatus.toLowerCase() == 'paid';
    final Color bg = isCod
        ? (isPaid ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1))
        : const Color(0xFFE3F2FD);
    final Color fg = isCod
        ? (isPaid ? const Color(0xFF2E7D32) : const Color(0xFFE65100))
        : const Color(0xFF1565C0);
    final IconData icon = isCod ? Icons.payments_outlined : Icons.credit_card;
    final String label = isCod ? (isPaid ? 'COD Paid' : 'Cash on Delivery') : 'Online Paid';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: fg)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coupon Badge
// ─────────────────────────────────────────────────────────────────────────────
class _CouponBadge extends StatelessWidget {
  const _CouponBadge({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFD8B4FE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_offer, size: 11, color: Color(0xFF7C3AED)),
          const SizedBox(width: 4),
          Text(code, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item count badge
// ─────────────────────────────────────────────────────────────────────────────
class _ItemCountBadge extends StatelessWidget {
  const _ItemCountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count item${count == 1 ? '' : 's'}',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Config
// ─────────────────────────────────────────────────────────────────────────────
class _StatusConfig {
  final Color bg;
  final Color fg;
  final IconData icon;

  const _StatusConfig({required this.bg, required this.fg, required this.icon});

  factory _StatusConfig.fromStatus(String status) {
    final s = status.toLowerCase();
    if (s.contains('deliver') || s.contains('complet')) {
      return const _StatusConfig(bg: Color(0xFFE8F5E9), fg: Color(0xFF2E7D32), icon: Icons.check_circle_outline);
    }
    if (s.contains('ship')) {
      return const _StatusConfig(bg: Color(0xFFE3F2FD), fg: Color(0xFF1565C0), icon: Icons.local_shipping_outlined);
    }
    if (s.contains('process') || s.contains('confirm')) {
      return const _StatusConfig(bg: Color(0xFFFFF8E1), fg: Color(0xFFF57C00), icon: Icons.autorenew);
    }
    if (s.contains('cancel') || s.contains('refund') || s.contains('return')) {
      return const _StatusConfig(bg: Color(0xFFFFEBEE), fg: Color(0xFFC62828), icon: Icons.cancel_outlined);
    }
    return const _StatusConfig(bg: Color(0xFFF3F4F6), fg: Color(0xFF374151), icon: Icons.hourglass_empty);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / Error State
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: Colors.black38),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
