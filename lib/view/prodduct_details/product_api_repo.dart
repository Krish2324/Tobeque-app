import 'dart:math' as math;
import 'package:tobeque/view/cart/cart_bus.dart';
import 'package:intl/intl.dart';
import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/data/network/network_api_sarvices.dart';

class ProductApi {
  ProductApi(this.net);
  final NetworkApi net;

  // ---------- Products ----------

  Future<Map<String, dynamic>> fetchProduct(dynamic id) async {
    final data = await net.getApi('${ApiConstant.products}/$id');
    if (data is Map && data['product'] != null) {
      return (data['product'] as Map).cast<String, dynamic>();
    }
    return (data as Map).cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> fetchRelatedByFirstCategory({
    required dynamic productId,
    required List cats,
    int perPage = 12,
  }) async {
    try {
      final data = await net.getApi('${ApiConstant.products}?status=published&limit=$perPage');
      List rawList = [];
      if (data is List) {
        rawList = data;
      } else if (data is Map) {
        if (data['data'] is Map && data['data']['products'] is List) {
          rawList = data['data']['products'] as List;
        } else if (data['data'] is List) {
          rawList = data['data'] as List;
        } else if (data['products'] is List) {
          rawList = data['products'] as List;
        }
      }
      
      if (rawList.isNotEmpty) {
        return rawList
            .map((e) => (e as Map).cast<String, dynamic>())
            .where((p) => p['_id']?.toString() != productId.toString() && p['id']?.toString() != productId.toString())
            .toList();
      }
    } catch (e) {
      // Return empty list on failure
    }
    return [];
  }

  /// Add to cart (Store API; NetworkApi will fallback to wc-ajax if needed).

// ... inside ProductApi

Future<void> addToCart({
  required int productId,
  required int quantity,
  Map<String, String> attributes = const {},
  int? variationId,
}) async {
  final variation = attributes.entries
      .map((e) => {'attribute': e.key, 'value': e.value})
      .toList();

  final body = <String, dynamic>{
    'id': variationId ?? productId,
    'parent_id': productId,
    'product_id': productId,
    'quantity': quantity,
    if (variation.isNotEmpty) 'variation': variation,
    if (variationId != null) 'variation_id': variationId,
  };

  await net.postApi(body, 'cart/add-item');
  CartBus.I.bump(); // <- notify listeners
}

Future<Map<String, dynamic>> updateCartQty({
  required String itemKey,
  required int quantity,
}) async {
  final data = await net.putApi({'quantity': quantity}, 'cart/items/$itemKey');
  CartBus.I.bump();
  return (data as Map).cast<String, dynamic>();
}

Future<Map<String, dynamic>> removeCartItem(String key) async {
    // Store API may return 204 (no body) or 200 with the cart body.
    final res = await net.delete(null, 'cart/items/$key');

    if (res is Map) {
      return res.cast<String, dynamic>();
    }

    // If no content, fetch the latest cart snapshot.
    final cart = await net.getApi('cart');
    return (cart as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> clearCart() async {
    // Some setups return 204 for clear too.
    final res = await net.delete(null, 'cart/items');
    if (res is Map) return res.cast<String, dynamic>();
    final cart = await net.getApi('cart');
    return (cart as Map).cast<String, dynamic>();
  }

  // ---------- Cart ----------

  Future<Map<String, dynamic>> fetchCart() async {
    final data = await net.getApi('cart'); // GET /cart
    return (data as Map).cast<String, dynamic>();
  }

  // ---------- Helpers ----------

  static String formatPrice(dynamic priceVal) {
    if (priceVal == null) return "₹0";
    if (priceVal is Map) {
      final p = priceVal['price'] ?? priceVal['regularPrice'] ?? priceVal['value'];
      return formatPrice(p);
    }
    final numVal = double.tryParse(priceVal.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    return "₹${numVal.toStringAsFixed(0)}";
  }
}
