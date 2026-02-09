import 'package:tobeque/utills/html_decode.dart';
import 'package:tobeque/view/cart/cart_screen.dart';
import 'package:tobeque/view/prodduct_details/product_detail_binding.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'product_detail_controller.dart';
import 'package:tobeque/view/wishlist/wish_button.dart';

import 'size_sheet.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.productId});
  final int productId;

  @override
  Widget build(BuildContext context) {
    // Get the controller that was created by the binding
    final c = Get.find<ProductDetailController>(tag: 'p:$productId');
// add this field


    return Obx(() {
      if (c.loading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.black)));
      }
      if (c.error.value != null) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(c.error.value!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: c.refreshNow, child: const Text('Retry')),
              ],
            ),
          ),
        );
      }

      final p = c.product.value!;
      final name = (p['name'] ?? '').toString();
      final price = c.priceText(p['prices']);
      final images = (p['images'] as List? ?? [])
          .map((e) => (e as Map)['src']?.toString() ?? '')
          .where((e) => e.isNotEmpty).toList();
final rawHtml = (p['description'] as String? ?? '');
final desc = rawHtml
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&nbsp;', ' ')
    .trim();
      return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                
                // --- Big gallery (like screenshot) ---
                SliverAppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
            onPressed: Get.back,
          ),
          actions:  [
            // Padding(
            //   padding: EdgeInsets.only(right: 6),
            //   child: Icon(Icons.shopping_bag_outlined, color: Colors.black87),
            // ),
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: IconButton(
               
         icon: Icon( Icons.shopping_bag_outlined,color: Colors.black87,), onPressed: () { 
          Get.to(CartScreen());
          },),
            ),
          ],
          expandedHeight: MediaQuery.of(context).size.height * 0.775,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              children: [
        // gallery
        
               PageView.builder(
          scrollDirection: Axis.vertical,   // 👈 vertical scroll
          controller: c.pageCtrl,
          onPageChanged: (i) => c.page.value = i,
          itemCount: images.isEmpty ? 1 : images.length,
          itemBuilder: (_, i) {
            if (images.isEmpty) return const ColoredBox(color: Color(0xfff2f2f2));
            return ColoredBox(
              color: Colors.white,
              child: Image.network(
        images[i],
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        width: double.infinity,
        height: double.infinity,
              ),
            );
          },
        ),
        
        
        // dots like the app: a small capsule centered near the bottom
        if (images.length > 1)
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: Obx(() => _VerticalDots(
            count: images.length,
            index: c.page.value.clamp(0, images.length - 1),
          )),
            ),
          ),
        // ... existing children of the Stack (PageView + dots)
