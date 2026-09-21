import 'dart:async';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/view/home/widgets/footer_section.dart';
import 'package:tobeque/view/home/widgets/promo_banner.dart';
import 'package:tobeque/view/wishlist/wish_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';


import 'package:tobeque/componant/helper.dart';

import '../cetegory/category_page.dart';
import '../prodduct_details/product_detail_binding.dart';
import '../prodduct_details/product_details_page.dart';
import 'controller/home_controller.dart';
import 'models.dart';

class HomePageView extends StatelessWidget {
  const HomePageView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(HomeController()); // no Binding file

    return Obx(() {
      if (c.loading.value) {
        return const Scaffold(
          backgroundColor: Colors.white,
          body: _HomeSkeletonLoader(),
        );
      }
      if (c.error.value != null) {
        // ⬇️ Error page with pull-to-refresh AND a retry button
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: c.refreshHome,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text('Something went wrong',
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  c.error.value!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 22),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: c.refreshHome,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        body: CustomScrollView(
          slivers: [
            // ===== HERO (video or image) with collapsing title =====
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              expandedHeight: MediaQuery.of(context).size.height * 0.74,
              backgroundColor: Colors.transparent,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              foregroundColor: Colors.black,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                expandedTitleScale: 2.2,
                title: const Text(
                  'TOBEQUE',
                  style: TextStyle(
                    fontSize: 30,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                background: _HeroMedia(
                  controller: c,
                  imageFallback: c.heroData.value?.imageUrl,
                ),
              ),
            ),
// === PROMO title + dots (under hero) ===
// const SliverToBoxAdapter(
//   child: Padding(
//     padding: EdgeInsets.only(top: 12, bottom: 16),
//     child: Column(
//       children: [
//         Text(
//           'special prices',
//           style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: .3),
//         ),
       
//       ],
//     ),
//   ),
// ),
// ═══════════════════════════════════════════════════════════
// SECTION 1 — SHOP BY CATEGORY
// ═══════════════════════════════════════════════════════════
SliverToBoxAdapter(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const SizedBox(height: 18),
      const _SectionHeaderWidget(subtitle: 'Shop By', title: 'Category'),
      const SizedBox(height: 14),
      _CategoryGrid(cats: c.cats),
      const SizedBox(height: 20),
    ],
  ),
),

// ═══════════════════════════════════════════════════════════
// SECTION 2 — HAND-PICKED FEATURED PICKS (Paginated 6 Initial Items)
// ═══════════════════════════════════════════════════════════
SliverToBoxAdapter(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const SizedBox(height: 8),
      const _SectionHeaderWidget(subtitle: 'Hand-Picked', title: 'Featured Picks'),
      const SizedBox(height: 14),
    ],
  ),
),
SliverPadding(
  padding: const EdgeInsets.symmetric(horizontal: 4),
  sliver: Obx(() {
    final list = c.best;
    if (list.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    final displayCount = math.min(c.visibleFeaturedCount.value, list.length);
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.63,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _ProductCard(p: list[index]),
        childCount: displayCount,
      ),
    );
  }),
),
SliverToBoxAdapter(
  child: Obx(() {
    final list = c.best;
    if (list.isEmpty) return const SizedBox.shrink();
    final hasMore = c.visibleFeaturedCount.value < list.length;
    if (hasMore) {
      final remaining = list.length - c.visibleFeaturedCount.value;
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
          child: OutlinedButton.icon(
            onPressed: c.loadMoreFeatured,
            icon: const Icon(Icons.add, size: 14, color: Colors.black),
            label: Text(
              'LOAD MORE PRODUCTS ($remaining MORE)',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
                color: Colors.black,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              side: const BorderSide(color: Colors.black, width: 1.5),
              shape: const StadiumBorder(),
              backgroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      child: Text(
        'ALL ${list.length} FEATURED PRODUCTS LOADED',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: Color(0xFF757575),
        ),
      ),
    );
  }),
),

// ═══════════════════════════════════════════════════════════
// SECTION 3 — PROMO BANNER (Full-Bleed Summer Trend Banner)
// ═══════════════════════════════════════════════════════════
SliverToBoxAdapter(
  child: _PromoBannerWidget(controller: c),
),

// ═══════════════════════════════════════════════════════════
// SECTION 4 — ON SALE SECTION
// ═══════════════════════════════════════════════════════════
SliverToBoxAdapter(
  child: Obx(() => c.onSale.isNotEmpty
      ? _OnSaleSection(products: c.onSale)
      : const SizedBox.shrink()),
),

// ═══════════════════════════════════════════════════════════
// SECTION 5 — HOT RIGHT NOW SECTION (SEE WHAT'S TRENDING)
// ═══════════════════════════════════════════════════════════
SliverToBoxAdapter(
  child: Obx(() => c.hotRightNow.isNotEmpty
      ? _HotRightNowSection(products: c.hotRightNow)
      : const SizedBox.shrink()),
),
SliverToBoxAdapter(child: const SizedBox(height: 6)),

// ═══════════════════════════════════════════════════════════
// SECTION 6 — FOOTER
// ═══════════════════════════════════════════════════════════
SliverToBoxAdapter(
  child: StoreFooterTobeque(
    onSubscribe: () { /* open subscribe flow */ },
    onCall: () { /* launch phone */ },
    onChat: () { /* open chat */ },
    onPrivacy: () { /* navigate */ },
    onTerms: () { /* navigate */ },
    onCookies: () { /* navigate */ },
    onCookieSettings: () { /* navigate */ },
    appVersion: '1.0.0',
  ),
),
          ],
        ),
      );
    });
  }
}

