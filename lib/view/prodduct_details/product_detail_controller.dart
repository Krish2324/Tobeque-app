import 'dart:math' as math;
import 'package:tobeque/view/root/bage_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:tobeque/data/network/network_api_sarvices.dart';
import 'package:tobeque/view/prodduct_details/product_api_repo.dart';
import 'package:tobeque/view/cart/cart_events.dart';
 // for CartBadgeController.refreshNow()

class ProductDetailController extends GetxController {
  ProductDetailController(this.productId);
  final int productId;
final descExpanded = false.obs;
  final pageCtrl = PageController();
  late final ProductApi api;

  // state
  final loading = true.obs;
  final error = RxnString();
  final product = Rxn<Map<String, dynamic>>();
  final related = <Map<String, dynamic>>[].obs;

  // gallery
  final page = 0.obs;

  // picks
  final qty = 1.obs;
  final sizeSlug = RxnString();
  final sizeLabel = RxnString();
  final colorSlug = RxnString();
  final colorLabel = RxnString();

  // cached options
  List<Map<String, String>> sizeOptions = [];
  List<Map<String, String>> colorOptions = [];

  // add-to-cart guard
  final adding = false.obs;

  @override
  void onInit() {
    api = ProductApi(NetworkApi());
    _load();
    super.onInit();
  }

