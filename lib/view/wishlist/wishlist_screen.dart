// lib/view/wishlist/wishlist_screen.dart
import 'dart:math' as math;
import 'package:tobeque/utills/html_decode.dart';
import 'package:tobeque/view/cart/cart_controller.dart';
import 'package:tobeque/view/prodduct_details/product_detail_controller.dart';
import 'package:tobeque/view/prodduct_details/size_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'wishlist_service.dart';
import 'wishlist_binding.dart';

import 'package:tobeque/view/prodduct_details/product_detail_binding.dart';
import 'package:tobeque/view/prodduct_details/product_details_page.dart';
import 'package:tobeque/view/prodduct_details/product_api_repo.dart';
import 'package:tobeque/data/network/network_api_sarvices.dart';

class WishlistScreen extends GetView<WishlistService> {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WishlistBinding().dependencies();

    return Obx(() {
      final items = controller.items.values.toList();
      return Scaffold(
        appBar: AppBar(
          title: Text('Favourites (${items.length})'),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: .5,
          actions: [
           
          ],
        ),
        body: items.isEmpty
            ? const _Empty()
            : _WishlistBody(favs: items),
      );
    });
  }
}

/* ------------------------------- EMPTY STATE ------------------------------ */

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No favourites yet'));
  }
}

/* ----------------------------- PAGE BODY (LIST) --------------------------- */

class _WishlistBody extends StatefulWidget {
  const _WishlistBody({required this.favs});
  final List<WishItem> favs;

  @override
  State<_WishlistBody> createState() => _WishlistBodyState();
}

class _WishlistBodyState extends State<_WishlistBody> {
  final _api = ProductApi(NetworkApi());
  bool _loading = true;
  List<Map<String, dynamic>> _suggest = const [];

  @override
  void initState() {
    super.initState();
    _loadSuggest();
  }

  Future<void> _loadSuggest() async {
    // Simple “popular”/best offers as suggestions (no auth required).
    try {
      final res = await _api.net.getApi(
        'products?orderby=popularity&order=desc&per_page=12',
      );
      if (res is List) {
        _suggest = res.cast<Map<String, dynamic>>();
      }
    } catch (_) {
      _suggest = const [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // FAVOURITES LIST
        ...widget.favs.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _WishRow(item: w),
            )),

        const SizedBox(height: 8),
        // “YOU MAY LIKE” HEADER (centered)
        const Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            'You may like',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),

        // GRID SUGGESTIONS
        if (_loading)
          const _SuggestSkeleton()
        else if (_suggest.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _suggest.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 0,
              crossAxisSpacing: 5,
              childAspectRatio: 0.5,
            ),
            itemBuilder: (_, i) => _SuggestTile(p: _suggest[i]),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}

/* ------------------------------ FAVOURITE ROW ----------------------------- */

class _WishRow extends StatelessWidget {
  const _WishRow({required this.item});
  final WishItem item;

  String _cleanPrice(String? html) {
    if (html == null || html.isEmpty) return '';
    var s = html.replaceAll(RegExp(r'<[^>]*>'), '');
    s = s.replaceAll('&nbsp;', ' ').replaceAll('&amp;', '&');
    s = s.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final c = int.tryParse(m.group(1)!);
      return c != null ? String.fromCharCode(c) : m.group(0)!;
    }).replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
      final c = int.tryParse(m.group(1)!, radix: 16);
      return c != null ? String.fromCharCode(c) : m.group(0)!;
    });
    s = s.replaceFirstMapped(RegExp(r'^([^\d\s]+)(\d)'), (m) => '${m[1]} ${m[2]}');
    return s.trim();
  }

