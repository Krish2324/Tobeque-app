import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tobeque/utills/html_decode.dart';
import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/view/cart/cart_screen.dart';
import 'package:tobeque/view/wishlist/wish_button.dart';
import 'package:tobeque/view/root/bage_controller.dart';
import 'package:tobeque/componant/helper.dart';
import 'product_detail_controller.dart';
import 'product_detail_binding.dart';
import 'package:tobeque/constants/string_constant.dart';
import 'package:tobeque/utills/helper_func.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.productId});
  final dynamic productId;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProductDetailController>(tag: 'p:$productId');

    return Obx(() {
      if (c.loading.value) {
        return const Scaffold(
          backgroundColor: Colors.white,
          body: _PdpSkeletonLoader(),
        );
      }

      if (c.error.value != null) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
              onPressed: Get.back,
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(
                    c.error.value!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: c.refreshNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final p = c.product.value!;
      final name = (p['name'] ?? p['title'] ?? '').toString();
      final images = c.extractedImages;
      final price = c.formattedPrice;
      final regularPrice = c.formattedRegularPrice;
      final discount = c.discountPercent;

      final rawDesc = (p['fullDescription'] ?? p['description'] ?? p['shortDescription'] ?? '').toString();
      final desc = rawDesc.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
      final catName = (p['category'] is Map ? p['category']['name'] : null)?.toString() ?? 'TOBEQUE';

      return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── 1. HERO IMAGE CAROUSEL APP BAR ──────────────────────
                SliverAppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  pinned: true,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.85),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
                        onPressed: Get.back,
                      ),
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.85),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black, size: 20),
                              onPressed: () => Get.to(() => const CartScreen()),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: _CartBadgeDot(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  expandedHeight: MediaQuery.of(context).size.height * 0.80,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image PageView with tap to open full screen
                        PageView.builder(
                          controller: c.pageCtrl,
                          onPageChanged: (i) => c.page.value = i,
                          itemCount: images.isEmpty ? 1 : images.length,
                          itemBuilder: (ctx, i) {
                            if (images.isEmpty) {
                              return Container(
                                color: const Color(0xFFF5F5F5),
                                child: const Icon(Icons.image_not_supported_outlined, color: Colors.black26, size: 48),
                              );
                            }
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _openImageLightbox(context, images, i),
                              child: Hero(
                                tag: 'product_image_${images[i]}',
                                child: CachedNetworkImage(
                                  imageUrl: images[i],
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                  placeholder: (_, __) => const _ShimmerBox(),
                                  errorWidget: (_, __, ___) => Container(
                                    color: const Color(0xFFF5F5F5),
                                    child: const Icon(Icons.broken_image_outlined, color: Colors.black26, size: 48),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Smooth Dot Page Indicator (Bottom Center)
                        if (images.length > 1)
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: SmoothPageIndicator(
                                controller: c.pageCtrl,
                                count: images.length,
                                effect: const ExpandingDotsEffect(
                                  dotHeight: 6,
                                  dotWidth: 6,
                                  expansionFactor: 3,
                                  spacing: 5,
                                  activeDotColor: Colors.white,
                                  dotColor: Colors.white38,
                                ),
                              ),
                            ),
                          ),

                        // Fullscreen Zoom Icon Button (Bottom Right)
                        if (images.isNotEmpty)
                          Positioned(
                            right: 14,
                            bottom: 14,
                            child: CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.9),
                              radius: 18,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.fullscreen_rounded, color: Colors.black87, size: 22),
                                onPressed: () => _openImageLightbox(context, images, c.page.value),
                              ),
                            ),
                          ),

                        // Floating Wishlist Heart Button (Bottom Left)
                        Positioned(
                          left: 14,
                          bottom: 14,
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            radius: 20,
                            child: WishButton(
                              id: (p['_id'] ?? p['id'] ?? '').toString(),
                              name: name,
                              image: images.isNotEmpty ? images.first : null,
                              size: 22,
                              activeColor: Colors.redAccent,
                              inactiveColor: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 2. PRODUCT DETAILS SECTION ─────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Tag
                        Text(
                          catName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Product Name
                        Text(
                          HtmlDecode.text(name).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            height: 1.25,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Price & Discount Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              price,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            if (regularPrice.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                regularPrice,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black38,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                            if (discount > 0) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$discount% OFF',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Inclusive of all taxes',
                          style: TextStyle(fontSize: 11, color: Colors.black45),
                        ),

                        const SizedBox(height: 20),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 20),

                        // ── 3. ON-PAGE SIZE SELECTOR ───────────────────────
                        if (c.sizeOptions.isNotEmpty) ...[
                          const Text(
                            'SIZE',
                            style: TextStyle(fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          Obx(() {
                            final selectedSlug = c.sizeSlug.value ?? '';
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: c.sizeOptions.map((opt) {
                                final slug = opt['slug'] ?? '';
                                final label = opt['label'] ?? slug.toUpperCase();
                                final isSelected = selectedSlug == slug;
                                final inStock = opt['inStock'] != 'false';

                                return GestureDetector(
                                  onTap: inStock ? () { c.sizeSlug.value = slug; c.sizeLabel.value = label; } : null,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.black : Colors.white,
                                      border: Border.all(
                                        color: isSelected ? Colors.black : (inStock ? const Color(0xFFE0E0E0) : const Color(0xFFEEEEEE)),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected ? Colors.white : (inStock ? Colors.black87 : Colors.black26),
                                        decoration: inStock ? null : TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          }),
                          const SizedBox(height: 24),
                        ],

                        // ── 4. ON-PAGE COLOR SELECTOR ──────────────────────
                        if (c.colorOptions.isNotEmpty) ...[
                          Row(
                            children: [
                              const Text(
                                'COLOUR',
                                style: TextStyle(fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: Colors.black54),
                              ),
                              Obx(() {
                                final label = c.colorLabel.value;
                                if (label == null || label.isEmpty) return const SizedBox.shrink();
                                return Text(
                                  ' — ${label.toUpperCase()}',
                                  style: const TextStyle(fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: Colors.black),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Obx(() {
                            final selectedSlug = c.colorSlug.value ?? '';
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: c.colorOptions.map((opt) {
                                final slug = opt['slug'] ?? '';
                                final label = opt['label'] ?? slug;
                                final isSelected = selectedSlug == slug;
                                final swatchColor = guessColor(label) ?? guessColor(slug) ?? Colors.transparent;

                                return GestureDetector(
                                  onTap: () { c.colorSlug.value = slug; c.colorLabel.value = label; },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? Colors.black : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: swatchColor,
                                        border: Border.all(color: Colors.black12, width: 1),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          }),
                          const SizedBox(height: 24),
                        ],

                        // ── 5. ACTION BUTTONS ──────────────────────────────
                        Row(
                          children: [
                            // Quantity
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFDDDDDD)),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 14),
                                    onPressed: () { if (c.qty.value > 1) c.qty.value--; },
                                  ),
                                  Obx(() => Text('${c.qty.value}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 14),
                                    onPressed: () => c.qty.value++,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // ADD TO CART
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: Obx(() {
                                  final busy = c.adding.value;
                                  return OutlinedButton(
                                    onPressed: busy ? null : () => c.addCurrentSelectionToCart(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      side: const BorderSide(color: Colors.black, width: 1),
                                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                    ),
                                    child: busy
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                      : const Text('ADD TO CART', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.5)),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // BUY NOW
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => c.buyNow(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                            child: const Text('BUY NOW', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.5)),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // ── 6. ASK QUESTION & SHARE ────────────────────────
                        Row(
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _showAskQuestionModal(context, p),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.help_outline, size: 16, color: Colors.black45),
                                    SizedBox(width: 6),
                                    Text('ASK A QUESTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _showShareModal(context, p, images.isNotEmpty ? images.first : ''),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.share_outlined, size: 16, color: Colors.black45),
                                    SizedBox(width: 6),
                                    Text('SHARE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 16),

                        // ── 7. DELIVERY & SKU ──────────────────────────────
                        Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined, size: 16, color: Colors.black45),
                            const SizedBox(width: 8),
                            const Text('Delivery:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(width: 8),
                            Text('14 Sep - 15 Sep, 2026', style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const SizedBox(width: 24),
                            const Text('Sku:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(width: 24),
                            Obx(() {
                              final baseSku = (p['sku'] ?? 'JC5219').toString();
                              final curSz = (c.sizeLabel.value ?? c.sizeSlug.value ?? '').toUpperCase();
                              final curCol = (c.colorLabel.value ?? c.colorSlug.value ?? '').toUpperCase();
                              String fullSku = baseSku;
                              if (curSz.isNotEmpty && curCol.isNotEmpty) {
                                final cCode = curCol.length >= 3 ? curCol.substring(0, 3) : curCol;
                                fullSku = '$baseSku-$curSz-$cCode';
                              }
                              return Text(fullSku, style: const TextStyle(fontSize: 12, color: Colors.black87));
                            }),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── 8. TRUST BADGES ────────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7D7F81),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: const [
                                        Icon(Icons.replay_circle_filled_outlined, color: Color(0xFF4DB6AC), size: 24),
                                        SizedBox(height: 8),
                                        Text('7 Day Return', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                        SizedBox(height: 2),
                                        Text('No Questions Asked', style: TextStyle(color: Colors.white70, fontSize: 9)),
                                      ],
                                    ),
                                  ),
                                  Container(width: 1, height: 40, color: Colors.black26),
                                  Expanded(
                                    child: Column(
                                      children: const [
                                        Icon(Icons.local_shipping_outlined, color: Color(0xFF4DB6AC), size: 24),
                                        SizedBox(height: 8),
                                        Text('Free Shipping', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                        SizedBox(height: 2),
                                        Text('on pre-paid orders', style: TextStyle(color: Colors.white70, fontSize: 9)),
                                      ],
                                    ),
                                  ),
                                  Container(width: 1, height: 40, color: Colors.black26),
                                  Expanded(
                                    child: Column(
                                      children: const [
                                        Icon(Icons.money_outlined, color: Color(0xFF4DB6AC), size: 24),
                                        SizedBox(height: 8),
                                        Text('COD Available', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                        SizedBox(height: 2),
                                        Text('On All Orders', style: TextStyle(color: Colors.white70, fontSize: 9)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: Colors.black26, height: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Guaranteed safe checkout', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(color: const Color(0xFF1A1F71), borderRadius: BorderRadius.circular(2)),
                                        child: const Text('VISA', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2)),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.circle, color: Colors.red, size: 8),
                                            Icon(Icons.circle, color: Colors.orange, size: 8),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2)),
                                        child: const Text('UPI', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.w800)),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2)),
                                        child: const Text('COD', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── 9. ACCORDIONS (DESCRIPTION & SHIPPING/RETURNS) ──
                        Obx(() {
                          final isDescOpen = c.descExpanded.value;
                          final isShippingOpen = c.shippingExpanded.value;

                          // Get raw HTML from API field (shippingReturns)
                          final rawShipping = (p['shippingReturns'] ?? p['shippingReturnsText'] ?? p['shippingPolicy'] ?? p['shippingInfo'] ?? '').toString().trim();

                          // Detect if it's actually empty / null string
                          final isShippingEmpty = rawShipping.isEmpty ||
                              rawShipping.toLowerCase() == 'null' ||
                              rawShipping.toLowerCase() == 'undefined' ||
                              rawShipping == '[]';

                          // Default fallback HTML when admin hasn't filled the field
                          const defaultShippingHtml =
                            '<p>Orders are processed within 1-2 business days. Returns accepted within 14 days of delivery.</p>';

                          final shippingHtml = isShippingEmpty ? defaultShippingHtml : rawShipping;

                          // Raw description from API
                          final rawDesc2 = (p['fullDescription'] ?? p['description'] ?? p['shortDescription'] ?? '').toString();
                          final hasHtmlInDesc = rawDesc2.contains('<');

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (desc.isNotEmpty || rawDesc2.isNotEmpty) ...[
                                GestureDetector(
                                  onTap: () => c.descExpanded.toggle(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: const BoxDecoration(
                                      border: Border(top: BorderSide(color: Color(0xFFEEEEEE)), bottom: BorderSide(color: Color(0xFFEEEEEE))),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('DESCRIPTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black54, letterSpacing: 1.2)),
                                        Icon(isDescOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.black45, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isDescOpen)
                                  hasHtmlInDesc
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Html(
                                          data: rawDesc2,
                                          style: {
                                            'body': Style(fontSize: FontSize(13), lineHeight: LineHeight(1.6), color: Colors.black87, margin: Margins.zero, padding: HtmlPaddings.zero),
                                            'p': Style(margin: Margins.only(bottom: 8)),
                                            'li': Style(margin: Margins.only(bottom: 4)),
                                            'strong': Style(fontWeight: FontWeight.w700),
                                          },
                                        ),
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          desc,
                                          style: const TextStyle(fontSize: 13, height: 1.6, color: Colors.black87),
                                        ),
                                      ),
                              ],

                              // SHIPPING & RETURNS — renders exact HTML from admin
                              GestureDetector(
                                onTap: () => c.shippingExpanded.toggle(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: (desc.isEmpty && rawDesc2.isEmpty) ? const BorderSide(color: Color(0xFFEEEEEE)) : BorderSide.none,
                                      bottom: const BorderSide(color: Color(0xFFEEEEEE)),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('SHIPPING & RETURNS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black54, letterSpacing: 1.2)),
                                      Icon(isShippingOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.black45, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                              if (isShippingOpen)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Html(
                                    data: shippingHtml,
                                    style: {
                                      'body': Style(fontSize: FontSize(13), lineHeight: LineHeight(1.6), color: Colors.black87, margin: Margins.zero, padding: HtmlPaddings.zero),
                                      'p': Style(margin: Margins.only(bottom: 8)),
                                      'li': Style(margin: Margins.only(bottom: 6)),
                                      'strong': Style(fontWeight: FontWeight.w700),
                                      'h1': Style(fontSize: FontSize(16), fontWeight: FontWeight.w800),
                                      'h2': Style(fontSize: FontSize(15), fontWeight: FontWeight.w800),
                                      'h3': Style(fontSize: FontSize(14), fontWeight: FontWeight.w700),
                                      'a': Style(color: Colors.black87, textDecoration: TextDecoration.underline),
                                    },
                                  ),
                                ),
                            ],
                          );
                        }),
                        const SizedBox(height: 40),

                        // ── 10. RELATED PRODUCTS SECTION ──────────────────
                        Obx(() {
                          final styleItems = c.styleItWithProducts;
                          if (styleItems.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'RELATED PRODUCTS',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 260,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: styleItems.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                                  itemBuilder: (ctx, idx) {
                                    final item = styleItems[idx];
                                    final stId = (item['_id'] ?? item['id'] ?? '').toString();
                                    return SizedBox(
                                      width: 140,
                                      child: _RelatedProductCard(
                                        p: item,
                                        onTap: () => Get.to(
                                          () => ProductDetailPage(key: ValueKey(stId), productId: stId),
                                          binding: ProductDetailBinding(stId),
                                          preventDuplicates: false,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Divider(height: 1, color: Color(0xFFEEEEEE)),
                              const SizedBox(height: 24),
                            ],
                          );
                        }),

                        // ── 11. YOU MIGHT ALSO LIKE SECTION ─────────────────
                        Obx(() {
                          final rel = c.related;
                          if (rel.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'YOU MIGHT ALSO LIKE',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 260,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: rel.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                                  itemBuilder: (ctx, idx) {
                                    final item = rel[idx];
                                    final relId = (item['_id'] ?? item['id'] ?? '').toString();
                                    return SizedBox(
                                      width: 140,
                                      child: _RelatedProductCard(
                                        p: item,
                                        onTap: () => Get.to(
                                          () => ProductDetailPage(key: ValueKey(relId), productId: relId),
                                          binding: ProductDetailBinding(relId),
                                          preventDuplicates: false,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 80),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  void _openImageLightbox(BuildContext context, List<String> images, int initialIndex) {
    if (images.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.92),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _FullScreenImageViewer(
              images: images,
              initialIndex: initialIndex,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }

  void _showAskQuestionModal(BuildContext context, Map<String, dynamic> product) {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final questionCtrl = TextEditingController();

    final prodName = (product['name'] ?? product['title'] ?? 'Product').toString();
    final pId = (product['_id'] ?? product['id'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ASK A QUESTION',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.black54),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Have a question about ${HtmlDecode.text(prodName)}? Send us a message.',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Your Name *',
                labelStyle: TextStyle(fontSize: 12, color: Colors.black54),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.5)),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contactCtrl,
              decoration: const InputDecoration(
                labelText: 'Email or Mobile Number *',
                labelStyle: TextStyle(fontSize: 12, color: Colors.black54),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.5)),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: questionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Your Question / Inquiry *',
                labelStyle: TextStyle(fontSize: 12, color: Colors.black54),
                alignLabelWithHint: true,
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.5)),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final qText = questionCtrl.text.trim();
                      final uName = nameCtrl.text.trim();
                      final msg = 'Hi Tobeque, I have a question about ${HtmlDecode.text(prodName)} (ID: $pId).'
                          '${uName.isNotEmpty ? '\nName: $uName' : ''}'
                          '${qText.isNotEmpty ? '\nQuestion: $qText' : ''}';
                      Navigator.pop(ctx);
                      final ok = await openWhatsAppChat(Constent.phone, message: msg, defaultCountryCode: '91');
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open WhatsApp')),
                        );
                      }
                    },
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16, color: Colors.white),
                    label: const Text('WHATSAPP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final qText = questionCtrl.text.trim();
                      if (qText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter your question.')),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Thank you! Your question about "${HtmlDecode.text(prodName)}" has been submitted.'),
                          backgroundColor: Colors.black87,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('SUBMIT INQUIRY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showShareModal(BuildContext context, Map<String, dynamic> product, String image) {
    final prodName = (product['name'] ?? product['title'] ?? 'Product').toString();
    final pId = (product['_id'] ?? product['id'] ?? '').toString();
    final shareLink = 'https://tobeque.com/product/$pId';
    final shareText = 'Check out ${HtmlDecode.text(prodName)} on Tobeque!\n$shareLink';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SHARE PRODUCT',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.black54),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  if (image.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: image,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      HtmlDecode.text(prodName),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Color(0xFF25D366), shape: BoxShape.circle),
                child: const FaIcon(FontAwesomeIcons.whatsapp, size: 18, color: Colors.white),
              ),
              title: const Text('Share on WhatsApp', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: const Text('Send directly to your WhatsApp contacts', style: TextStyle(fontSize: 11, color: Colors.black45)),
              onTap: () async {
                Navigator.pop(ctx);
                final waUri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(shareText)}');
                if (await canLaunchUrl(waUri)) {
                  await launchUrl(waUri, mode: LaunchMode.externalApplication);
                } else {
                  final waWeb = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(shareText)}');
                  await launchUrl(waWeb, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                child: const Icon(Icons.copy_rounded, size: 18, color: Colors.white),
              ),
              title: const Text('Copy Link', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: Text(shareLink, style: const TextStyle(fontSize: 11, color: Colors.black45), maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                Clipboard.setData(ClipboardData(text: shareLink));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product link copied to clipboard!')),
                );
              },
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Color(0xFF1976D2), shape: BoxShape.circle),
                child: const Icon(Icons.mail_outline_rounded, size: 18, color: Colors.white),
              ),
              title: const Text('Share via Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: const Text('Send an email with product details', style: TextStyle(fontSize: 11, color: Colors.black45)),
              onTap: () async {
                Navigator.pop(ctx);
                final mailUri = Uri.parse('mailto:?subject=${Uri.encodeComponent('Check out ${HtmlDecode.text(prodName)} on Tobeque')}&body=${Uri.encodeComponent(shareText)}');
                if (await canLaunchUrl(mailUri)) {
                  await launchUrl(mailUri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showSizeGuideModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Size Guide (Inches)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            Table(
              border: TableBorder.all(color: const Color(0xFFEEEEEE)),
              children: const [
                TableRow(
                  decoration: BoxDecoration(color: Color(0xFFF5F5F5)),
                  children: [
                    Padding(padding: EdgeInsets.all(8.0), child: Text('Size', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(8.0), child: Text('Bust', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(8.0), child: Text('Waist', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(8.0), child: Text('Hips', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                TableRow(children: [
                  Padding(padding: EdgeInsets.all(8.0), child: Text('XS')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('32"')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('26"')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('35"')),
                ]),
                TableRow(children: [
                  Padding(padding: EdgeInsets.all(8.0), child: Text('S')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('34"')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('28"')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('37"')),
                ]),
                TableRow(children: [
                  Padding(padding: EdgeInsets.all(8.0), child: Text('M')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('36"')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('30"')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('39"')),
                ]),
                TableRow(children: [
                  Padding(padding: EdgeInsets.all(8.0), child: Text('L')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('38"')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('32"')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('41"')),
                ]),
                TableRow(children: [
                  Padding(padding: EdgeInsets.all(8.0), child: Text('XL')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('40"')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('34"')),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('43"')),
                ]),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Smooth Full Screen Image Viewer Widget with Pinch-to-Zoom & Pull Down Gesture
/// ─────────────────────────────────────────────────────────────────────────────
class _FullScreenImageViewer extends StatefulWidget {
  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late final PageController _pageCtrl;
  bool _isZoomed = false;
  int _pointers = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onZoomChanged(bool isZoomed) {
    if (_isZoomed != isZoomed) {
      setState(() {
        _isZoomed = isZoomed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool disableScroll = _isZoomed || _pointers >= 2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background dismiss tap detector
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!_isZoomed) {
                Navigator.of(context).pop();
              }
            },
            child: Container(color: Colors.black),
          ),

          // Swipable + Zoomable Image Carousel with Multi-Touch Pointer Listener
          Listener(
            onPointerDown: (_) {
              setState(() {
                _pointers++;
              });
            },
            onPointerUp: (_) {
              setState(() {
                _pointers = (_pointers - 1).clamp(0, 10);
              });
            },
            onPointerCancel: (_) {
              setState(() {
                _pointers = (_pointers - 1).clamp(0, 10);
              });
            },
            child: PageView.builder(
              controller: _pageCtrl,
              physics: disableScroll
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _isZoomed = false;
                  _currentPage = index;
                });
              },
              itemBuilder: (context, i) {
                return _ZoomableImageItem(
                  key: ValueKey(widget.images[i]),
                  imageUrl: widget.images[i],
                  onZoomChanged: _onZoomChanged,
                  onDismiss: () => Navigator.of(context).pop(),
                );
              },
            ),
          ),

          // Top Right Close Icon Button
          // Close Button (Top Right)
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 1),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Smooth Dot Indicator (Bottom Center) — only shown when multiple images
          if (widget.images.length > 1)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedSmoothIndicator(
                  activeIndex: _currentPage,
                  count: widget.images.length,
                  effect: const ExpandingDotsEffect(
                    dotHeight: 7,
                    dotWidth: 7,
                    expansionFactor: 3,
                    spacing: 6,
                    activeDotColor: Colors.white,
                    dotColor: Colors.white38,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ZoomableImageItem extends StatefulWidget {
  final String imageUrl;
  final ValueChanged<bool> onZoomChanged;
  final VoidCallback onDismiss;

  const _ZoomableImageItem({
    super.key,
    required this.imageUrl,
    required this.onZoomChanged,
    required this.onDismiss,
  });

  @override
  State<_ZoomableImageItem> createState() => _ZoomableImageItemState();
}

class _ZoomableImageItemState extends State<_ZoomableImageItem> with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  TapDownDetails? _doubleTapDetails;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    widget.onZoomChanged(scale > 1.05);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    final position = _doubleTapDetails?.localPosition ?? Offset.zero;
    final currentScale = _transformationController.value.getMaxScaleOnAxis();

    final Matrix4 endMatrix;
    if (currentScale > 1.05) {
      endMatrix = Matrix4.identity();
    } else {
      const double targetScale = 2.5;
      final x = -position.dx * (targetScale - 1);
      final y = -position.dy * (targetScale - 1);

      endMatrix = Matrix4.identity()
        ..translate(x, y, 0.0)
        ..scale(targetScale, targetScale, 1.0);
    }

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 1.0,
      maxScale: 5.0,
      clipBehavior: Clip.none,
      panEnabled: true,
      scaleEnabled: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final currentScale = _transformationController.value.getMaxScaleOnAxis();
          if (currentScale <= 1.05) {
            widget.onDismiss();
          }
        },
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: SizedBox.expand(
          child: Center(
            child: CachedNetworkImage(
              imageUrl: widget.imageUrl,
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
              errorWidget: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.black87),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ],
    );
  }
}

class _RelatedProductCard extends StatelessWidget {
  const _RelatedProductCard({required this.p, required this.onTap});
  final Map<String, dynamic> p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = (p['name'] ?? p['title'] ?? '').toString();
    final imgs = (p['images'] as List?) ?? const [];
    String? imgUrl;
    if (imgs.isNotEmpty) {
      final first = imgs.first;
      if (first is Map) {
        imgUrl = (first['imageUrl'] ?? first['url'] ?? first['src'])?.toString();
      } else {
        imgUrl = first?.toString();
      }
    }
    imgUrl ??= p['thumbnail']?.toString() ?? p['featuredImage']?.toString();
    final fullImg = ApiConstant.getImageUrl(imgUrl);

    final priceVal = p['price'] ?? p['discountPrice'] ?? p['regularPrice'];
    final priceStr = priceVal != null ? '₹$priceVal' : '';

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: fullImg,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, __) => _ShimmerBox(),
                errorWidget: (_, __, ___) => Container(color: const Color(0xFFF5F5F5)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            HtmlDecode.text(name).toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (priceStr.isNotEmpty)
                Text(
                  priceStr,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              const Spacer(),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12, width: 1),
                  color: guessColor(name) ?? const Color(0xFF5B6B7C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Opens a full-screen image lightbox with swipe support and pinch-to-zoom.
void _openImageLightbox(BuildContext context, List<String> images, int initialIndex) {
  final PageController pageCtrl = PageController(initialPage: initialIndex);

  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black,
      fullscreenDialog: true,
      pageBuilder: (ctx, animation, _) {
        return FadeTransition(
          opacity: animation,
          child: _ImageLightboxPage(
            images: images,
            initialIndex: initialIndex,
            pageController: pageCtrl,
          ),
        );
      },
    ),
  );
}

class _ImageLightboxPage extends StatefulWidget {
  const _ImageLightboxPage({
    required this.images,
    required this.initialIndex,
    required this.pageController,
  });
  final List<String> images;
  final int initialIndex;
  final PageController pageController;

  @override
  State<_ImageLightboxPage> createState() => _ImageLightboxPageState();
}

class _ImageLightboxPageState extends State<_ImageLightboxPage> {
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
  }

  @override
  void dispose() {
    widget.pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.images.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 12),
              child: Text(
                '${_current + 1} / ${widget.images.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: PageView.builder(
          controller: widget.pageController,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (ctx, i) {
            return GestureDetector(
              onTap: () {}, // prevent tap-to-close on image itself
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: Center(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.90,
                    width: MediaQuery.of(context).size.width,
                    child: Hero(
                      tag: 'product_image_${widget.images[i]}',
                      child: CachedNetworkImage(
                        imageUrl: widget.images[i],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white30,
                          size: 56,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: widget.images.length > 1
          ? Container(
              color: Colors.black,
              padding: const EdgeInsets.only(bottom: 24, top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) {
                  final active = i == _current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            )
          : null,
    );
  }
}

class _CartBadgeDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CartBadgeController>(tag: 'cart-badge')) return const SizedBox.shrink();
    final controller = Get.find<CartBadgeController>(tag: 'cart-badge');
    return Obx(() {
      final count = controller.count.value;
      if (count <= 0) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
        child: Text(
          '$count',
          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
        ),
      );
    });
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({this.width, this.height, this.borderRadius = 4});
  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEEEEE),
      highlightColor: const Color(0xFFFAFAFA),
      child: Container(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class _PdpSkeletonLoader extends StatelessWidget {
  const _PdpSkeletonLoader();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(width: w, height: MediaQuery.of(context).size.height * 0.80, borderRadius: 0),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: 80, height: 12),
                const SizedBox(height: 8),
                _ShimmerBox(width: w * 0.75, height: 22),
                const SizedBox(height: 14),
                _ShimmerBox(width: 110, height: 26),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),
                _ShimmerBox(width: 90, height: 14),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ShimmerBox(width: 50, height: 44),
                    const SizedBox(width: 10),
                    _ShimmerBox(width: 50, height: 44),
                    const SizedBox(width: 10),
                    _ShimmerBox(width: 50, height: 44),
                  ],
                ),
                const SizedBox(height: 24),
                _ShimmerBox(width: w, height: 100, borderRadius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
