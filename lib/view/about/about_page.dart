// lib/view/about/about_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/data/dio_client.dart';

// ─── Repository ───────────────────────────────────────────────────────────────

class AboutRepository {
  final Dio _dio = DioClient.build();

  Future<Map<String, dynamic>?> fetchAboutUs() async {
    try {
      final res  = await _dio.get(ApiConstant.aboutUs);
      final data = res.data;
      if (data is Map) return data.cast<String, dynamic>();
    } catch (_) {}
    return null;
  }
}

// ─── Controller ───────────────────────────────────────────────────────────────

class AboutController extends GetxController {
  final _repo = AboutRepository();

  final loading = true.obs;
  final error   = RxnString();
  final about   = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    loading.value = true;
    error.value   = null;
    try {
      final data = await _repo.fetchAboutUs();
      about.value = data;
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AboutController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        if (c.loading.value) return _AboutSkeleton();

        final data = c.about.value ?? {};

        return CustomScrollView(
          slivers: [
            // Hero banner app bar
            SliverAppBar(
              backgroundColor: Colors.black,
              pinned: true,
              expandedHeight: MediaQuery.of(context).size.width * 0.9,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black),
                    onPressed: Get.back,
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Brand image
                    _aboutImage(data),

                    // Gradient overlay
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),

                    // Title overlay
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            data['tagline']?.toString() ?? 'Clothes for Teenagers',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              letterSpacing: 3.0,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['brand']?.toString() ?? 'TOBEQUE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content sections
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Our Story
                    _sectionTitle('OUR STORY'),
                    const SizedBox(height: 14),
                    _paragraph(data['story']?.toString() ??
                        'Tobeque is a teen fashion brand that believes style is a form of self-expression. '
                        'We create clothes that help teenagers feel confident, comfortable, and uniquely themselves.'),
                    const SizedBox(height: 36),

                    // Mission
                    if ((data['mission']?.toString() ?? '').isNotEmpty) ...[
                      _sectionTitle('OUR MISSION'),
                      const SizedBox(height: 14),
                      _paragraph(data['mission'].toString()),
                      const SizedBox(height: 36),
                    ],

                    // Values grid
                    _sectionTitle('WHY TOBEQUE'),
                    const SizedBox(height: 20),
                    _valuesGrid(),
                    const SizedBox(height: 36),

                    // Stats row
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: const Color(0xFFF6F6F5),
                      child: Row(
                        children: [
                          _StatBox(
                            number: data['productsCount']?.toString() ?? '100+',
                            label: 'Styles',
                          ),
                          _StatBox(
                            number: data['customersCount']?.toString() ?? '10K+',
                            label: 'Happy Customers',
                          ),
                          _StatBox(
                            number: data['yearsActive']?.toString() ?? '3+',
                            label: 'Years',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _aboutImage(Map<String, dynamic> data) {
    final rawImg = data['bannerImage'] ?? data['image'] ?? data['heroImage'] ?? '';
    final imgUrl = ApiConstant.getImageUrl(rawImg.toString());
    if (imgUrl.isEmpty) {
      return Container(color: const Color(0xFF0D0D0D));
    }
    return CachedNetworkImage(
      imageUrl: imgUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: const Color(0xFF1A1A1A)),
      errorWidget: (_, __, ___) => Container(color: const Color(0xFF0D0D0D)),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 3.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0D0D0D),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: const Color(0xFFEEEEEE))),
      ],
    );
  }

  Widget _paragraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF6B6B6B),
        height: 1.75,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _valuesGrid() {
    const values = [
      {'icon': Icons.favorite_border, 'title': 'Made with Love', 'desc': 'Every piece is crafted with care and attention to detail.'},
      {'icon': Icons.local_shipping_outlined, 'title': 'Fast Delivery', 'desc': 'Quick & reliable shipping to your doorstep.'},
      {'icon': Icons.verified_outlined, 'title': 'Quality First', 'desc': 'Premium fabrics that look great and feel comfortable.'},
      {'icon': Icons.refresh_outlined, 'title': 'Easy Returns', 'desc': '7-day hassle-free return policy on all orders.'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: values.length,
      itemBuilder: (_, i) {
        final v = values[i];
        return Container(
          padding: const EdgeInsets.all(14),
          color: const Color(0xFFF6F6F5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(v['icon'] as IconData, size: 22, color: const Color(0xFF0D0D0D)),
              const SizedBox(height: 8),
              Text(
                v['title'] as String,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0D0D0D)),
              ),
              const SizedBox(height: 4),
              Text(
                v['desc'] as String,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B6B6B), height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.number, required this.label});
  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0D0D0D),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B6B6B),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _AboutSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF0F0F0),
      highlightColor: Colors.white,
      child: Column(
        children: [
          Container(height: 300, color: const Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 100, color: const Color(0xFFF0F0F0)),
                const SizedBox(height: 16),
                Container(height: 12, width: double.infinity, color: const Color(0xFFF0F0F0)),
                const SizedBox(height: 8),
                Container(height: 12, width: double.infinity, color: const Color(0xFFF0F0F0)),
                const SizedBox(height: 8),
                Container(height: 12, width: 200, color: const Color(0xFFF0F0F0)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
