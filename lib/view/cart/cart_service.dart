import 'dart:convert';
import 'package:get/get.dart';
import 'package:tobeque/services/shared_pref.dart';
import 'package:tobeque/view/cart/cart_events.dart';

class LocalCartItem {
  final String cartId;
  final String productId;
  final String name;
  final dynamic price;
  final String? image;
  final String? selectedSize;
  final String? selectedColor;
  int quantity;

  LocalCartItem({
    required this.cartId,
    required this.productId,
    required this.name,
    required this.price,
    this.image,
    this.selectedSize,
    this.selectedColor,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
    'cartId': cartId,
    'productId': productId,
    'name': name,
    'price': price,
    'image': image,
    'selectedSize': selectedSize,
    'selectedColor': selectedColor,
    'quantity': quantity,
  };

  factory LocalCartItem.fromJson(Map<String, dynamic> m) => LocalCartItem(
    cartId: (m['cartId'] ?? '').toString(),
    productId: (m['productId'] ?? m['id'] ?? m['_id'] ?? '').toString(),
    name: (m['name'] ?? '').toString(),
    price: m['price'],
    image: m['image']?.toString(),
    selectedSize: m['selectedSize']?.toString(),
    selectedColor: m['selectedColor']?.toString(),
    quantity: (m['quantity'] as num?)?.toInt() ?? 1,
  );
}

class CartService extends GetxService {
  static const _kKey = 'tobeque_cart_items_v2';

  final items = <LocalCartItem>[].obs;

  int get count => items.fold(0, (sum, i) => sum + i.quantity);

  double get totalPrice {
    double total = 0;
    for (final item in items) {
      final pStr = item.price.toString().replaceAll(RegExp(r'[^0-9.]'), '');
      final pNum = double.tryParse(pStr) ?? 0;
      total += pNum * item.quantity;
    }
    return total;
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    await restoreCart();
  }

  Future<void> persistCart() async {
    final list = items.map((e) => e.toJson()).toList();
    await SharedPrefService.setString(_kKey, json.encode(list));
    if (Get.isRegistered<CartEvents>()) {
      final ev = Get.find<CartEvents>();
      ev.setCount(count);
      ev.bump();
    }
  }

  Future<void> restoreCart() async {
    final raw = await SharedPrefService.getString(_kKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = json.decode(raw);
      if (decoded is List) {
        final list = <LocalCartItem>[];
        for (final x in decoded) {
          if (x is Map) {
            list.add(LocalCartItem.fromJson((x).cast<String, dynamic>()));
          }
        }
        items.assignAll(list);
      }
    } catch (_) {}
  }

  void addItem({
    required String productId,
    required String name,
    required dynamic price,
    String? image,
    String? selectedSize,
    String? selectedColor,
    int quantity = 1,
  }) {
    final index = items.indexWhere((i) =>
      i.productId == productId &&
      (i.selectedSize ?? '') == (selectedSize ?? '') &&
      (i.selectedColor ?? '') == (selectedColor ?? '')
    );

    if (index >= 0) {
      items[index].quantity += quantity;
      items.refresh();
    } else {
      final cartId = '$productId-${DateTime.now().millisecondsSinceEpoch}';
      items.add(LocalCartItem(
        cartId: cartId,
        productId: productId,
        name: name,
        price: price,
        image: image,
        selectedSize: selectedSize,
        selectedColor: selectedColor,
        quantity: quantity,
      ));
    }
    persistCart();
  }

  void updateQuantity(String cartId, int quantity) {
    if (quantity <= 0) {
      removeItem(cartId);
      return;
    }
    final index = items.indexWhere((i) => i.cartId == cartId);
    if (index >= 0) {
      items[index].quantity = quantity;
      items.refresh();
      persistCart();
    }
  }

  void removeItem(String cartId) {
    items.removeWhere((i) => i.cartId == cartId);
    persistCart();
  }

  void clear() {
    items.clear();
    persistCart();
  }
}
