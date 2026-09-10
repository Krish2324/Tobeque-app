// lib/view/cart/cart_controller.dart
import 'package:tobeque/view/cart/cart_events.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';


import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/data/network/network_api_sarvices.dart';
import 'package:tobeque/view/prodduct_details/product_api_repo.dart';

class CartController extends GetxController {
  CartController(this._events);

  final CartEvents _events;

  // deps
  late final ProductApi api;
final popular = <Map<String, dynamic>>[].obs;
  // state
  final loading = true.obs;        // only for first load / pull-to-refresh
  final mutating = false.obs;      // 👈 NEW: short overlay for updates
  final error = RxnString();
  final cart = Rxn<Map<String, dynamic>>();
 bool _pending = false;
  List get items => (cart.value?['items'] as List?) ?? const [];
List<Map<String, dynamic>> get popularNotInCart {
  final inCartNames = items
      .map((i) => (i['name'] ?? '').toString().toLowerCase().trim())
      .toSet();
  return popular
      .where((p) => !inCartNames.contains(
          (p['name'] ?? '').toString().toLowerCase().trim()))
      .toList();
}
  @override
  void onInit() {
    super.onInit();
    api = ProductApi(NetworkApi());
    fetchCart();
    ever<int>(_events.version, (_) => fetchCart());
     fetchPopular();
  }



  // CartController.dart (add method)
Future<void> fetchPopular() async {
  try {
    final res = await api.net.getApi(
      '${ApiConstant.products}?status=published&limit=12',
    );
    List list = [];
    if (res is Map && res['products'] is List) {
      list = res['products'];
    } else if (res is List) {
      list = res;
    }
    popular.assignAll(
      list.whereType<Map>().map((m) => m.cast<String, dynamic>()),
    );
  } catch (_) {
    // ignore silently – cart still works even if popular fails
  }
}

 /// Format raw price (in paise or cents, integer) to ₹X,XXX style
String formatPrice(String raw) {
  // Extract digits (handles "1,234", "₹1234", etc.)
  int minor;
  try {
    minor = int.parse(raw.replaceAll(RegExp(r'[^\d-]'), '')); // keep minus just in case
  } catch (_) {
    minor = 0;
  }

  // Assume 2 minor units (paise/cents)
  final isZeroCents = minor % 100 == 0;
  final rupees = minor ~/ 100;
  final value  = minor / 100.0;

  if (isZeroCents) {
    // No decimals (₹4,500)
    final whole = NumberFormat.decimalPattern('en_IN').format(rupees);
    return '₹$whole';
  } else {
    // Keep two decimals (₹4,500.50)
    final withCents = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(value);
    return withCents;
  }
}
  
  Future<void> fetchCart() async {
    try {
      loading.value = true;
      error.value = null;
      final c = await api.fetchCart();
      cart.value = c;
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  // ---------- Totals ----------
  String cartSubtotal() {
    final totals = (cart.value?['totals'] as Map?)?.cast<String, dynamic>();
    if (totals == null) return '';
    return totals['items_total_rendered']?.toString() ??
        totals['total_items']?.toString() ??
        '';
  }

  String cartTotal() {
    final totals = (cart.value?['totals'] as Map?)?.cast<String, dynamic>();
    if (totals == null) return '';
    return totals['total_price_rendered']?.toString() ??
        totals['total_price']?.toString() ??
        '';
  }

  // ---------- Mutations ----------
  Future<void> incQty(Map item) async {
    final key = item['key']?.toString();
    final q = (item['quantity'] as num?)?.toInt() ?? 1;
    if (key == null) return;
    await _setQty(key, q + 1);
  }

  Future<void> decQty(Map item) async {
    final key = item['key']?.toString();
    final q = (item['quantity'] as num?)?.toInt() ?? 1;
    if (key == null) return;
    if (q <= 1) return;
    await _setQty(key, q - 1);
  }

  Future<void> _setQty(String key, int qty) async {
    try {
      mutating.value = true;                         // 👈 show blur
      final c = await api.updateCartQty(itemKey: key, quantity: qty);
      cart.value = c;
      _events.bump();                                // notify others
    } catch (e) {
      Get.snackbar('Cart', 'Failed to update quantity: $e');
    } finally {
      mutating.value = false;                        // 👈 hide blur
    }
  }

  Future<void> removeItem(Map item) async {
    final key = item['key']?.toString();
    if (key == null) return;
    try {
      mutating.value = true;                         // 👈 show blur
      final c = await api.removeCartItem(key);
      cart.value = c;
      _events.bump();
    } catch (e) {
      print(e);
      Get.snackbar('Cart', 'Failed to remove item: $e');
    } finally {
      mutating.value = false;                        // 👈 hide blur
    }
  }

  Future<void> clearCart() async {
    try {
      mutating.value = true;                         // 👈 show blur
      final c = await api.clearCart();
      cart.value = c;
      _events.bump();
    } catch (e) {
      Get.snackbar('Cart', 'Failed to clear cart: $e');
    } finally {
      mutating.value = false;                        // 👈 hide blur
    }
  }

  

  // ---------- Helpers ----------
  String? pickCartImage(Map<String, dynamic> item) {
    final imgs = (item['images'] as List?) ?? const [];
    if (imgs.isNotEmpty) {
      final m = (imgs.first as Map).cast<String, dynamic>();
      final src = m['src']?.toString();
      if (src != null && src.isNotEmpty) return src;
      final thumb = m['thumbnail']?.toString();
      if (thumb != null && thumb.isNotEmpty) return thumb;
    }
    final thumb = item['thumbnail']?.toString();
    if (thumb != null && thumb.isNotEmpty) return thumb;
    final feat = item['featured_image']?.toString();
    if (feat != null && feat.isNotEmpty) return feat;
    return null;
  }

  Future<int?> resolveProductId(Map<String, dynamic> item) async {
    final pid = item['product_id'];
    if (pid is int) return pid;
    final parentId = item['parent_id'];
    if (parentId is int) return parentId;

    final link = item['permalink']?.toString();
    if (link == null || link.isEmpty) return null;
    final uri = Uri.tryParse(link);
    if (uri == null) return null;

    String? slug;
    for (var i = uri.pathSegments.length - 1; i >= 0; i--) {
      final seg = uri.pathSegments[i].trim();
      if (seg.isNotEmpty && seg != 'product') {
        slug = seg;
        break;
      }
    }
    if (slug == null) return null;

    final list = await api.net.getApi('products?slug=$slug');
    if (list is List && list.isNotEmpty) {
      final id = (list.first as Map)['id'];
      if (id is int) return id;
    }
    return null;
  }

  String titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
