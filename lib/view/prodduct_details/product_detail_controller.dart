import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:tobeque/data/network/network_api_sarvices.dart';
import 'package:tobeque/view/prodduct_details/product_api_repo.dart';
import 'package:tobeque/view/cart/cart_service.dart';
import 'package:tobeque/view/checkout/checkout_screen.dart';
import 'package:tobeque/constants/api_constants.dart';
 // for CartBadgeController.refreshNow()

class ProductDetailController extends GetxController {
  ProductDetailController(this.productId);
  final dynamic productId; // Accepts String (MongoDB _id) or int
  final descExpanded = false.obs;
  final shippingExpanded = false.obs;
  final pageCtrl = PageController();
  late final ProductApi api;

  // state
  final loading = true.obs;
  final error = RxnString();
  final product = Rxn<Map<String, dynamic>>();
  final related = <Map<String, dynamic>>[].obs;

  // gallery
  final page = 0.obs;
  
  /// The thumbnail URL known from the listing page. Shown as image[0] so the
  /// user always sees the same image they tapped on the home/category page.
  String? hintImageUrl;

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

    ever(colorSlug, (String? slug) {
      if (pageCtrl.hasClients) {
        pageCtrl.jumpToPage(0);
        page.value = 0;
      }
    });
  }

  Future<void> _load() async {
    try {
      loading.value = true;
      error.value = null;

      final p = await api.fetchProduct(productId);
      product.value = p;

      final rel = await api.fetchRelatedByFirstCategory(
        productId: productId,
        cats: (p['categories'] as List?) ?? (p['category'] != null ? [p['category']] : const []),
        perPage: 20,
      );

      await _loadStyleItWithAndRelated(p, rel);

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
    
    final currentSlug = colorSlug.value;
    final allUrls = <String>[];
    final matchingUrls = <String>[];

    // 1. Always put the hint image (from the listing page) first so the user
    //    sees the same image they tapped — even before other images load.
    final hint = hintImageUrl?.trim();
    if (hint != null && hint.isNotEmpty) {
      final fullHint = ApiConstant.getImageUrl(hint);
      if (fullHint.isNotEmpty) {
        if (!allUrls.contains(fullHint)) allUrls.add(fullHint);
        if (!matchingUrls.contains(fullHint)) matchingUrls.add(fullHint);
      }
    }

    final thumb = (p['thumbnail'] ?? p['thumbnailImage'] ?? p['featuredImage'] ?? p['image'])?.toString();
    if (thumb != null && thumb.trim().isNotEmpty) {
      final fullUrl = ApiConstant.getImageUrl(thumb.trim());
      if (fullUrl.isNotEmpty && !allUrls.contains(fullUrl)) {
        allUrls.add(fullUrl);
      }
    }

    final imgs = (p['images'] as List?) ?? const [];
    for (final item in imgs) {
      if (item is Map) {
        final url = (item['imageUrl'] ?? item['url'] ?? item['src'] ?? item['thumbnail'])?.toString();
        if (url != null && url.trim().isNotEmpty) {
          final fullUrl = ApiConstant.getImageUrl(url.trim());
          if (fullUrl.isNotEmpty) {
            if (!allUrls.contains(fullUrl)) allUrls.add(fullUrl);
            
            if (currentSlug != null) {
              final c = item['color']?.toString().toLowerCase() ?? '';
              final alt = item['alt']?.toString().toLowerCase() ?? '';
              final n = item['name']?.toString().toLowerCase() ?? '';
              if (c == currentSlug || alt == currentSlug || n == currentSlug) {
                if (!matchingUrls.contains(fullUrl)) matchingUrls.add(fullUrl);
              }
            }
          }
        }
      } else if (item is String && item.trim().isNotEmpty) {
        final fullUrl = ApiConstant.getImageUrl(item.trim());
        if (fullUrl.isNotEmpty && !allUrls.contains(fullUrl)) {
          allUrls.add(fullUrl);
        }
      }
    }

    final vars = (p['variants'] as List?) ?? (p['variations'] as List?) ?? const [];
    for (final v in vars) {
      if (v is Map) {
        final url = (v['image'] ?? v['imageUrl'] ?? v['thumbnail'])?.toString();
        if (url != null && url.trim().isNotEmpty) {
           final fullUrl = ApiConstant.getImageUrl(url.trim());
           if (fullUrl.isNotEmpty) {
             if (!allUrls.contains(fullUrl)) allUrls.add(fullUrl);
             
             if (currentSlug != null) {
               final vc = (v['color'] ?? v['attributes']?['color'] ?? v['attributes']?['pa_color'])?.toString().toLowerCase() ?? '';
               if (vc == currentSlug) {
                 if (!matchingUrls.contains(fullUrl)) matchingUrls.add(fullUrl);
               }
             }
           }
        }
      }
    }

    return matchingUrls.isNotEmpty ? matchingUrls : allUrls;
  }

  String get formattedPrice {
    final p = product.value;
    if (p == null) return '';

    final priceNum = p['price'] ?? p['discountPrice'] ?? p['regularPrice'];
    if (priceNum != null && priceNum is num && priceNum > 0) {
      final formatted = '₹${NumberFormat.decimalPattern().format(priceNum)}';
      return formatted.replaceFirst(RegExp(r'\.00$'), '').replaceAll('.00', '');
    }

    if (p['prices'] is Map) {
      final pr = priceText(p['prices'] as Map<String, dynamic>);
      if (pr.isNotEmpty) return pr.replaceFirst(RegExp(r'\.00$'), '').replaceAll('.00', '');
    }

    final html = (p['price_html'] ?? p['priceHtml'])?.toString() ?? '';
    if (html.isNotEmpty) {
      final clean = html.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
      if (clean.isNotEmpty) return clean.replaceFirst(RegExp(r'\.00$'), '').replaceAll('.00', '');
    }

    return '₹0';
  }

  String get formattedRegularPrice {
    final p = product.value;
    if (p == null) return '';
    final regPrice = p['regularPrice'];
    final curPrice = p['price'] ?? p['discountPrice'];
    if (regPrice is num && curPrice is num && regPrice > curPrice) {
      final formatted = '₹${NumberFormat.decimalPattern().format(regPrice)}';
      return formatted.replaceFirst(RegExp(r'\.00$'), '').replaceAll('.00', '');
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
    final thumb = (p['thumbnail'] ?? p['thumbnailImage'] ?? p['featuredImage'] ?? p['image'])?.toString();
    if (thumb != null && thumb.trim().isNotEmpty) {
      return ApiConstant.getImageUrl(thumb.trim());
    }
    final imgs = (p['images'] as List?) ?? const [];
    if (imgs.isEmpty) return null;
    final first = imgs.first;
    if (first is Map) {
      final url = (first['imageUrl'] ?? first['url'] ?? first['src'] ?? first['thumbnail'])?.toString();
      return ApiConstant.getImageUrl(url);
    }
    return ApiConstant.getImageUrl(first?.toString());
  }

  final styleItWithProducts = <Map<String, dynamic>>[].obs;

  Future<void> _loadStyleItWithAndRelated(
    Map<String, dynamic> p,
    List<Map<String, dynamic>> catalogProducts,
  ) async {
    final explicitStyle = <Map<String, dynamic>>[];
    final raw = p['styleItWith'];
    if (raw is List && raw.isNotEmpty) {
      for (final item in raw) {
        if (item is Map) {
          explicitStyle.add((item).cast<String, dynamic>());
        } else if (item is String && item.isNotEmpty) {
          try {
            final fetched = await api.fetchProduct(item);
            if (fetched.isNotEmpty) explicitStyle.add(fetched);
          } catch (_) {}
        }
      }
    }

    final currentIdStr = (p['_id'] ?? p['id'] ?? '').toString();
    final explicitIds = explicitStyle.map((e) => (e['_id'] ?? e['id'] ?? '').toString()).toSet();

    // Catalog pool excluding current product & explicit products
    final catalogPool = catalogProducts.where((prod) {
      final idStr = (prod['_id'] ?? prod['id'] ?? '').toString();
      return idStr != currentIdStr && !explicitIds.contains(idStr);
    }).toList();

    // 1. Build RELATED PRODUCTS (styleItWithProducts): explicit products first, then catalog pool (up to 8)
    final styleList = <Map<String, dynamic>>[...explicitStyle];
    for (final item in catalogPool) {
      if (styleList.length >= 8) break;
      styleList.add(item);
    }
    styleItWithProducts.assignAll(styleList);

    // 2. Build YOU MIGHT ALSO LIKE (related): catalog pool items NOT included in styleItWithProducts
    final styleIds = styleList.map((e) => (e['_id'] ?? e['id'] ?? '').toString()).toSet();
    final remainingPool = catalogPool.where((prod) {
      final idStr = (prod['_id'] ?? prod['id'] ?? '').toString();
      return !styleIds.contains(idStr);
    }).toList();

    List<Map<String, dynamic>> likeList;
    if (remainingPool.isNotEmpty) {
      likeList = remainingPool.take(8).toList();
    } else if (catalogPool.length > 2) {
      // If all catalog items were consumed in styleList, reverse/rotate catalogPool for variety so they aren't identical at first glance
      likeList = catalogPool.reversed.take(8).toList();
    } else {
      likeList = catalogPool.take(8).toList();
    }

    related.assignAll(likeList);
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

  String? _parseImg(dynamic val) {
    if (val == null) return null;
    if (val is String) return val.trim().isNotEmpty ? val.trim() : null;
    if (val is Map) {
      final res = (val['url'] ?? val['src'] ?? val['imageUrl'] ?? val['path'] ?? val['image'])?.toString().trim();
      return (res != null && res.isNotEmpty) ? res : null;
    }
    return null;
  }

  String? _findImgInMap(Map m) {
    return _parseImg(m['image']) ??
        _parseImg(m['texture']) ??
        _parseImg(m['textureImage']) ??
        _parseImg(m['imageUrl']) ??
        _parseImg(m['photo']) ??
        _parseImg(m['swatch']) ??
        _parseImg(m['src']) ??
        _parseImg(m['icon']);
  }

  List<Map<String, String>> _extractColors(Map<String, dynamic> p) {
    final list = <Map<String, String>>[];
    final mapBySlug = <String, Map<String, String>>{};

    void addOption(String label, String slug, [String? rawImg, String? hexColor]) {
      if (label.trim().isEmpty) return;
      final cleanSlug = slug.trim().toLowerCase();

      String? fullImg;
      if (rawImg != null && rawImg.trim().isNotEmpty) {
        fullImg = ApiConstant.getImageUrl(rawImg.trim());
      }

      if (mapBySlug.containsKey(cleanSlug)) {
        final existing = mapBySlug[cleanSlug]!;
        if ((existing['image'] == null || existing['image']!.isEmpty) && fullImg != null && fullImg.isNotEmpty) {
          existing['image'] = fullImg;
        }
        if ((existing['color'] == null || existing['color']!.isEmpty) && hexColor != null && hexColor.trim().isNotEmpty) {
          existing['color'] = hexColor.trim();
        }
        return;
      }

      final map = <String, String>{
        'label': label.trim(),
        'slug': cleanSlug,
      };
      if (fullImg != null && fullImg.isNotEmpty) {
        map['image'] = fullImg;
      }
      if (hexColor != null && hexColor.trim().isNotEmpty) {
        map['color'] = hexColor.trim();
      }
      mapBySlug[cleanSlug] = map;
      list.add(map);
    }

    // 1. First check rich colorSwatches / swatches (stores admin custom fabric/color images)
    final swatches = (p['colorSwatches'] as List?) ?? (p['swatches'] as List?) ?? const [];
    for (final s in swatches) {
      if (s is Map) {
        final label = (s['color'] ?? s['name'] ?? s['label'] ?? s['title'])?.toString();
        final slug = (s['slug'] ?? label ?? '').toString();
        final img = _findImgInMap(s);
        final hex = (s['hex'] ?? s['code'] ?? s['colorCode'] ?? s['value'])?.toString();
        if (label != null) addOption(label, slug, img, hex);
      }
    }

    // 2. Direct colors list (strings or maps)
    final cols = (p['colors'] as List?) ?? const [];
    for (final c in cols) {
      if (c is Map) {
        final label = (c['name'] ?? c['color'] ?? c['label'] ?? c['title'])?.toString();
        final slug = (c['slug'] ?? label ?? '').toString();
        final img = _findImgInMap(c);
        final hex = (c['hex'] ?? c['code'] ?? c['colorCode'] ?? c['value'])?.toString();
        if (label != null) addOption(label, slug, img, hex);
      } else if (c != null) {
        addOption(c.toString(), c.toString());
      }
    }

    // 3. Single color string
    if (p['color'] is String && (p['color'] as String).trim().isNotEmpty) {
      for (final splitted in (p['color'] as String).split(',')) {
        addOption(splitted, splitted);
      }
    }

    // 4. Images list with color tags
    final imgs = (p['images'] as List?) ?? const [];
    for (final item in imgs) {
      if (item is Map && item['color'] != null) {
        final c = item['color'].toString().trim();
        final img = _findImgInMap(item);
        addOption(c, c, img);
      }
    }

    // 5. Variants / Variations
    final vars = (p['variants'] as List?) ?? (p['variations'] as List?) ?? const [];
    for (final v in vars) {
      if (v is Map) {
        final c = (v['color'] ?? v['attributes']?['color'] ?? v['attributes']?['pa_color'])?.toString();
        final img = _findImgInMap(v);
        final hex = (v['colorCode'] ?? v['hex'])?.toString();
        if (c != null) addOption(c, c, img, hex);
      }
    }

    // 6. Attributes
    final fromAttrs = _extractOptions(p, wantsSlug: 'pa_color', nameContains: 'color');
    for (final e in fromAttrs) {
      final label = e['label'] ?? '';
      final slug = e['slug'] ?? label;
      final img = e['image'];
      final hex = e['color'];
      addOption(label, slug, img, hex);
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
    final terms = (target['terms'] as List?) ?? (target['options'] as List?) ?? const [];
    return terms.map<Map<String, String>>((t) {
      if (t is Map) {
        final label = (t['name'] ?? t['label'] ?? t['value'])?.toString() ?? '';
        final slug  = (t['slug']?.toString() ?? label.toLowerCase()).trim();
        final img   = _findImgInMap(t);
        final hex   = (t['hex'] ?? t['color'] ?? t['colorCode'] ?? t['code'] ?? t['value'])?.toString();
        final map = <String, String>{'label': label, 'slug': slug};
        if (img != null && img.trim().isNotEmpty) {
          final full = ApiConstant.getImageUrl(img.trim());
          if (full.isNotEmpty) map['image'] = full;
        }
        if (hex != null && hex.trim().isNotEmpty) map['color'] = hex.trim();
        return map;
      } else if (t != null) {
        final str = t.toString().trim();
        return {'label': str, 'slug': str.toLowerCase()};
      }
      return <String, String>{};
    }).where((m) => m.isNotEmpty).toList();
  }

  // ---------- variation resolution ----------
  int? findVariationId(Map<String, dynamic> p, Map<String, String> selected) {
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

    await addToCart(
      context: context,
      productId: productId,
      quantity: qty.value.clamp(1, 999),
      attributes: attrs,
    );
  }

  /// Direct Buy Now: validates, adds to cart, and navigates directly to Checkout
  Future<void> buyNow(BuildContext context) async {
    final attrs = _currentAttributes();
    final p = product.value;

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

    final success = await addToCart(
      context: context,
      productId: productId,
      quantity: qty.value.clamp(1, 999),
      attributes: attrs,
    );

    if (success && context.mounted) {
      Get.to(() => const CheckoutScreen());
    }
  }

  Future<bool> addToCart({
    required BuildContext context,
    required dynamic productId,
    required int quantity,
    required Map<String, String> attributes,
    dynamic variationId,
  }) async {
    if (adding.value) return false;
    adding.value = true;

    try {
      final p = product.value;
      final name = (p?['name'] ?? p?['title'] ?? 'Product').toString();
      final price = formattedPrice;
      final image = extractedImages.isNotEmpty ? extractedImages.first : null;
      final pIdStr = (p?['_id'] ?? p?['id'] ?? productId).toString();

      final cartService = Get.isRegistered<CartService>()
          ? Get.find<CartService>()
          : Get.put(CartService(), permanent: true);

      cartService.addItem(
        productId: pIdStr,
        name: name,
        price: price,
        image: image,
        selectedSize: sizeLabel.value ?? sizeSlug.value,
        selectedColor: colorLabel.value ?? colorSlug.value,
        quantity: quantity,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Added to bag ✓'),
          duration: Duration(milliseconds: 1200),
        ));
      }
      return true;
    } catch (e) {
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