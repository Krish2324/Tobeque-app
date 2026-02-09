import 'dart:math' as math;
import 'package:tobeque/view/cart/cart_bus.dart';
import 'package:intl/intl.dart';
import 'package:tobeque/data/network/network_api_sarvices.dart';

class ProductApi {
  ProductApi(this.net);
  final NetworkApi net;

  static const String base = 'https://tobeque.com/wp-json/wc/store/v1';

  // ---------- Products ----------

  Future<Map<String, dynamic>> fetchProduct(int id) async {
    final data = await net.getApi('$base/products/$id');
    return (data as Map).cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> fetchRelatedByFirstCategory({
    required int productId,
    required List cats,
    int perPage = 12,
  }) async {
    if (cats.isEmpty) return [];
    final catId = (cats.first as Map)['id'];
    final data = await net.getApi(
      '$base/products?category=$catId&per_page=$perPage&exclude=$productId',
    );
    return (data as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
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

  /// Format Woo Store API prices: divide minor units and add symbol.
  static String formatPrice(Map<String, dynamic>? prices) {
    if (prices == null) return "";
    final raw = prices['price']?.toString() ?? '';
    if (raw.isEmpty) return "";
    final minorDigits = (prices['currency_minor_unit'] is int)
        ? prices['currency_minor_unit'] as int
        : 2;
    final sym = prices['currency_symbol']?.toString() ?? '₹';

    final numRaw = double.tryParse(raw) ?? 0;
    final value = numRaw / math.pow(10, minorDigits);

    return "$sym${NumberFormat.decimalPattern().format(value)}";
  }
}