Positioned(
  right: 8,
  bottom: 8,
  child: Material(
    color: Colors.white.withOpacity(0.30),
    shape: const CircleBorder(),
    child: Padding(
      padding: const EdgeInsets.all(2),
      // We’re on PDP, so we have the product map `p`
      child: WishButton(
        id: (p['id'] as num).toInt(),
        name: (p['name'] ?? '').toString(),
        // priceHtml is optional here; pass null or a formatted string if you want
        image: (p['images'] is List && (p['images'] as List).isNotEmpty)
            ? (((p['images'] as List).first as Map)['src']?.toString())
            : null,
        size: 22,
        activeColor: Colors.redAccent,
        inactiveColor: Colors.black54,
      ),
    ),
  ),
),

              ],
            ),
          ),
        ),
        
                // --- Summary card ---
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 44, height: 6,
                          decoration: BoxDecoration(
                            color: Colors.black12, borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(  HtmlDecode.text(  name),
                                  style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w400,
                                    letterSpacing: .2,
                                    
                                  )),
                            ),
                            const SizedBox(width: 10),
                            Text(price,
                                style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400,
                                )),
                          ],
                        ),
                      ),
                      
                      // delivery tiles
                      const _DeliveryTile(
                        title: 'Collection in‑store',
                        trailing: 'FREE',
                        icon: Icons.store_mall_directory_outlined,
                      ),
                      const _DeliveryTile(
                        title: 'Standard home delivery',
                        trailing: 'FREE',
                        subtitle: 'You need £0.01 more to be eligible',
                        icon: Icons.local_shipping_outlined,
                      ),
        
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text('About this product',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                     if (desc.isNotEmpty)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Obx(() {
      final expanded = c.descExpanded.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            desc,
            style: const TextStyle(height: 1.6),
            maxLines: expanded ? null : 3,                 // show only a few lines first
            overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => c.descExpanded.toggle(),
            icon: Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18),
            label: Text(expanded ? 'Read less' : 'Read more'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      );
    }),
  ),
                      const SizedBox(height: 20),
                      // --- Related products grid ---
        if (c.related.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'You might be like !',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
         // --- Related products grid (styled like SuggestStrip) ---
GridView.builder(
  physics: const NeverScrollableScrollPhysics(),
  shrinkWrap: true,
  itemCount: c.related.length,
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 2,
    crossAxisSpacing: 2,
    childAspectRatio: 0.58, // close to SuggestStrip proportions
  ),
  itemBuilder: (_, i) {
    final p = c.related[i] ;
    final id = (p['id'] as num).toInt();
    return _RelatedCard(
      p: p,
      onTap: () => Get.to(
        () => ProductDetailPage(key: ValueKey(id), productId: id),
        binding: ProductDetailBinding(id),
        preventDuplicates: false,
      ),
      priceFromPricesMap: (prices) => c.priceText(prices), // reuse your helper
    );
  },
),
SizedBox(
  height: 70,
)
        ],
         // room for bottom bar
                    ],
                  ),
                ),
              ],
            ),
        
            // --- Bottom bar SELECT SIZE (sticky) ---
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => openSizeSheet(context, c),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.5)),
                      ),
                      child: const Text('SELECT SIZE', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
// --- Tile used by the grid, visually matching SuggestStrip ---
class _RelatedCard extends StatelessWidget {
  const _RelatedCard({
    required this.p,
    required this.onTap,
    required this.priceFromPricesMap,
  });

  final Map<String, dynamic> p;
  final VoidCallback onTap;
  final String Function(Map<String, dynamic>?) priceFromPricesMap;

  String _priceText() {
    // 1) Prefer Store API prices (minor units) via your controller helper
    final pricesMap = (p['prices'] as Map?)?.cast<String, dynamic>();
    var price = priceFromPricesMap(pricesMap);

    // 2) Fallback to price_html if needed
    if (price.isEmpty) {
      final html = (p['price_html']?.toString() ?? '')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&nbsp;', ' ')
          .trim();
      price = html;
    }
    return price;
    }

  @override
  Widget build(BuildContext context) {
    final name = (p['name']?.toString() ?? '').trim();

    // best image
    String? imageUrl;
    final imgs = (p['images'] as List?) ?? const [];
    if (imgs.isNotEmpty && imgs.first is Map) {
      imageUrl = (imgs.first as Map)['src']?.toString();
    }

    final priceText = _priceText();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left:8.0,right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (same feel as SuggestStrip → cover inside fixed aspect)
            AspectRatio(
              aspectRatio: 5 / 7.7,
              child: ClipRRect(
                child: Container(
                  color: const Color(0xfff3f3f3),
                  child: (imageUrl == null || imageUrl!.isEmpty)
                      ? const SizedBox.shrink()
                      : Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
        
            // Title (two lines, bold, small leading)
            Text(
            
              HtmlDecode.text(  name),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: .2,
                fontSize: 12,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 4),
        
            // Price (single line, heavy)
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
      ),
    );
  }
}

class _DeliveryTile extends StatelessWidget {
  const _DeliveryTile({required this.title, this.subtitle, required this.trailing, required this.icon});
  final String title;
  final String? subtitle;
  final String trailing;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffeeeeee)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Icon(icon, color: Colors.black87),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: subtitle == null ? null : Text(subtitle!, style: const TextStyle(color: Colors.black54)),
          trailing: Text(trailing, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}
class _VerticalDots extends StatelessWidget {
  const _VerticalDots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(top: 10,bottom: 10,right: 10),
          width: 6,
          height: isActive ? 18 : 6,   // 👈 vertical bar when active
          decoration: BoxDecoration(
            color: isActive ? Colors.grey : Colors.black.withOpacity(.5),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}
