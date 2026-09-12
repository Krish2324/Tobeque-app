import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tobeque/utills/html_decode.dart';
import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/view/cart/cart_screen.dart';
import 'package:tobeque/view/wishlist/wish_button.dart';
import 'package:tobeque/view/root/bage_controller.dart';
import 'package:tobeque/componant/helper.dart';
import 'product_detail_controller.dart';
import 'product_detail_binding.dart';
import 'size_sheet.dart';
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
      final fabricCare = (p['fabricCare'] ?? '').toString().replaceAll(RegExp(r'<[^>]*>'), '').trim();
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
                  expandedHeight: MediaQuery.of(context).size.width * 1.25,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image PageView
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
                              onTap: () => _openImageLightbox(ctx, images, i),
                              child: CachedNetworkImage(
                                imageUrl: images[i],
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                placeholder: (_, __) => _ShimmerBox(),
                                errorWidget: (_, __, ___) => Container(
                                  color: const Color(0xFFF5F5F5),
                                  child: const Icon(Icons.broken_image_outlined, color: Colors.black26, size: 48),
                                ),
                              ),
                            );
                          },
                        ),

                        // Image Counter Pill (Top Right)
                        if (images.length > 1)
                          Positioned(
                            right: 14,
                            bottom: 16,
                            child: Obx(() => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.65),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${c.page.value + 1} / ${images.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                )),
                          ),

                        // Floating Wishlist Heart Button (Bottom Right)
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
                          HtmlDecode.text(name),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
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
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                            if (regularPrice.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              Text(
                                regularPrice,
                                style: const TextStyle(
                                  fontSize: 14,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Select Size',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black),
                              ),
                              GestureDetector(
                                onTap: () => _showSizeGuideModal(context),
                                child: const Row(
                                  children: [
                                    Icon(Icons.straighten, size: 16, color: Colors.black54),
                                    SizedBox(width: 4),
                                    Text(
                                      'Size Guide',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Obx(() {
                            final selectedSlug = c.sizeSlug.value ?? '';
                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: c.sizeOptions.map((opt) {
                                final slug = opt['slug'] ?? '';
                                final label = opt['label'] ?? slug.toUpperCase();
                                final isSelected = selectedSlug == slug;
                                final inStock = opt['inStock'] != 'false';

                                return GestureDetector(
                                  onTap: inStock
                                      ? () {
                                          c.sizeSlug.value = slug;
                                          c.sizeLabel.value = label;
                                        }
                                      : null,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 52,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.black : Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.black
                                            : (inStock ? const Color(0xFFCCCCCC) : const Color(0xFFEEEEEE)),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? Colors.white
                                            : (inStock ? Colors.black87 : Colors.black26),
                                        decoration: inStock ? null : TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          }),
                          const SizedBox(height: 20),
                        ],

                        // ── 4. ON-PAGE COLOR SELECTOR ──────────────────────
                        if (c.colorOptions.isNotEmpty) ...[
                          Row(
                            children: [
                              const Text(
                                'Select Color',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black),
                              ),
                              Obx(() {
                                final label = c.colorLabel.value;
                                if (label == null || label.isEmpty) return const SizedBox.shrink();
                                return Text(
                                  '  •  $label',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Obx(() {
                            final selectedSlug = c.colorSlug.value ?? '';
                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: c.colorOptions.map((opt) {
                                final slug = opt['slug'] ?? '';
                                final label = opt['label'] ?? slug;
                                final isSelected = selectedSlug == slug;
                                final swatchColor = guessColor(label) ?? guessColor(slug) ?? Colors.grey.shade400;
                                final isWhite = swatchColor.value == 0xFFFFFFFF;

                                return GestureDetector(
                                  onTap: () {
                                    c.colorSlug.value = slug;
                                    c.colorLabel.value = label;
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: isSelected ? Colors.black : const Color(0xFFCCCCCC),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Small circular color preview dot
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: swatchColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isWhite ? Colors.black26 : Colors.black12,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          }),
                          const SizedBox(height: 20),
                        ],

                        // ── 5. PINCODE & DELIVERY CHECKER ─────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.local_shipping_outlined, size: 20, color: Colors.black87),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delivery & Services',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFDDDDDD)),
                                      ),
                                      child: TextField(
                                        onChanged: (v) => c.pincodeText.value = v,
                                        keyboardType: TextInputType.number,
                                        maxLength: 6,
                                        decoration: const InputDecoration(
                                          hintText: 'Enter 6-digit Pincode',
                                          hintStyle: TextStyle(fontSize: 13, color: Colors.black38),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          border: InputBorder.none,
                                          counterText: '',
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    height: 44,
                                    child: ElevatedButton(
                                      onPressed: () => c.checkPincode(c.pincodeText.value),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      child: const Text('CHECK', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ),
                              Obx(() {
                                final msg = c.pincodeMsg.value;
                                final ok = c.pincodeOk.value;
                                if (msg == null) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Row(
                                    children: [
                                      Icon(
                                        ok == true ? Icons.check_circle_outline : Icons.error_outline,
                                        size: 16,
                                        color: ok == true ? Colors.green : Colors.redAccent,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          msg,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: ok == true ? Colors.green.shade800 : Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 14),

                              // Trust Badges Grid
                              const Row(
                                children: [
                                  Expanded(
                                    child: _FeatureBadge(
                                      icon: Icons.local_shipping_outlined,
                                      label: 'Free Delivery',
                                    ),
                                  ),
                                  Expanded(
                                    child: _FeatureBadge(
                                      icon: Icons.replay_30_sharp,
                                      label: '7 Days Return',
                                    ),
                                  ),
                                  Expanded(
                                    child: _FeatureBadge(
                                      icon: Icons.payments_outlined,
                                      label: 'COD Available',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 16),

                        // ── 6. EXPANDABLE DESCRIPTION ────────────────────
                        if (desc.isNotEmpty) ...[
                          const Text(
                            'Product Details',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
                          ),
                          const SizedBox(height: 8),
                          Obx(() {
                            final isExpanded = c.descExpanded.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  desc,
                                  style: const TextStyle(fontSize: 13.5, height: 1.6, color: Colors.black87),
                                  maxLines: isExpanded ? null : 4,
                                  overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => c.descExpanded.toggle(),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isExpanded ? 'Show Less' : 'Read More',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      Icon(
                                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                        size: 18,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                          const SizedBox(height: 20),
                        ],

                        // Fabric & Care
                        if (fabricCare.isNotEmpty) ...[
                          const Text(
                            'Fabric & Care',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            fabricCare,
                            style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ── 6.5 PRODUCT INQUIRY ────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Have a Question?',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Need styling advice or more details?',
                                      style: TextStyle(fontSize: 12, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final name = c.product.value?['name'] ?? 'a product';
                                  final pId = c.product.value?['_id'] ?? c.product.value?['id'] ?? '';
                                  final msg = 'Hi Tobeque, I have a question about $name (ID: $pId).';
                                  final ok = await openWhatsAppChat(Constent.phone, message: msg, defaultCountryCode: '91');
                                  if (!ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Could not open WhatsApp on this device')),
                                    );
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  side: const BorderSide(color: Colors.black),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                label: const Text('Inquire', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 24),

                        // ── 7. STYLE IT WITH SECTION ──────────────────
                        Obx(() {
                          final styleItems = c.styleItWithProducts;
                          if (styleItems.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'STYLE IT WITH',
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

                        // ── 8. RELATED PRODUCTS SECTION ─────────────────
                        if (c.related.isNotEmpty) ...[
                          const Text(
                            'YOU MAY ALSO LIKE',
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
                              itemCount: c.related.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (ctx, idx) {
                                final item = c.related[idx];
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
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── 8. STICKY BOTTOM ACTION BAR ──────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Quantity Selector
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: () {
                              if (c.qty.value > 1) c.qty.value--;
                            },
                          ),
                          Obx(() => Text(
                                '${c.qty.value}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              )),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: () => c.qty.value++,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ADD TO BAG Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: Obx(() {
                          final busy = c.adding.value;
                          return ElevatedButton.icon(
                            onPressed: busy ? null : () => c.addCurrentSelectionToCart(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            icon: busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.shopping_bag_outlined, size: 18),
                            label: Text(
                              busy ? 'ADDING...' : 'ADD TO BAG',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _openImageLightbox(BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: images.length,
              itemBuilder: (_, i) => InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: images[i],
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
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
            HtmlDecode.text(name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          if (priceStr.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              priceStr,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.black),
            ),
          ],
        ],
      ),
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
          _ShimmerBox(width: w, height: w * 1.2, borderRadius: 0),
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
