import 'dart:math' as math;
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
        return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.black)));
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


// === Category posters (HORIZONTAL, large, shows ALL) ===
SliverToBoxAdapter(
  child: SizedBox(
    height: 225, // tweak for bigger/smaller posters
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
      itemCount: c.cats.length,
      separatorBuilder: (_, __) => const SizedBox(width: 1),
      itemBuilder: (_, i) {
        final cat = c.cats[i];
        return SizedBox(
          width: 165, // big width; adjust to taste
          child: Padding(
            padding: const EdgeInsets.only(top: 4,right: 4),
            child: _CategoryPosterCard(
              title: cat.name,
              imageUrl: cat.image,
              onTap: () => Get.to(() =>
                CategoryPage(categoryId: cat.id, title: cat.name)),
            ),
          ),
        );
      },
    ),
  ),
)
,
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.only(top: 4),
    child: PromoBanner(
    assetPath: 'assets/girl2.png',
    title: 'jackets and\ncoats',
    onTap: () {
      // navigate to your Jackets/Coats category
      // e.g. Get.to(() => CategoryPage(...));
    },
    ),
  ),
),


// === GET THE LOOK heading ===
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
         // textBaseline: TextBaseline.alphabetic,
          children: const [
            Padding(
              padding: EdgeInsets.only(bottom: 3),
              child: Icon(Icons.arrow_forward,size: 25,weight: 25,),
            ),
            SizedBox(width: 5),
            Text(
              'Something you’ll love!',

              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.0,
                   overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
   
      ],
    ),
  ),
)
,

// --- “Get the look” grid (2×2, only 4 items, no price) ---
SliverToBoxAdapter(
  child: _InterestSection(products: c.best),
),


SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.only(top: 0),
    child: PromoBanner(
    assetPath: 'assets/girl3.png',
    title: 'Jeans and\ntop',
    onTap: () {
      // navigate to your Jackets/Coats category
      // e.g. Get.to(() => CategoryPage(...));
    },
    ),
  ),
),


 SliverToBoxAdapter(child:  StoreFooterTobeque(
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
  bool _precacheDone = false;// short hold to avoid flicker

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
      final img = widget.imageFallback ?? '';
      if (img.isEmpty) return placeholder();
      return Stack(
        fit: StackFit.expand,
        children: [
          placeholder(), // show asset first
          Image.network(
            img,
            fit: BoxFit.fill,
            loadingBuilder: (c, child, p) => p == null ? child : const SizedBox.shrink(),
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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

    return SizedBox(
      height: 380,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (_, i) => SizedBox(
          width: screenW / 2,
          child: _ProductCard(p: products[i]),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 4),
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

  String _trimZeroCents(String s) => s.replaceAll(RegExp(r'([.,])00\b'), '');

  String _priceFor(WcProduct p) {
    final html = p.priceHtml;
    if (html == null || html.isEmpty) return '';
    final stripped = html.replaceAll(RegExp(r'<[^>]*>'), '');
    var decoded = _decodeEntities(stripped).trim();
    decoded = decoded.replaceFirstMapped(RegExp(r'^([^\d\s]+)(\d)'), (m) => '${m[1]} ${m[2]}');
    return _trimZeroCents(decoded);
  }

  @override
  Widget build(BuildContext context) {
    final name = _decodeEntities(p.name).trim();
    final img  = (p.image ?? '').trim();
    final price = _priceFor(p);

    return InkWell(
      onTap: () => Get.to(
        () => ProductDetailPage(key: ValueKey(p.id), productId: p.id),
        binding: ProductDetailBinding(p.id),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE + OVERLAYED HEART (Positioned inside Stack ✅)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: AspectRatio(
                aspectRatio: 2 / 1.1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (img.isNotEmpty)
                      Image.network(
                        img,
                        fit: BoxFit.cover,
                        loadingBuilder: (c, child, p) =>
                            p == null ? child : const ColoredBox(color: Color(0xFFEDEDED)),
                        errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFF2F2F2)),
                      )
                    else
                      const ColoredBox(color: Color(0xFFF2F2F2)),

                    // bottom-right (or change to left) heart
                   
                  ],
                ),
              ),
            ),
          ),
      

// Title + price (left)  •  Heart (right)
Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    // LEFT: name + price
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // name
          Text(
            name, // make sure you pass a decoded name
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.7),
          ),
          // price
          if (price.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              price,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.7),
            ),
          ],
        ],
      ),
    ),

    const SizedBox(width: 8),

    // RIGHT: heart (wishlist)
    Padding(
      padding: const EdgeInsets.only(right:4.0,bottom: 10),
      child: SizedBox(
            
        child: WishButton.fromProduct(
          p,
          size: 22,                       // adjust if you want bigger/smaller
          activeColor: Colors.redAccent,  // filled heart color
          inactiveColor: Colors.black54,  // outline color
        ),
      ),
    ),
  ],
),
SizedBox(
  height: 8,
)
        ],
      ),
    );
  }
}