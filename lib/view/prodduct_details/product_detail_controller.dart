import 'dart:math' as math;
import 'package:tobeque/view/root/bage_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:tobeque/data/network/network_api_sarvices.dart';
import 'package:tobeque/view/prodduct_details/product_api_repo.dart';
import 'package:tobeque/view/cart/cart_events.dart';
import 'package:tobeque/constants/api_constants.dart';
 // for CartBadgeController.refreshNow()

class ProductDetailController extends GetxController {
  ProductDetailController(this.productId);
  final dynamic productId; // Accepts String (MongoDB _id) or int
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

  // pincode check
  final pincodeText = ''.obs;
  final pincodeMsg = RxnString();
  final pincodeOk = RxnBool();

  void checkPincode(String code) {
    final trimmed = code.trim();
    if (trimmed.length != 6 || int.tryParse(trimmed) == null) {
      pincodeOk.value = false;
      pincodeMsg.value = 'Please enter a valid 6-digit Pincode';
      return;
    }
    pincodeOk.value = true;
    final delDate = DateFormat('EEEE, MMM d').format(DateTime.now().add(const Duration(days: 4)));
    pincodeMsg.value = 'Express Delivery by $delDate to $trimmed';
  }

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
        cats: (p['categories'] as List?) ?? (p['category'] != null ? [p['category']] : const []),
        perPage: 12,
      );

      product.value = p;
      related.assignAll(rel);
      await _loadStyleItWith(p);

      sizeOptions  = _extractSizes(p);
      colorOptions = _extractColors(p);

      // Auto-select first available size
      if (sizeOptions.isNotEmpty && sizeSlug.value == null) {
        final firstInStock = sizeOptions.firstWhere(
          (s) => s['inStock'] != 'false',
          orElse: () => sizeOptions.first,
        );
        sizeSlug.value = firstInStock['slug'];
        sizeLabel.value = firstInStock['label'];
      }

      // Auto-select first color
      if (colorOptions.isNotEmpty && colorSlug.value == null) {
        colorSlug.value = colorOptions.first['slug'];
        colorLabel.value = colorOptions.first['label'];
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> refreshNow() => _load();

  // ---------- Getters for UI ----------
  List<String> get extractedImages {
    final p = product.value;
    if (p == null) return const [];
    final list = <String>[];

    final imgs = (p['images'] as List?) ?? const [];
    for (final item in imgs) {
      if (item is Map) {
        final url = (item['imageUrl'] ?? item['url'] ?? item['src'] ?? item['thumbnail'])?.toString();
        if (url != null && url.trim().isNotEmpty) {
          final fullUrl = ApiConstant.getImageUrl(url.trim());
          if (!list.contains(fullUrl)) list.add(fullUrl);
        }
      } else if (item is String && item.trim().isNotEmpty) {
        final fullUrl = ApiConstant.getImageUrl(item.trim());
        if (!list.contains(fullUrl)) list.add(fullUrl);
      }
    }

    final thumb = p['thumbnail']?.toString();
    if (thumb != null && thumb.trim().isNotEmpty) {
      final fullUrl = ApiConstant.getImageUrl(thumb.trim());
      if (!list.contains(fullUrl)) list.add(fullUrl);
    }

    final feat = p['featuredImage']?.toString();
    if (feat != null && feat.trim().isNotEmpty) {
      final fullUrl = ApiConstant.getImageUrl(feat.trim());
      if (!list.contains(fullUrl)) list.add(fullUrl);
    }

    return list;
  }

  String get formattedPrice {
    final p = product.value;
    if (p == null) return '';

    final priceNum = p['price'] ?? p['discountPrice'] ?? p['regularPrice'];
    if (priceNum != null && priceNum is num && priceNum > 0) {
      return '₹${NumberFormat.decimalPattern().format(priceNum)}';
    }

    if (p['prices'] is Map) {
      final pr = priceText(p['prices'] as Map<String, dynamic>);
      if (pr.isNotEmpty) return pr;
    }

    final html = (p['price_html'] ?? p['priceHtml'])?.toString() ?? '';
    if (html.isNotEmpty) {
      final clean = html.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
      if (clean.isNotEmpty) return clean;
    }

    return '₹0';
  }

  String get formattedRegularPrice {
    final p = product.value;
    if (p == null) return '';
    final regPrice = p['regularPrice'];
    final curPrice = p['price'] ?? p['discountPrice'];
    if (regPrice is num && curPrice is num && regPrice > curPrice) {
      return '₹${NumberFormat.decimalPattern().format(regPrice)}';
    }
    return '';
  }

  int get discountPercent {
    final p = product.value;
    if (p == null) return 0;

    if (p['discountPercentage'] is num && (p['discountPercentage'] as num) > 0) {
      return (p['discountPercentage'] as num).round();
    }

    final regPrice = p['regularPrice'];
    final curPrice = p['price'] ?? p['discountPrice'];
    if (regPrice is num && curPrice is num && regPrice > curPrice && regPrice > 0) {
      return (((regPrice - curPrice) / regPrice) * 100).round();
    }
    return 0;
  }

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
    final url = (first['imageUrl'] ?? first['url'] ?? first['src'] ?? first['thumbnail'])?.toString();
    return ApiConstant.getImageUrl(url);
  }

  final styleItWithProducts = <Map<String, dynamic>>[].obs;

  Future<void> _loadStyleItWith(Map<String, dynamic> p) async {
    final raw = p['styleItWith'];
    if (raw is List && raw.isNotEmpty) {
      final list = <Map<String, dynamic>>[];
      for (final item in raw) {
        if (item is Map) {
          list.add((item).cast<String, dynamic>());
        } else if (item is String && item.isNotEmpty) {
          try {
            final fetched = await api.fetchProduct(item);
            if (fetched.isNotEmpty) list.add(fetched);
          } catch (_) {}
        }
      }
      if (list.isNotEmpty) {
        styleItWithProducts.assignAll(list);
        return;
      }
    }
    // Fallback: use first few items from related for "STYLE IT WITH"
    if (related.length >= 2) {
      styleItWithProducts.assignAll(related.take(4).toList());
    }
  }

  List<Map<String, String>> _extractSizes(Map<String, dynamic> p) {
    final list = <Map<String, String>>[];
    final seen = <String>{};

    final vars = (p['variants'] as List?) ?? const [];
    if (vars.isNotEmpty) {
      for (final v in vars) {
        if (v is Map) {
          final sz = (v['size'] ?? v['name'])?.toString().trim();
          if (sz != null && sz.isNotEmpty) {
            final slug = sz.toLowerCase();
            if (!seen.contains(slug)) {
              seen.add(slug);
              final stock = (v['stock'] ?? v['stockQuantity'] ?? 1);
              final inStock = stock is num ? stock > 0 : true;
              list.add({
                'label': sz.toUpperCase(),
                'slug': slug,
                'inStock': inStock ? 'true' : 'false',
              });
            }
          }
        }
      }
      if (list.isNotEmpty) return list;
    }

    final fromAttrs = _extractOptions(p, wantsSlug: 'pa_size', nameContains: 'size');
    if (fromAttrs.isNotEmpty) {
      for (final e in fromAttrs) {
        final slug = (e['slug'] ?? '').toLowerCase();
        if (slug.isNotEmpty && !seen.contains(slug)) {
          seen.add(slug);
          list.add({
            'label': (e['label'] ?? '').toUpperCase(),
            'slug': slug,
            'inStock': 'true',
          });
        }
      }
      return list;
    }

    return const [];
  }

  List<Map<String, String>> _extractColors(Map<String, dynamic> p) {
    final list = <Map<String, String>>[];
    final seen = <String>{};

    final cols = (p['colors'] as List?) ?? (p['colorSwatches'] as List?) ?? const [];
    if (cols.isNotEmpty) {
      for (final c in cols) {
        final label = c is Map ? (c['name'] ?? c['color'])?.toString() : c.toString();
        if (label != null && label.trim().isNotEmpty) {
          final slug = label.trim().toLowerCase();
          if (!seen.contains(slug)) {
            seen.add(slug);
            list.add({
              'label': label.trim(),
              'slug': slug,
            });
          }
        }
      }
      if (list.isNotEmpty) return list;
    }

    final imgs = (p['images'] as List?) ?? const [];
    for (final item in imgs) {
      if (item is Map && item['color'] != null) {
        final c = item['color'].toString().trim();
        if (c.isNotEmpty) {
          final slug = c.toLowerCase();
          if (!seen.contains(slug)) {
            seen.add(slug);
            list.add({
              'label': c,
              'slug': slug,
            });
          }
        }
      }
    }
    if (list.isNotEmpty) return list;

    final fromAttrs = _extractOptions(p, wantsSlug: 'pa_color', nameContains: 'color');
    for (final e in fromAttrs) {
      final slug = (e['slug'] ?? '').toLowerCase();
      if (slug.isNotEmpty && !seen.contains(slug)) {
        seen.add(slug);
        list.add({
          'label': e['label'] ?? '',
          'slug': slug,
        });
      }
    }

    return list;
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