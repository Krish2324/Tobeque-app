// lib/view/cart/cart_screen.dart
import 'dart:ui';
import 'package:tobeque/utills/html_decode.dart';
import 'package:tobeque/view/checkout/checkout_screen.dart';
import 'package:tobeque/view/prodduct_details/product_detail_binding.dart';
import 'package:tobeque/view/wishlist/wish_button.dart';
import 'package:tobeque/view/wishlist/wishlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:tobeque/view/cart/cart_controller.dart';
import 'package:tobeque/view/cart/cart_binding.dart';
import 'package:tobeque/view/prodduct_details/product_details_page.dart';

class CartScreen extends GetView<CartController> {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    CartBinding().dependencies();

    return Obx(() {
      if (controller.loading.value) {
        return const Scaffold(
        
          body: Center(child: CircularProgressIndicator(color: Colors.grey)),
        );
      }

      if (controller.error.value != null) {
        return Scaffold(
         // appBar: const _CartAppBar(),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error loading cart',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(controller.error.value!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.fetchCart,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      final items = controller.items;
     // when cart is empty
if (items.isEmpty) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: controller.fetchCart,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SizedBox(height: 8),
            const _FreeDeliveryBanner(), // keeps your wishlist CTA chip
            const SizedBox(height: 12),

            // Empty-state hero
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 72, color: Colors.black38),
                  const SizedBox(height: 10),
                  const Text('Your bag is empty',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Add something you love to get started',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 14),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: Get.back, // or route to your Home/Shop page
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('START SHOPPING', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Get.to(() => const WishlistScreen()),
                          icon: const Icon(Icons.favorite_border, size: 18),
                          label: const Text('WISHLIST'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Color(0xffe5e5e5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Suggestions (only show if you have any)
            if (controller.popularNotInCart.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Text(
                  'You might be interested in',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              SuggestStrip(items: controller.popularNotInCart),
            ],
          ],
        ),
      ),
    ),
  );
}


      return Scaffold(
     //   appBar: const _CartAppBar(),
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: controller.fetchCart,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 160),
                  children: [
                    const _FreeDeliveryBanner(),
                    const SizedBox(height: 6),
          
                    // -------- cart items ----------
                    ...List.generate(items.length, (i) {
                      final item = (items[i] as Map).cast<String, dynamic>();
                      final name = item['name']?.toString() ?? '';
                      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                      final img = controller.pickCartImage(item);
          
                      // attributes (size, color, etc.)
                      final rawAttrs = (item['variation'] as List?) ??
                          (item['attributes'] as List?) ??
                          const [];
                      final sizeOnly = _extractSize(rawAttrs);
                      final attrText = _attrText(controller, rawAttrs);
          
                      // price text (line total or price)
                      final totals =
                          (item['totals'] as Map?)?.cast<String, dynamic>() ??
                              const {};
                      final lineTotal = totals['line_total_rendered']?.toString() ??
                          totals['line_total']?.toString() ??
                          totals['total']?.toString() ??
                          '';
                      final priceText = controller.formatPrice(
                          lineTotal.isNotEmpty ? lineTotal : (item['price'] ?? ''));
          
                      return InkWell(
                        onTap: () async {
                          final id = await controller.resolveProductId(item);
                          if (id == null) return;
                          await Get.to(
                            () => ProductDetailPage(
                                key: ValueKey(id), productId: id),
                            binding: ProductDetailBinding(id),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _CartImage(imageUrl: img),
                                  const SizedBox(width: 14),
          
                                  // Title, attrs, qty controls
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // price right-aligned on first row
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  priceText,
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w900),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      tooltip: 'Edit',
                                                      icon: const Icon(
                                                          Icons.edit_outlined,
                                                          size: 20),
                                                      onPressed: () async {
                                                        final id =
                                                            await controller
                                                                .resolveProductId(
                                                                    item);
                                                        if (id == null) return;
                                                        await Get.to(
                                                          () => ProductDetailPage(
                                                              key: ValueKey(id),
                                                              productId: id),
                                                          binding:
                                                              ProductDetailBinding(
                                                                  id),
                                                        );
                                                      },
                                                    ),
                                                    Obx(() => IconButton(
                                                          tooltip: 'Remove',
                                                          icon: const Icon(
                                                              Icons.delete_outline,
                                                              size: 20),
                                                          onPressed: controller
                                                                  .mutating.value
                                                              ? null
                                                              : () => controller
                                                                  .removeItem(item),
                                                        )),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
          
                                        if (sizeOnly != null) ...[
                                          const SizedBox(height: 4),
                                          Text(sizeOnly,
                                              style: const TextStyle(
                                                  color: Colors.black87)),
                                        ] else if (attrText.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(attrText,
                                              style: const TextStyle(
                                                  color: Colors.black54)),
                                        ],
          
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Obx(() => _QtyButton(
                                                  icon: Icons.remove,
                                                  onTap: controller
                                                          .mutating.value
                                                      ? null
                                                      : () => controller
                                                          .decQty(item),
                                                )),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 10),
                                              child: Text('$qty',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700)),
                                            ),
                                            Obx(() => _QtyButton(
                                                  icon: Icons.add,
                                                  onTap: controller
                                                          .mutating.value
                                                      ? null
                                                      : () => controller
                                                          .incQty(item),
                                                )),
                                          ],
                                        ),
          
                                        const SizedBox(height: 12),
                                        InkWell(
                                          onTap: () {
                                            // hook your wishlist add here
                                          },
                                          child: const Text(
                                            'Move to favourites',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                             
                            ],
                          ),
                        ),
                      );
                    }),
           const SizedBox(height: 14),
                              const Divider(height: 1),
                    // -------- promotional code ----------
                    const _PromoCodeRow(),
                    const Divider(height: 1),
          
                    // -------- recommendations ----------
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
                      child: Text(
                        'You might be interested in',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                   SuggestStrip(items: controller.popularNotInCart),
                  ],
                ),
              ),
          
              // ---- blur overlay while mutating (unchanged) ----
              Obx(() {
                final show = controller.mutating.value;
                return IgnorePointer(
                  ignoring: !show,
                  child: AnimatedOpacity(
                    opacity: show ? 1 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: Stack(
                      children: [
                        Positioned.fill(
                            child: Container(
                                color: Colors.black.withOpacity(0.04))),
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: const SizedBox.expand(),
                          ),
                        ),
                        const Positioned.fill(
                          child: Center(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Updating…',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // sticky green total bar + CTA
        bottomNavigationBar: _TotalBarGreen(
          total: controller.formatPrice(controller.cartTotal()),
          onProcess: controller.mutating.value
              ? null
              : () => Get.to(const CheckoutScreen()),
        ),
      );
    });
  }

  // helpers for attr rendering
  String _attrText(CartController c, List raw) {
    return raw
        .whereType<Map>()
        .map((m) {
          final mm = m.cast<String, dynamic>();
          final n = (mm['name'] ?? mm['attribute'] ?? '').toString();
          final v = (mm['value'] ?? '').toString();
          final nice =
              n.replaceAll(RegExp(r'^pa_'), '').replaceAll('_', ' ');
          return v.isEmpty
              ? ''
              : '${nice.isEmpty ? '' : '${c.titleCase(nice)}: '}$v';
        })
        .where((s) => s.trim().isNotEmpty)
        .join('  •  ');
  }

  String? _extractSize(List raw) {
    for (final x in raw.whereType<Map>()) {
      final name =
          (x['name'] ?? x['attribute'] ?? '').toString().toLowerCase();
      if (name.contains('size')) {
        final v = (x['value'] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
    }
    return null;
  }
}

/* ------------------------------ UI pieces ------------------------------ */

// class _CartAppBar extends StatelessWidget implements PreferredSizeWidget {
//   const _CartAppBar();

//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);

//   @override
//   Widget build(BuildContext context) {
//     return AppBar(
//       title: const Text('My Cart'),
//       centerTitle: true,
//       elevation: 0.5,
//       backgroundColor: Colors.white,
//       foregroundColor: Colors.black,
//     );
//   }
// }

class _FreeDeliveryBanner extends StatelessWidget {
  const _FreeDeliveryBanner();

  @override
  Widget build(BuildContext context) {
   return Material(
  color: Colors.transparent,
  child: InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: () => Get.to(() => const WishlistScreen()),
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xffecfff1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffd7f5de)),
      ),
      child: Row(
        children: [
          const Text(
            'OMG!',
            style: TextStyle(
              color: Color(0xff0a8f3f),
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
                fontSize: 12,
            ),
          ),
          const SizedBox(width: 5),
          const Expanded(
            child: Text(
              'FREE STANDARD DELIVERY!',
              style: TextStyle(
                color: Color(0xff0a8f3f),
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
              ),
            ),
          ),
         //const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => Get.to(() => const WishlistScreen()),
            icon: const Icon(Icons.favorite_border, size: 16),
            label: const Text('WISHLIST'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xff0a8f3f),
              side: const BorderSide(color: Color(0xff0a8f3f)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}

class _PromoCodeRow extends StatelessWidget {
  const _PromoCodeRow();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: const Icon(Icons.auto_awesome, color: Colors.black87),
      title: const Text('Promotional code'),
      trailing: TextButton(
        onPressed: () {
          // open add-coupon flow
        },
        child: const Text('At checkout'),
      ),
    );
  }
}

class SuggestStrip extends GetView<CartController> {
  const SuggestStrip({required this.items});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 340, // fits 3:4 image + texts
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: items.length.clamp(0, 12),
        itemBuilder: (_, i) {
          final p = items[i];

          // image
          final images = (p['images'] as List?) ?? const [];
          String img = '';
          if (images.isNotEmpty && images.first is Map) {
            img = (images.first as Map)['src']?.toString() ?? '';
          }

          // name
          final name = (p['name']?.toString() ?? '').trim();

          // price (Store API minor units → fallback to price_html)
          String priceText;
          final minorStr = p['prices']?['price']?.toString() ?? '';
          if (minorStr.isNotEmpty && RegExp(r'^\d+$').hasMatch(minorStr)) {
            priceText = controller.formatPrice(minorStr);
          } else {
            final html = (p['price_html']?.toString() ?? '')
                .replaceAll(RegExp(r'<[^>]*>'), '')
                .replaceAll('&nbsp;', ' ')
                .trim();
            priceText = html.isEmpty ? '' : html;
          }

          return InkWell(
            onTap: () async {
              final pid = p['id'];
              final id = pid is int ? pid : await controller.resolveProductId(p);
              if (id == null) return;
              await Get.to(
                () => ProductDetailPage(key: ValueKey(id), productId: id),
                binding: ProductDetailBinding(id),
              );
            },
            child: SizedBox(
              width: 160,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 5 / 7.7,
                    child: ClipRRect(
                      child: Container(
                        color: const Color(0xfff3f3f3),
                        child: img.isEmpty
                            ? const SizedBox.shrink()
                            : Image.network(img, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // TITLE
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      Column(
                          mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width/3.9,
                            child: Text(
                              HtmlDecode.text(name)
                              ,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: .2,
                                fontSize: 12,
                                height: 1.15,
                              ),
                            ),
                          ),
                           const SizedBox(height: 4),
                      
                      // PRICE
                      if (priceText.isNotEmpty)
                        Text(
                          priceText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: .3,
                            fontSize: 12,
                          ),
                        ),
                        ],
                      ),
                          SizedBox(
                                                    
                            child: WishButton(
                              
                                  id: (p['id'] as num).toInt(),
                                name: (p['name'] ?? '').toString(),
                                priceHtml: p['price_html']?.toString(),
                                image: (() {
                                  final images = p['images'] as List?;
                                  if (images != null && images.isNotEmpty && images.first is Map) {
                                    return (images.first as Map)['src']?.toString();
                                  }
                                  return null;
                                })(),
                              size: 20,                       // adjust if you want bigger/smaller
                              activeColor: Colors.redAccent,  // filled heart color
                              inactiveColor: Colors.black54,  // outline color
                            ),
                          ),

                 ] ),

                 
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}



class _TotalBarGreen extends StatelessWidget {
  const _TotalBarGreen({required this.total, this.onProcess});
  final String total;
  final VoidCallback? onProcess;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xffeeeeee))),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Total',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const Spacer(),
                Text(total,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(width: 9),
                
              ],
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '(Taxes included, where applicable)',
                style: TextStyle(color: Colors.black54, fontSize: 12.5),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onProcess,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff128c52),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'PROCESS ORDER',
                  style:
                      TextStyle(fontWeight: FontWeight.w900, letterSpacing: .6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartImage extends StatelessWidget {
  const _CartImage({this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 92,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xfff2f2f2)),
          child: (imageUrl == null || imageUrl!.isEmpty)
              ? const SizedBox.expand()
              : Image.network(imageUrl!, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Ink(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffe5e5e5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Icon(icon, size: 18),
          ),
        ),
      ),
    );
  }
}