  Future<void> _load() async {
    try {
      loading.value = true;
      error.value = null;

      final p = await api.fetchProduct(productId);
      final rel = await api.fetchRelatedByFirstCategory(
        productId: productId,
        cats: (p['categories'] as List?) ?? const [],
        perPage: 12,
      );

      product.value = p;
      related.assignAll(rel);

      sizeOptions  = _extractOptions(p, wantsSlug: 'pa_size',  nameContains: 'size');
      colorOptions = _extractOptions(p, wantsSlug: 'pa_color', nameContains: 'color');
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> refreshNow() => _load();

  // ---------- UI helpers ----------
  String priceText(Map<String, dynamic>? prices) {
    if (prices == null) return '';
    final raw = prices['price']?.toString() ?? '';
    if (raw.isEmpty) return '';
    final minor = (prices['currency_minor_unit'] is int) ? prices['currency_minor_unit'] as int : 2;
    final sym = prices['currency_symbol']?.toString() ?? '₹';
    final value = (double.tryParse(raw) ?? 0) / math.pow(10, minor);
    return "$sym${NumberFormat.decimalPattern().format(value)}";
  }

  String? pickImage(Map p) {
    final imgs = (p['images'] as List?) ?? const [];
    if (imgs.isEmpty) return null;
    final first = (imgs.first as Map);
    return (first['src']?.toString() ?? first['thumbnail']?.toString());
  }

  List<Map<String, String>> _extractOptions(
    Map<String, dynamic> p, {
    required String wantsSlug,
    String? nameContains,
  }) {
    final attrs = (p['attributes'] as List?) ?? const [];
    Map? target;

    for (final a in attrs) {
      final m = (a as Map);
      final tax = (m['taxonomy'] ?? m['name'] ?? '').toString().toLowerCase();
      if (tax == wantsSlug.toLowerCase()) { target = m; break; }
    }
    if (target == null && nameContains != null) {
      for (final a in attrs) {
        final m = (a as Map);
        final nm = (m['name'] ?? '').toString().toLowerCase();
        if (nm.contains(nameContains.toLowerCase())) { target = m; break; }
      }
    }
    if (target == null) return const [];
    final terms = (target['terms'] as List?) ?? const [];
    return terms.map<Map<String, String>>((t) {
      final tm = (t as Map);
      final label = tm['name']?.toString() ?? '';
      final slug  = (tm['slug']?.toString() ?? label.toLowerCase()).trim();
      return {'label': label, 'slug': slug};
    }).where((e) => e['label']!.isNotEmpty && e['slug']!.isNotEmpty).toList();
  }

  // ---------- variation resolution ----------
  int? _findVariationId(Map<String, dynamic> p, Map<String, String> selected) {
    final varsRaw = (p['variations'] as List?) ?? const [];
    if (varsRaw.isEmpty) return null;
    if (varsRaw.first is int) return null; // server will match via attrs

    for (final v in varsRaw.cast<Map>()) {
      final attrs = (v['attributes'] as List?)?.cast<Map>() ?? const [];
      bool allMatch = true;
      for (final entry in selected.entries) {
        final wantKey = entry.key.toLowerCase();
        final wantVal = entry.value.toLowerCase();
        final ok = attrs.any((a) {
          final nm  = (a['name']?.toString() ?? '').toLowerCase();
          final opt = (a['option']?.toString() ?? a['value']?.toString() ?? '').toLowerCase();
          return nm.endsWith(wantKey) && opt == wantVal;
        });
        if (!ok) { allMatch = false; break; }
      }
      if (allMatch) return (v['id'] as num).toInt();
    }
    return null;
  }

  Map<String, String> _currentAttributes() {
    final map = <String, String>{};
    if (sizeSlug.value != null && sizeSlug.value!.isNotEmpty) {
      map['pa_size'] = sizeSlug.value!;
    }
    if (colorSlug.value != null && colorSlug.value!.isNotEmpty) {
      map['pa_color'] = colorSlug.value!;
    }
    return map;
  }

  bool _needsAttr(String slug) {
    final p = product.value;
    if (p == null) return false;
    final attrs = (p['attributes'] as List?) ?? const [];
    for (final a in attrs.cast<Map>()) {
      final tax = (a['taxonomy'] ?? a['name'] ?? '').toString().toLowerCase();
      final vis = (a['visible'] == true);
      final varAttr = (a['variation'] == true); // only variation attributes are required
      if (tax == slug.toLowerCase() && varAttr) return true;
      if (tax.isEmpty && vis && varAttr && slug == 'pa_size' &&
          ((a['name'] ?? '').toString().toLowerCase().contains('size'))) return true;
      if (tax.isEmpty && vis && varAttr && slug == 'pa_color' &&
          ((a['name'] ?? '').toString().toLowerCase().contains('color'))) return true;
    }
    return false;
  }

  // ---------- actions ----------

  /// One-tap helper for the UI: reads current picks, validates, and adds to cart.
  Future<void> addCurrentSelectionToCart(BuildContext context) async {
    final attrs = _currentAttributes();
    final p = product.value;

    // Validate required attributes for variable products
    if (p != null && (p['type']?.toString() == 'variable')) {
      if (_needsAttr('pa_size') && !attrs.containsKey('pa_size')) {
        _toast(context, 'Please select a size');
        return;
      }
      if (_needsAttr('pa_color') && !attrs.containsKey('pa_color')) {
        _toast(context, 'Please select a color');
        return;
      }
    }

    // Resolve variation id if possible (optional; server can also match)
    int? varId;
    if (p != null) {
      varId = _findVariationId(p, attrs);
    }

    await addToCart(
      context: context,
      productId: productId,
      quantity: qty.value.clamp(1, 999),
      attributes: attrs,
      variationId: varId,
    );
  }

 Future<bool> addToCart({
  required BuildContext context,
  required int productId,
  required int quantity,
  required Map<String, String> attributes,
  int? variationId,
}) async {
  if (adding.value) return false;
  adding.value = true;

  final events = Get.isRegistered<CartEvents>()
      ? Get.find<CartEvents>()
      : Get.put(CartEvents(), permanent: true);

  // optimistic bump
  final oldCount = events.count.value;
  final inc = (quantity <= 0 ? 1 : quantity);
  events.setCount((oldCount + inc).clamp(0, 9999));

  try {
    // --- server call ---
    await api.addToCart(
      productId: productId,
      quantity: quantity,
      attributes: attributes,
      variationId: variationId,
    );

    // ✅ INSERT HERE
    events.bump(); // let listeners (cart/badge) know something changed
    if (Get.isRegistered<CartBadgeController>(tag: 'cart-badge')) {
      await Get.find<CartBadgeController>(tag: 'cart-badge').refreshNow();
    }

    // (optional) toast
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Added to bag'),
        duration: Duration(milliseconds: 1200),
      ));
    }
    return true;

  } catch (e) {
    // rollback optimistic bump
    events.setCount(oldCount);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Add to bag failed: $e'),
      ));
    }
    return false;
  } finally {
    adding.value = false;
  }
}

  // ---------- small utils ----------
  void _toast(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(msg),
      duration: const Duration(milliseconds: 1200),
    ));
  }

}