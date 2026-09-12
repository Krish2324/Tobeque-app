import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/data/network/network_api_sarvices.dart';
import 'package:tobeque/view/prodduct_details/product_api_repo.dart';
import 'package:tobeque/view/cart/cart_events.dart';
import 'package:tobeque/view/cart/cart_service.dart';

class CartController extends GetxController {
  CartController(this._events);

  final CartEvents _events;

  // deps
  late final ProductApi api;
  final popular = <Map<String, dynamic>>[].obs;

  // state
  final loading = true.obs;
  final mutating = false.obs;
  final error = RxnString();
  final cart = Rxn<Map<String, dynamic>>();

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

  Future<void> fetchPopular() async {
    try {
      final res = await api.net.getApi(
        '${ApiConstant.products}?status=published&limit=12',
      );
      List list = [];
      if (res is Map) {
        if (res['data'] is Map && res['data']['products'] is List) {
          list = res['data']['products'];
        } else if (res['products'] is List) {
          list = res['products'];
        }
      } else if (res is List) {
        list = res;
      }
      popular.assignAll(
        list.whereType<Map>().map((m) => m.cast<String, dynamic>()),
      );
    } catch (_) {}
  }

  String formatPrice(String raw) {
    double value = 0;
    try {
      final clean = raw.replaceAll(RegExp(r'[^0-9.]'), '');
      value = double.tryParse(clean) ?? 0;
    } catch (_) {
      value = 0;
    }
    return '₹${NumberFormat.decimalPattern('en_IN').format(value.round())}';
  }
  
  Future<void> fetchCart() async {
    try {
      loading.value = true;
      error.value = null;

      final cartService = Get.isRegistered<CartService>()
          ? Get.find<CartService>()
          : Get.put(CartService(), permanent: true);

      final localItems = cartService.items.map((i) => {
        'key': i.cartId,
        'id': i.productId,
        'product_id': i.productId,
        'name': i.name,
        'price': i.price,
        'quantity': i.quantity,
        'image': i.image,
        'selectedSize': i.selectedSize,
        'selectedColor': i.selectedColor,
        'thumbnail': i.image,
        'attributes': [
          if (i.selectedSize != null) {'name': 'Size', 'option': i.selectedSize},
          if (i.selectedColor != null) {'name': 'Color', 'option': i.selectedColor},
        ]
      }).toList();

      final total = cartService.totalPrice;
      cart.value = {
        'items': localItems,
        'items_count': cartService.count,
        'totals': {
          'total_price': total,
          'total_price_rendered': '₹${NumberFormat.decimalPattern('en_IN').format(total.round())}',
          'items_total_rendered': '₹${NumberFormat.decimalPattern('en_IN').format(total.round())}',
        }
      };
    } catch (e) {
      cart.value = {'items': []};
      error.value = null;
    } finally {
      loading.value = false;
    }
  }

  // ---------- Totals ----------
  String cartSubtotal() {
    final totals = (cart.value?['totals'] as Map?)?.cast<String, dynamic>();
    if (totals == null) return '₹0';
    return totals['items_total_rendered']?.toString() ?? '₹0';
  }

  String cartTotal() {
    final totals = (cart.value?['totals'] as Map?)?.cast<String, dynamic>();
    if (totals == null) return '₹0';
    return totals['total_price_rendered']?.toString() ?? '₹0';
  }

  // ---------- Mutations ----------
  Future<void> incQty(Map item) async {
    final key = item['key']?.toString();
    final q = (item['quantity'] as num?)?.toInt() ?? 1;
    if (key == null) return;
    _setQty(key, q + 1);
  }

  Future<void> decQty(Map item) async {
    final key = item['key']?.toString();
    final q = (item['quantity'] as num?)?.toInt() ?? 1;
    if (key == null) return;
    if (q <= 1) return;
    _setQty(key, q - 1);
  }

  void _setQty(String key, int qty) {
    if (Get.isRegistered<CartService>()) {
      Get.find<CartService>().updateQuantity(key, qty);
      fetchCart();
    }
  }

  Future<void> removeItem(Map item) async {
    final key = item['key']?.toString();
    if (key == null) return;
    if (Get.isRegistered<CartService>()) {
      Get.find<CartService>().removeItem(key);
      fetchCart();
    }
  }

  Future<void> clearCart() async {
    if (Get.isRegistered<CartService>()) {
      Get.find<CartService>().clear();
      fetchCart();
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
