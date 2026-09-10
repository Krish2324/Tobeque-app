import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tobeque/view/home/widgets/footer_section.dart';
import 'package:tobeque/view/home/widgets/promo_banner.dart';
import 'package:tobeque/view/wishlist/wish_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chewie/chewie.dart';
import 'package:intl/intl.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';


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
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                expandedTitleScale: 2.2,
                title:  Text(
                  'TOBEQUE',
                  style: TextStyle(
                    fontSize: 30,
                    color: Colors.white,
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
// SECTION 1 — SHOP BY CATEGORY  (2-column portrait grid)
// ═══════════════════════════════════════════════════════════
SliverToBoxAdapter(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Section heading
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SHOP BY', style: TextStyle(fontSize: 11, letterSpacing: 3, color: Colors.black45, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Category', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              ],
            ),
          ],
        ),
      ),
      // 2-column category grid
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: _CategoryGrid(cats: c.cats),
      ),
      const SizedBox(height: 32),
    ],
  ),
),

// ═══════════════════════════════════════════════════════════
// SECTION 2 — NEW ARRIVALS heading + horizontal product scroll
// ═══════════════════════════════════════════════════════════
SliverToBoxAdapter(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Divider
      Container(height: 1, color: const Color(0xFFF0F0F0)),
      const SizedBox(height: 28),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TRENDING NOW', style: TextStyle(fontSize: 11, letterSpacing: 3, color: Colors.black45, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('New Arrivals', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              ],
            ),
            GestureDetector(
              onTap: () {/* Navigate to all products */},
              child: Text('View all', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54, decoration: TextDecoration.underline)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ],
  ),
),
SliverToBoxAdapter(
  child: _InterestSection(products: c.best),
),

// ═══════════════════════════════════════════════════════════
// SECTION 3 — Editorial dark CTA banner
// ═══════════════════════════════════════════════════════════
SliverToBoxAdapter(
  child: _EditorialBanner(),
),

 SliverToBoxAdapter(child: StoreFooterTobeque(
  onSubscribe: () { /* open subscribe flow */ },
  onCall: () { /* launch phone */ },
  onChat: () { /* open chat */ },
  onPrivacy: () { /* navigate */ },
  onTerms: () { /* navigate */ },
  onCookies: () { /* navigate */ },
  onCookieSettings: () { /* navigate */ },
  appVersion: '1.0.0',
)),
          ],
        ),
      );
    });
  }
}

/* ═══════════════════════════════════════════════════════════════
   CATEGORY GRID  — 2-column tall portrait cards
   ═══════════════════════════════════════════════════════════════ */

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.cats});
  final List<WcCategory> cats;

  @override
  Widget build(BuildContext context) {
    if (cats.isEmpty) return const SizedBox.shrink();
    // Show in pairs (2 columns)
    final rows = (cats.length / 2).ceil();
    return Column(
      children: List.generate(rows, (row) {
        final leftIdx  = row * 2;
        final rightIdx = row * 2 + 1;
        final leftCat  = cats[leftIdx];
        final rightCat = rightIdx < cats.length ? cats[rightIdx] : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(child: _CategoryCard(cat: leftCat)),
              const SizedBox(width: 10),
              Expanded(
                child: rightCat != null
                    ? _CategoryCard(cat: rightCat)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.cat});
  final WcCategory cat;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => CategoryPage(categoryId: cat.id, title: cat.name)),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              if (cat.image != null && cat.image!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: cat.image!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (_, __) => _ShimmerBox(),
                  errorWidget: (_, __, ___) => Container(color: const Color(0xFFEEEEEE)),
                )
              else
                Container(color: const Color(0xFFF0F0F0)),

              // Gradient overlay (bottom-heavy for text legibility)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.18),
                      Colors.black.withOpacity(0.72),
                    ],
                    stops: const [0.4, 0.72, 1.0],
                  ),
                ),
              ),

              // Category label at bottom
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          'SHOP',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
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
      margin: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 36),
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
  bool _minHoldElapsed = false; // short hold to avoid flicker
  bool _precacheDone = false; // short hold to avoid flicker
  final PageController _pageController = PageController();
  int _currentPage = 0;

 @override
  void initState() {
    super.initState();
    // small minimum hold
    Future.delayed(const Duration(milliseconds: 2700), () {
      if (mounted) setState(() => _minHoldElapsed = true);
    });

    // Alternative fix (works too):
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (mounted) precacheImage(const AssetImage('assets/home.png'), context);
    // });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Safe place to use context-dependent lookups like MediaQuery
    if (!_precacheDone) {
      precacheImage(const AssetImage('assets/home.png'), context);
      _precacheDone = true;
    }
  }


  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bottom overlay (kept empty for now)
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

    Widget placeholder() => Image.asset(
          'assets/home.png',
          fit: BoxFit.fitHeight,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );

    Widget fallbackImage() {
      final banners = widget.controller.heroData.value?.mobileBanners ?? [];
      
      if (banners.isEmpty) {
        final img = widget.imageFallback ?? '';
        if (img.isEmpty) return placeholder();
        return Stack(
          fit: StackFit.expand,
          children: [
            placeholder(),
            Image.network(
              img,
              fit: BoxFit.fill,
              loadingBuilder: (c, child, p) => p == null ? child : const SizedBox.shrink(),
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ],
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
              return Stack(
                fit: StackFit.expand,
                children: [
                  placeholder(),
                  Image.network(
                    banners[index],
                    fit: BoxFit.fill,
                    loadingBuilder: (c, child, p) => p == null ? child : const SizedBox.shrink(),
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ],
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
            final keepPlaceholder = stillLoading || !_minHoldElapsed;
            return Stack(
              fit: StackFit.expand,
              children: [
                YoutubePlayer(controller: widget.controller.ytCtl!, aspectRatio: 16 / 9),
                if (keepPlaceholder) placeholder(),
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
      final keepPlaceholder = !isReady || !_minHoldElapsed;

      return cover(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isReady) Chewie(controller: widget.controller.chewieCtl!),
            if (keepPlaceholder) placeholder(),
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
                    Image.network(imageUrl!, fit: BoxFit.cover),


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

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.p});
  final WcProduct p;

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
    return decoded.replaceAll(RegExp(r'([.,])00\b'), '');
  }

  @override
  Widget build(BuildContext context) {
    final name  = _decodeEntities(p.name).trim();
    final img   = (p.image ?? '').trim();
    final price = _priceFor(p);

    return GestureDetector(
      onTap: () => Get.to(
        () => ProductDetailPage(key: ValueKey(p.id), productId: p.id),
        binding: ProductDetailBinding(p.id),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── PORTRAIT IMAGE ──────────────────────────────────
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (img.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: img,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (_, __) => _ShimmerBox(),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFF0F0F0),
                        child: const Icon(Icons.image_not_supported_outlined,
                            color: Colors.black26, size: 32),
                      ),
                    )
                  else
                    _ShimmerBox(),

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

          // ── NAME + PRICE ─────────────────────────────────────
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          if (price.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              price,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
          const SizedBox(height: 8),
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