/* ═══════════════════════════════════════════════════════════════
   CATEGORY GRID  — Tall portrait cards matching website
   ═══════════════════════════════════════════════════════════════ */

class _CategoryGrid extends StatefulWidget {
  const _CategoryGrid({required this.cats});
  final List<WcCategory> cats;

  @override
  State<_CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<_CategoryGrid> {
  final ScrollController _scroll = ScrollController();
  Timer? _timer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!_scroll.hasClients || widget.cats.isEmpty || _isUserInteracting) return;
      _scroll.jumpTo(_scroll.offset + 1.0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cats.isEmpty) return const SizedBox.shrink();
    // Large virtual item count for seamless continuous looping without rewinding
    const virtualCount = 10000;

    return SizedBox(
      height: 180,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notif) {
          if (notif is ScrollStartNotification && notif.dragDetails != null) {
            _isUserInteracting = true;
          } else if (notif is ScrollEndNotification) {
            _isUserInteracting = false;
          }
          return false;
        },
        child: ListView.separated(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          itemCount: virtualCount,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, index) => _CategoryCard(cat: widget.cats[index % widget.cats.length]),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.cat});
  final WcCategory cat;

  @override
  Widget build(BuildContext context) {
    final imgUrl = cat.image ?? '';

    return GestureDetector(
      onTap: () => Get.to(() => CategoryPage(categoryId: cat.id, title: cat.name)),
      child: Container(
        width: 134,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imgUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imgUrl,
                  memCacheWidth: 350,
                  maxWidthDiskCache: 350,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const _ShimmerBox(),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFFF2F2F2),
                    child: const Icon(Icons.style_outlined, color: Colors.black26, size: 28),
                  ),
                )
              else
                Container(
                  color: const Color(0xFFF2F2F2),
                  child: const Icon(Icons.style_outlined, color: Colors.black26, size: 28),
                ),

              // Dark bottom gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

              // Bottom Category Name Label (matching website design)
              Positioned(
                bottom: 12,
                left: 10,
                right: 10,
                child: Text(
                  cat.name.toUpperCase(),
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    height: 1.15,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ═══════════════════════════════════════════════════════════════
   EDITORIAL BANNER  — dark full-width CTA
   ═══════════════════════════════════════════════════════════════ */

class _EditorialBanner extends StatelessWidget {
  const _EditorialBanner();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      width: w,
      margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXCLUSIVELY\nCURATED FOR YOU',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Container(width: 40, height: 2, color: Colors.white30),
          const SizedBox(height: 16),
          const Text(
            'Discover the latest in women\'s fashion. New arrivals every week.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {/* Navigate to all products */},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Text(
                'SHOP NOW',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------- HERO MEDIA WIDGET ------------------------- */


// keep your other imports (YoutubePlayer, Chewie, etc.)

// replace your _HeroMedia with this version
class _HeroMedia extends StatefulWidget {
  const _HeroMedia({required this.controller, required this.imageFallback});
  final HomeController controller;
  final String? imageFallback;

  @override
  State<_HeroMedia> createState() => _HeroMediaState();
}

class _HeroMediaState extends State<_HeroMedia> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bottom overlay
    const overlay = Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('', style: TextStyle(color: Colors.white)),
      ),
    );

    Widget cover({required Widget child, required double childAspect}) {
      return AspectRatio(
        aspectRatio: 4 / 5,
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: 1000,
                  height: 1000 / childAspect,
                  child: child,
                ),
              ),
              overlay,
            ],
          ),
        ),
      );
    }

    Widget placeholder() => const _ShimmerBox(borderRadius: 0);

    Widget fallbackImage() {
      final banners = widget.controller.heroData.value?.mobileBanners ?? [];
      
      if (banners.isEmpty) {
        final img = widget.imageFallback ?? '';
        if (img.isEmpty) return placeholder();
        return CachedNetworkImage(
          imageUrl: ApiConstant.getImageUrl(img),
          fit: BoxFit.cover,
          placeholder: (_, __) => placeholder(),
          errorWidget: (_, __, ___) => placeholder(),
        );
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) {
              setState(() {
                _currentPage = idx;
              });
            },
            itemCount: banners.length,
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: ApiConstant.getImageUrl(banners[index]),
                fit: BoxFit.cover,
                placeholder: (_, __) => placeholder(),
                errorWidget: (_, __, ___) => placeholder(),
              );
            },
          ),
          if (banners.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(banners.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      );
    }

    final url = widget.controller.heroVideoUrl.value;

    // No media URL → show asset (or network fallback) full-bleed
    if (url == null || url.isEmpty) {
      return AspectRatio(
        aspectRatio: 4 / 5,
        child: Stack(fit: StackFit.expand, children: [fallbackImage(), overlay]),
      );
    }

    final kind = widget.controller.detectUrlKind(url);

    // --------------------- YouTube branch ---------------------
    if (kind == MediaKind.youtube && widget.controller.ytCtl != null) {
      return cover(
        child: IgnorePointer(
          child: Obx(() {
            final stillLoading = widget.controller.showYTPlaceholder.value;
            return Stack(
              fit: StackFit.expand,
              children: [
                YoutubePlayer(controller: widget.controller.ytCtl!, aspectRatio: 16 / 9),
                if (stillLoading) placeholder(),
              ],
            );
          }),
        ),
        childAspect: 16 / 9,
      );
    }

    // ------------------ Direct file (Chewie) branch ------------------
    if (kind == MediaKind.directFile && widget.controller.videoCtl != null) {
      final isReady = widget.controller.videoCtl!.value.isInitialized;
      final ar = isReady
          ? widget.controller.videoCtl!.value.aspectRatio
          : (16 / 9);

      return cover(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isReady) Chewie(controller: widget.controller.chewieCtl!),
            if (!isReady) placeholder(),
          ],
        ),
        childAspect: ar,
      );
    }

    // Unknown kind → placeholder/fallback
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Stack(fit: StackFit.expand, children: [fallbackImage(), overlay]),
    );
  }
}



