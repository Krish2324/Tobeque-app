// lib/view/cart/cart_events.dart
import 'package:tobeque/view/prodduct_details/product_api_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Tiny event bus to notify cart updates from anywhere.
class CartEvents extends GetxService {
  final version = 0.obs;   // bump when cart changes
  final count   = 0.obs;   // total items in cart (sum of quantities)

  void bump() => version.value++;
  void setCount(int c) => count.value = c;
  // lib/view/common/add_to_cart_and_notify.dart

/// Add to cart using your ProductApi, then notify CartEvents so
/// other screens (badge, cart screen) refresh without showing a spinner.
///
/// Usage:
/// await addToCartAndNotify(
///   api: ProductApi(NetworkApi()),
///   context: context,
///   productId: 22113,
///   quantity: 1,
///   attributes: {'pa_size': 'm', 'pa_color': 'yellow'},
///   variationId: 22114, // optional
/// );
Future<void> addToCartAndNotify({
  required ProductApi api,
  required BuildContext context,
  required int productId,
  required int quantity,
  required Map<String, String> attributes,
  int? variationId,
  String? successMessage,
}) async {
  // Optional: optimistic badge increment. If you don't want this, delete this block.
  CartEvents? events =
      Get.isRegistered<CartEvents>() ? Get.find<CartEvents>() : null;
  // If you implemented CartEvents.count/setCount as in my previous message:
  final hadCountField = events != null;
  if (hadCountField) {
    // optimistic tick up; will be reconciled by bump() fetch
    events.setCount(events.count.value + quantity);
  }

  try {
    await api.addToCart(
      productId: productId,
      quantity: quantity,
      attributes: attributes,
      variationId: variationId,
    );

    // Tell the app “cart changed” → silent refresh on listeners (badge/cart).
    if (events != null) events.bump();

    // Small success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage ?? 'Added to cart'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e) {
    // Rollback optimistic badge if you enabled it
    if (hadCountField) {
      events.setCount((events.count.value - quantity).clamp(0, 1 << 31));
    }
    // Error feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Add to cart failed: $e'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    rethrow;
  }
}

}