Future<void> _moveToBasket(BuildContext context) async {
  try {
    // Ensure the PDP controller for this product exists (and loads data)
    ProductDetailBinding(item.id).dependencies();
    final c = Get.find<ProductDetailController>(tag: 'p:${item.id}');

    // If it’s still loading, show a tiny blocking spinner and wait
    if (c.loading.value) {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(.05),
      );
      while (c.loading.value) {
        await Future.delayed(const Duration(milliseconds: 80));
      }
      if (Get.isDialogOpen == true) Get.back(); // close spinner
    }

    // Open the size/color bottom sheet (handles add-to-bag itself)
    await openSizeSheet(context, c);
  } catch (e) {
    // Fallback: open PDP if anything goes wrong
    await Get.to(
      () => ProductDetailPage(key: ValueKey(item.id), productId: item.id),
      binding: ProductDetailBinding(item.id),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final svc = Get.find<WishlistService>();
    final price = _cleanPrice(item.priceHtml);

    return InkWell(
      onTap: () => Get.to(
        () => ProductDetailPage(key: ValueKey(item.id), productId: item.id, hintImageUrl: item.image),
        binding: ProductDetailBinding(item.id),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image (fixed width then AspectRatio to avoid layout overflows)
          SizedBox(
            width: 160,
            child: AspectRatio(
              aspectRatio: 3 / 4.5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: (item.image != null && item.image!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: item.image!,
                        fit: BoxFit.cover,
                        memCacheWidth: 400,
                        placeholder: (_, __) => const ColoredBox(color: Color(0xFFF2F2F2)),
                        errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFFF2F2F2)),
                      )
                    : const ColoredBox(color: Color(0xFFF2F2F2)),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title/price + Move to basket
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + heart on the same row (like screenshot)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        HtmlDecode.text(item.name),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.redAccent),
                      onPressed: () => svc.remove(item.id),
                      tooltip: 'Remove',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (price.isNotEmpty)
                  Text(price,
                      style: const TextStyle(fontWeight: FontWeight.w800)),

                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => _moveToBasket(context),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: const StadiumBorder(),
                    side: const BorderSide(color: Colors.black87, width: 1.2),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Move to basket',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------------- SUGGEST GRID TILE ---------------------------- */

class _SuggestTile extends GetView<CartController> {
  const _SuggestTile({required this.p});
  final Map<String, dynamic> p;

  String _decode(String s) {
    // very small HTML entity decode (&amp; etc.) for names/prices
    return s
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#038;', '&')
        .replaceAll('&amp;', '&')
        .trim();
  }

  String _price(Map<String, dynamic> m) {
    final rawMinor = m['prices']?['price']?.toString() ?? '';
    if (rawMinor.isNotEmpty && RegExp(r'^\d+$').hasMatch(rawMinor)) {
      // minor units -> major without trailing .00
      final v = int.tryParse(rawMinor) ?? 0;
      final major = v / math.pow(10, (m['prices']?['currency_minor_unit'] as int?) ?? 2);
      final sym = (m['prices']?['currency_symbol']?.toString() ?? '₹');
      final text = _trimZeros(major);
      return '$sym$text';
    }
    final html = (m['price_html']?.toString() ?? '');
    return _decode(html);
  }

  String _trimZeros(num value) {
    final s = value.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'\.00$'), '');
  }

  @override
  Widget build(BuildContext context) {
    // image
    String img = (p['thumbnail'] ?? p['thumbnailImage'] ?? p['featuredImage'] ?? p['image'])?.toString() ?? '';
    if (img.isEmpty) {
      final imgs = (p['images'] as List?) ?? const [];
      if (imgs.isNotEmpty && imgs.first is Map) {
        img = (imgs.first as Map)['src']?.toString() ?? (imgs.first as Map)['imageUrl']?.toString() ?? '';
      }
    }
    // text
    final name = _decode((p['name'] ?? '').toString());
    final priceText = _price(p);

    return InkWell(
      onTap: () async {
        final pid = p['id'] as int?;
        if (pid == null) return;
        await Get.to(
          () => ProductDetailPage(key: ValueKey(pid), productId: pid, hintImageUrl: img.isNotEmpty ? img : null),
          binding: ProductDetailBinding(pid),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: AspectRatio(
                aspectRatio: 3 / 5,
                child: Container(
                  color: const Color(0xfff3f3f3),
                  child: img.isEmpty
                      ? const SizedBox.shrink()
                      : CachedNetworkImage(
                          imageUrl: img,
                          fit: BoxFit.cover,
                          memCacheWidth: 400,
                          placeholder: (_, __) => const SizedBox.shrink(),
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 0,
              letterSpacing: .2,
            ),
          ),
        

          // Price + bag icon
          Row(
            children: [
              Expanded(
                child: Text(
                  priceText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: .3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            
            ],
          ),
          SizedBox(
            height: 10,
          )
        ],
      ),
    );
  }
}

/* ------------------------------ SKELETON GRID ----------------------------- */

class _SuggestSkeleton extends StatelessWidget {
  const _SuggestSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.74,
      ),
      itemBuilder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDED),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 10, width: 120, color: const Color(0xFFEDEDED)),
          const SizedBox(height: 6),
          Container(height: 10, width: 80, color: const Color(0xFFEDEDED)),
        ],
      ),
    );
  }
}