/* ------------------------- CATEGORY CARD ------------------------- */

class _CategoryPosterCard extends StatelessWidget {
  const _CategoryPosterCard({
    required this.title,
    required this.imageUrl,
    this.onTap,
  });

  final String title;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 3 / 4, // tall poster
        child: Container(
         
          child: LayoutBuilder(
            builder: (_, cts) {
              final w = cts.maxHeight;
             
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 600,
                      maxWidthDiskCache: 600,
                      placeholder: (_, __) => const _ShimmerBox(),
                      errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFFF2F2F2)),
                    ),


                    const DecoratedBox(
  decoration: BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(0, -0.05), // a hair above center
      radius: 1.15,                // >1 so it reaches all corners
      colors: [
        Color(0x00000000),         // fully transparent center
        Color(0x42000000),         // ~26% black at edges (ARGB 66)
      ],
      stops: [0.40, 1.0],          // start fading ~40% from center
    ),
  ),
),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                         gradient: RadialGradient(
      center: Alignment.center, // start at center
      radius: 0,             // >1 so it reaches the corners
      colors: [
        Color.fromARGB(0, 0, 0, 0),   // fully transparent in the middle
        Color.fromARGB(66, 0, 0, 0),  // soft dark at the edges
      ],
      stops: [0.40, 1.0], // where the fade starts and ends
    ),
                    ),
                  ),
                  Padding(
                    padding:  EdgeInsets.only(top: w/2.4),
                    child: Text(
                      title.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        height: 1.05,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}


class _InterestSection extends StatelessWidget {
  const _InterestSection({required this.products});
  final List<WcProduct> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    final screenW = MediaQuery.of(context).size.width;
    final cardW   = screenW * 0.46;

    return SizedBox(
      height: cardW * (4 / 3) + 72, // portrait image + label area
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (_, i) => SizedBox(
          width: cardW,
          child: _ProductCard(p: products[i]),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: products.length,
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  const _ProductCard({required this.p});
  final WcProduct p;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  int _imgIndex = 0;
  final PageController _pc = PageController();

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  String _decodeEntities(String s) {
    var out = s.replaceAll('&nbsp;', ' ').replaceAll('&amp;', '&');
    out = out.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final code = int.tryParse(m.group(1)!);
      return code != null ? String.fromCharCode(code) : m.group(0)!;
    });
    return out;
  }

  String _priceFor(WcProduct p) {
    final html = p.priceHtml;
    if (html == null || html.isEmpty) return '';
    final stripped = html.replaceAll(RegExp(r'<[^>]*>'), '');
    var decoded = _decodeEntities(stripped).trim();
    decoded = decoded.replaceFirstMapped(RegExp(r'^([^\d\s]+)(\d)'), (m) => '${m[1]} ${m[2]}');
    return decoded.replaceFirst(RegExp(r'\.00$'), '').replaceAll('.00', '');
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final name  = _decodeEntities(p.name).trim();
    final price = _priceFor(p);
    final List<String> imgList = [];
    if (p.image != null && p.image!.isNotEmpty) {
      imgList.add(p.image!);
    }
    for (final img in p.images) {
      if (img.isNotEmpty && !imgList.contains(img)) {
        imgList.add(img);
      }
    }

    final Widget imageContent = Stack(
      fit: StackFit.expand,
      children: [
        if (imgList.isNotEmpty)
          CachedNetworkImage(
            imageUrl: imgList.first,
            memCacheWidth: 400,
            maxWidthDiskCache: 400,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (_, __) => const _ShimmerBox(),
            errorWidget: (_, __, ___) => Container(
              color: const Color(0xFFF0F0F0),
              child: const Icon(Icons.image_not_supported_outlined,
                  color: Colors.black26, size: 32),
            ),
          )
        else
          const _ShimmerBox(),
      ],
    );

    return GestureDetector(
      onTap: () => Get.to(
        () => ProductDetailPage(key: ValueKey(p.id), productId: p.id, hintImageUrl: p.image),
        binding: ProductDetailBinding(p.id),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── PORTRAIT IMAGE (SWIPEABLE) ─────────────────────
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageContent,
                  // Wishlist heart (top-right)
                  Positioned(
                    top: 8, right: 8,
                    child: WishButton.fromProduct(
                      p,
                      size: 20,
                      activeColor: Colors.redAccent,
                      inactiveColor: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── NAME + PRICE + SWATCH DOTS ────────────────────────
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B4B4B),
                      ),
                    ),
                    if (price.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Builder(builder: (_) {
                final colorSwatches = extractColorsFromProductMap(p.rawMap ?? p.toJson());
                if (colorSwatches.isEmpty) return const SizedBox.shrink();

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: colorSwatches.take(3).map((swatchData) {
                    final bool hasImage = swatchData.image != null && swatchData.image!.isNotEmpty;
                    final Color swatchColor = swatchData.color;
                    final bool isLight = swatchColor == const Color(0xFFFFFFFF) || swatchColor == const Color(0xFFFAFAFA);

                    return Container(
                      margin: const EdgeInsets.only(left: 3),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isLight ? Colors.black38 : Colors.black12,
                          width: 1,
                        ),
                        color: hasImage ? Colors.white : swatchColor,
                      ),
                      child: ClipOval(
                        child: hasImage
                            ? CachedNetworkImage(
                                imageUrl: swatchData.image!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => ColoredBox(color: swatchColor),
                                errorWidget: (_, __, ___) => ColoredBox(color: swatchColor),
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

/* ═══════════════════════════════════════════════════════════════
   SHIMMER BOX — reusable shimmer placeholder
   ═══════════════════════════════════════════════════════════════ */

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

/* ═══════════════════════════════════════════════════════════════
   HOME SKELETON LOADER — full page shimmer
   ═══════════════════════════════════════════════════════════════ */

class _HomeSkeletonLoader extends StatelessWidget {
  const _HomeSkeletonLoader();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero skeleton
          _ShimmerBox(width: w, height: h * 0.68, borderRadius: 0),

          const SizedBox(height: 28),

          // Section title skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: 70, height: 11, borderRadius: 4),
                const SizedBox(height: 6),
                _ShimmerBox(width: 140, height: 28, borderRadius: 4),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Category grid skeleton  (2 tall portrait cards)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(child: AspectRatio(aspectRatio: 3/4, child: _ShimmerBox(borderRadius: 4))),
                const SizedBox(width: 10),
                Expanded(child: AspectRatio(aspectRatio: 3/4, child: _ShimmerBox(borderRadius: 4))),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Products heading skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: 100, height: 11, borderRadius: 4),
                const SizedBox(height: 6),
                _ShimmerBox(width: 160, height: 28, borderRadius: 4),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Horizontal product cards skeleton
          SizedBox(
            height: (w * 0.46) * (4/3) + 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, __) {
                final cardW = w * 0.46;
                return SizedBox(
                  width: cardW,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _ShimmerBox(borderRadius: 4)),
                      const SizedBox(height: 8),
                      _ShimmerBox(width: cardW * 0.7, height: 13, borderRadius: 4),
                      const SizedBox(height: 5),
                      _ShimmerBox(width: cardW * 0.4, height: 13, borderRadius: 4),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 28),

          // Editorial banner skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _ShimmerBox(width: w, height: 180, borderRadius: 6),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

/* ═══════════════════════════════════════════════════════════════
   ON SALE SECTION  — horizontal slider with section header
   ═══════════════════════════════════════════════════════════════ */

class _OnSaleSection extends StatefulWidget {
  const _OnSaleSection({required this.products});
  final List<WcProduct> products;

  @override
  State<_OnSaleSection> createState() => _OnSaleSectionState();
}

class _OnSaleSectionState extends State<_OnSaleSection> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    _scroll.animateTo(
      (_scroll.offset + delta).clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) return const SizedBox.shrink();
    final screenW = MediaQuery.of(context).size.width;
    final cardW   = screenW * 0.32; // ~3 visible cards

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Section header
        const _SectionHeaderWidget(subtitle: 'Special Offers', title: 'On Sale'),
        const SizedBox(height: 14),

        // Slider with arrow buttons overlapping left/right
        Stack(
          alignment: Alignment.center,
          children: [
            // Products scroll
            SizedBox(
              height: cardW * (4 / 3) + 52,
              child: ListView.separated(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                physics: const BouncingScrollPhysics(),
                itemCount: widget.products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 3),
                itemBuilder: (_, i) => SizedBox(
                  width: cardW,
                  child: _OnSaleProductCard(p: widget.products[i]),
                ),
              ),
            ),

            // Left arrow (Luxury Circular Glassmorphism Control)
            Positioned(
              left: 6,
              child: GestureDetector(
                onTap: () => _scrollBy(-cardW),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 0.8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.black),
                ),
              ),
            ),

            // Right arrow (Luxury Circular Glassmorphism Control)
            Positioned(
              right: 6,
              child: GestureDetector(
                onTap: () => _scrollBy(cardW),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 0.8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

class _OnSaleProductCard extends StatelessWidget {
  const _OnSaleProductCard({required this.p});
  final WcProduct p;

  @override
  Widget build(BuildContext context) {
    final img   = (p.image ?? '').trim();
    final name  = p.displayName.trim();
    final price = (p.priceHtml ?? '').trim();
    final orig  = p.originalPrice;
    final hasSale = orig != null && orig.isNotEmpty;

    return GestureDetector(
      onTap: () => Get.to(
        () => ProductDetailPage(key: ValueKey(p.id), productId: p.id, hintImageUrl: img.isNotEmpty ? img : null),
        binding: ProductDetailBinding(p.id),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (img.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: img,
                      memCacheWidth: 350,
                      maxWidthDiskCache: 350,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const _ShimmerBox(),
                      errorWidget: (_, __, ___) => Container(color: const Color(0xFFF0F0F0)),
                    )
                  else
                    Container(color: const Color(0xFFF0F0F0)),

                  // Sale badge
                  if (hasSale)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        color: const Color(0xFFE53935),
                        child: Text(
                          '${p.savePercent}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0D0D0D)),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(price, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0D0D0D))),
              if (hasSale) ...[
                const SizedBox(width: 4),
                Text(
                  orig!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9E9E9E),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/* ═══════════════════════════════════════════════════════════════
   PROMO BANNER WIDGET  — Full bleed promo banner above Hot Right Now
   ═══════════════════════════════════════════════════════════════ */

class _PromoBannerWidget extends StatelessWidget {
  const _PromoBannerWidget({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bannerData = controller.bottomBanner.value;
      if (bannerData != null && bannerData.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: _BottomPromoBanner(banner: bannerData),
        );
      }

      final heroImg = controller.heroData.value?.imageUrl;
      final mobileImgs = controller.heroData.value?.mobileBanners;
      String? fallbackUrl;
      if (mobileImgs != null && mobileImgs.length > 1) {
        fallbackUrl = mobileImgs[1];
      } else if (heroImg != null && heroImg.isNotEmpty) {
        fallbackUrl = heroImg;
      }

      if (fallbackUrl == null || fallbackUrl.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: _BottomPromoBanner(
          banner: {
            'imageUrl': fallbackUrl,
            'title': 'Summer TREND',
            'subtitle': 'Discover the latest fashion. New arrivals every week.',
            'linkUrl': '/shop',
          },
        ),
      );
    });
  }
}

/* ═══════════════════════════════════════════════════════════════
   BOTTOM PROMO BANNER  — full-bleed admin-controlled banner
   ═══════════════════════════════════════════════════════════════ */

class _BottomPromoBanner extends StatelessWidget {
  const _BottomPromoBanner({required this.banner});
  final Map<String, dynamic> banner;

  bool _isVideo(String url) => url.toLowerCase().contains('.mp4') ||
      url.toLowerCase().contains('.webm') ||
      url.toLowerCase().contains('/video/');

  @override
  Widget build(BuildContext context) {
    final rawUrl  = (banner['mobileImageUrl'] ?? banner['imageUrl'] ?? '').toString();
    final imgUrl  = rawUrl.isNotEmpty ? ApiConstant.getImageUrl(rawUrl) : '';
    final title   = banner['title']?.toString() ?? '';
    final subtitle = banner['subtitle']?.toString() ?? '';
    final linkUrl  = banner['linkUrl']?.toString() ?? '';

    if (imgUrl.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: linkUrl.isNotEmpty ? () { /* TODO: navigate */ } : null,
      child: Stack(
        children: [
          // Background media
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _isVideo(imgUrl)
                ? Container(color: Colors.black) // video placeholder (Chewie handled separately)
                : CachedNetworkImage(
                    imageUrl: imgUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (_, __) => Container(color: const Color(0xFFF0F0F0)),
                    errorWidget: (_, __, ___) => Container(color: const Color(0xFFF0F0F0)),
                  ),
          ),

          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                  stops: const [0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Text overlay
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      height: 1.2,
                    ),
                  ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
                if (linkUrl.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: const BoxDecoration(color: Colors.white),
                    child: const Text(
                      'SHOP NOW',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ═══════════════════════════════════════════════════════════════
   HOT RIGHT NOW SECTION  — 9:16 portrait cards with overlay
   ═══════════════════════════════════════════════════════════════ */

class _HotRightNowSection extends StatefulWidget {
  const _HotRightNowSection({required this.products});
  final List<WcProduct> products;

  @override
  State<_HotRightNowSection> createState() => _HotRightNowSectionState();
}

class _HotRightNowSectionState extends State<_HotRightNowSection> {
  final ScrollController _scroll = ScrollController();
  Timer? _timer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!_scroll.hasClients || widget.products.isEmpty || _isUserInteracting) return;
      _scroll.jumpTo(_scroll.offset + 1.0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) return const SizedBox.shrink();
    final screenW = MediaQuery.of(context).size.width;
    final cardW   = (screenW - 11) / 2; // Exactly 2 cards visible at one time
    const virtualCount = 10000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Section header
        const _SectionHeaderWidget(subtitle: 'Trending Now', title: "See What's Trending"),
        const SizedBox(height: 14),

        // Horizontal scroll of 9:16 cards with direct physical touch detection
        SizedBox(
          height: cardW * (16 / 9),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notif) {
              if (notif is ScrollStartNotification && notif.dragDetails != null) {
                _isUserInteracting = true;
              } else if (notif is ScrollEndNotification) {
                _isUserInteracting = false;
              }
              return false;
            },
            child: ListView.separated(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              physics: const BouncingScrollPhysics(),
              itemCount: virtualCount,
              separatorBuilder: (_, __) => const SizedBox(width: 3),
              itemBuilder: (_, i) => SizedBox(
                width: cardW,
                child: _HotRightNowCard(p: widget.products[i % widget.products.length]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _HotRightNowCard extends StatelessWidget {
  const _HotRightNowCard({required this.p});
  final WcProduct p;

  @override
  Widget build(BuildContext context) {
    // prefer hotMedia (video/special image), fall back to main image
    final mediaUrl = (p.hotMedia?.isNotEmpty == true ? p.hotMedia! : p.image) ?? '';
    final thumbUrl = p.image ?? '';
    final name     = p.displayName.trim();
    final price    = p.priceHtml ?? '';
    final orig     = p.originalPrice;
    final hasSale  = orig != null && orig.isNotEmpty;
    final save     = p.savePercent;

    return GestureDetector(
      onTap: () => Get.to(
        () => ProductDetailPage(key: ValueKey(p.id), productId: p.id, hintImageUrl: thumbUrl.isNotEmpty ? thumbUrl : null),
        binding: ProductDetailBinding(p.id),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Dynamic Video/Image background with fallback to main product image
            _HotMediaWidget(
              mediaUrl: mediaUrl,
              fallbackImageUrl: thumbUrl,
            ),

            // Gradient overlay (bottom-heavy)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.4, 0.65, 1.0],
                ),
              ),
            ),

            // Product info at bottom
            Positioned(
              left: 10,
              right: 10,
              bottom: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Thumbnail
                  if (thumbUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: thumbUrl,
                        width: 40,
                        height: 52,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              price,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (hasSale) ...[
                              const SizedBox(width: 4),
                              Text(
                                orig!,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (save > 0)
                          Text(
                            'Save $save% off',
                            style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HotMediaWidget extends StatelessWidget {
  const _HotMediaWidget({required this.mediaUrl, required this.fallbackImageUrl});
  final String mediaUrl;
  final String fallbackImageUrl;

  bool get _isVideo {
    final u = mediaUrl.toLowerCase();
    if (u.endsWith('.jpg') || u.endsWith('.png') || u.endsWith('.jpeg') || u.endsWith('.webp') || u.endsWith('.gif')) return false;
    return u.endsWith('.mp4') || u.endsWith('.webm') || u.contains('.m3u8') || u.contains('/video/');
  }

  @override
  Widget build(BuildContext context) {
    final primaryImg = mediaUrl.isNotEmpty && !_isVideo ? mediaUrl : fallbackImageUrl;
    final fallbackImg = fallbackImageUrl;

    Widget imageLayer = Container(color: const Color(0xFF1A1A1A));
    if (primaryImg.isNotEmpty) {
      imageLayer = CachedNetworkImage(
        imageUrl: primaryImg,
        fit: BoxFit.cover,
        placeholder: (_, __) => const _ShimmerBox(),
        errorWidget: (_, __, ___) {
          if (fallbackImg.isNotEmpty && fallbackImg != primaryImg) {
            return CachedNetworkImage(
              imageUrl: fallbackImg,
              fit: BoxFit.cover,
              placeholder: (_, __) => const _ShimmerBox(),
              errorWidget: (_, __, ___) => Container(color: const Color(0xFF1A1A1A)),
            );
          }
          return Container(color: const Color(0xFF1A1A1A));
        },
      );
    }

    return imageLayer;
  }
}

/* ═══════════════════════════════════════════════════════════════
   UI/UX COMPONENTS — Bershka / Zara Style Modular Widgets
   ═══════════════════════════════════════════════════════════════ */

class _SectionHeaderWidget extends StatelessWidget {
  const _SectionHeaderWidget({
    required this.subtitle,
    required this.title,
  });

  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(child: Container(height: 1, color: const Color(0xFFE0E0E0))),
              const SizedBox(width: 14),
              Text(
                subtitle.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 3.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF757575),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Container(height: 1, color: const Color(0xFFE0E0E0))),
            ],
          ),
        ),
        if (title.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
              color: Colors.black,
            ),
          ),
        ],
      ],
    );
  }
}

