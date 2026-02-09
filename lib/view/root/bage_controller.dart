import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:tobeque/view/cart/cart_events.dart';
import 'package:tobeque/data/network/network_api_sarvices.dart';
import 'package:tobeque/view/prodduct_details/product_api_repo.dart';

/// Controls the live cart badge count.
///
/// - Listens to CartEvents.version to refresh on any cart change
/// - Computes count as SUM of item quantities (fallback to items_count/length)
class CartBadgeController extends GetxController {
  late final ProductApi api;

  /// Current badge number.
  final count = 0.obs;

  /// Prevents overlapping refresh calls.
  final _loading = false.obs;

   bool _pending = false;

  @override
  void onInit() {
    super.onInit();

    if (!Get.isRegistered<CartEvents>()) {
      Get.put(CartEvents(), permanent: true);
    }
    api = ProductApi(NetworkApi());

    // initial load
    _refresh();

    final ev = Get.find<CartEvents>();
    // 1) update from optimistic count immediately
    ever<int>(ev.count, (c) => count.value = c);
    // 2) refresh from server whenever version bumps
    ever<int>(ev.version, (_) => _refresh());
  }

  Future<void> _refresh() async {
    if (_loading.value) { _pending = true; return; }
    _loading.value = true;
    try {
      final cart = await api.fetchCart();
      final items = (cart['items'] as List?) ?? const [];
      var sum = 0;
      for (final it in items) {
        if (it is Map) sum += ((it['quantity'] as num?)?.toInt() ?? 0);
      }
      final fallback = (cart['items_count'] as num?)?.toInt()
          ?? (cart['itemsCount'] as num?)?.toInt()
          ?? items.length;

      final newCount = sum > 0 ? sum : fallback;
      count.value = newCount;
      Get.find<CartEvents>().setCount(newCount);
    } catch (_) {
      // keep last
    } finally {
      _loading.value = false;
      if (_pending) {
        _pending = false;
        // run the queued refresh
        // ignore: unawaited_futures
        _refresh();
      }
    }
  }

  /// Public method to force-refresh from outside (e.g., right after addToCart).
  Future<void> refreshNow() => _refresh();

 
  
}

/// Small red bubble to show the count.
/// Usage: place `const CartBadge()` as trailing above your cart icon.
class CartBadge extends StatelessWidget {
  const CartBadge({super.key});

  @override
  Widget build(BuildContext context) {
    // Create (once) a shared controller for all badges in the app.
    final ctrl = Get.put(
      CartBadgeController(),
      tag: 'cart-badge',
      permanent: true,
    );

    return Obx(() {
      final c = ctrl.count.value;
      if (c <= 0) return const SizedBox.shrink();
      return _Bubble(count: c);
    });
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
