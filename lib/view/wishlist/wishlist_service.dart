import 'dart:convert';
import 'package:get/get.dart';
import 'package:tobeque/services/shared_pref.dart';

class WishItem {
  final String id; // MongoDB _id string
  final String name;
  final String? priceHtml;
  final String? image;

  WishItem({required this.id, required this.name, this.priceHtml, this.image});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'priceHtml': priceHtml,
    'image': image,
  };

  factory WishItem.fromJson(Map<String, dynamic> m) => WishItem(
    id: (m['id'] ?? m['_id'] ?? '').toString(),
    name: (m['name'] ?? '').toString(),
    priceHtml: m['priceHtml']?.toString(),
    image: m['image']?.toString(),
  );
}

class WishlistService extends GetxService {
  static const _kKey = 'wishlist_items_v2'; // v2 key since id type changed

  /// Map of productId -> WishItem (reactive)
  final items = <String, WishItem>{}.obs;

  int get count => items.length;

  bool isIn(String id) => items.containsKey(id);

  Future<void> onInit() async {
    super.onInit();
    await _restore();
  }

  Future<void> _persist() async {
    final list = items.values.map((e) => e.toJson()).toList();
    await SharedPrefService.setString(_kKey, json.encode(list));
  }

  Future<void> _restore() async {
    final raw = await SharedPrefService.getString(_kKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = json.decode(raw);
      if (decoded is List) {
        for (final x in decoded) {
          final m = (x as Map).cast<String, dynamic>();
          final wi = WishItem.fromJson(m);
          if (wi.id.isNotEmpty) items[wi.id] = wi;
        }
      }
    } catch (_) {}
  }

  void add(WishItem wi) {
    items[wi.id] = wi;
    _persist();
  }

  void remove(String id) {
    items.remove(id);
    _persist();
  }

  void toggle(WishItem wi) {
    if (items.containsKey(wi.id)) {
      items.remove(wi.id);
    } else {
      items[wi.id] = wi;
    }
    _persist();
  }

  void clear() {
    items.clear();
    _persist();
  }
}
