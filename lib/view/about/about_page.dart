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
      if (data is Map) {
        if (data['data'] != null && data['data'] is Map) {
          return (data['data'] as Map).cast<String, dynamic>();
        }
        if (data['aboutUs'] != null && data['aboutUs'] is Map) {
          return (data['aboutUs'] as Map).cast<String, dynamic>();
        }
        if (data['about'] != null && data['about'] is Map) {
          return (data['about'] as Map).cast<String, dynamic>();
        }
        return data.cast<String, dynamic>();
      }
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

  String _cleanContent(dynamic raw) {
    if (raw == null) return '';
    var s = raw.toString().trim();
    if (s.isEmpty) return '';
    s = s.replaceAll(RegExp(r'<[^>]*>'), '\n\n').replaceAll('&nbsp;', ' ');
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return s.trim();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AboutController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        if (c.loading.value) return _AboutSkeleton();

        final data = c.about.value ?? {};

        // Extracted Admin Data Fields (matching Web App AboutPage.tsx)
        final heroTitle = _cleanContent(data['heroTitle'] ?? data['brand'] ?? 'About Tobeque');
        final heroSubtitle = _cleanContent(data['heroSubtitle'] ?? data['tagline'] ?? 'Teen Fashion Brand for Girls in India');
        
        final missionStmt = _cleanContent(data['missionStatement'] ?? data['mission'] ?? data['ourMission']);
        final visionStmt = _cleanContent(data['visionStatement'] ?? data['vision']);

        final ourStoryTitle = _cleanContent(data['ourStoryTitle'] ?? 'Our Story');
        final ourStoryText = _cleanContent(data['ourStoryText'] ?? data['story'] ?? data['content'] ?? data['description'] ?? data['aboutUs'] ?? data['text']);
        final ourStoryText2 = _cleanContent(data['ourStoryText2']);

        final extraSections = (data['extraSections'] as List?) ?? [];
        final statsList = (data['stats'] as List?) ?? [];

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Hero banner app bar (half height as requested)
            SliverAppBar(
              backgroundColor: Colors.black,
              pinned: true,
              expandedHeight: MediaQuery.of(context).size.width * 0.45,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
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
                    // Brand/Mission image
                    _aboutImage(data),

                    // Gradient overlay
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),

                    // Title & Subtitle overlay
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (heroSubtitle.isNotEmpty)
                            Text(
                              heroSubtitle.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                letterSpacing: 2.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            heroTitle.isNotEmpty ? heroTitle : 'TOBEQUE',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Main Content Sections
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mission & Vision Section
                    if (missionStmt.isNotEmpty) ...[
                      _sectionTitle('OUR MISSION'),
                      const SizedBox(height: 12),
                      _paragraph(missionStmt),
                      const SizedBox(height: 28),
                    ],

                    if (visionStmt.isNotEmpty) ...[
                      _sectionTitle('OUR VISION'),
                      const SizedBox(height: 12),
                      _paragraph(visionStmt),
                      const SizedBox(height: 28),
                    ],

                    // Dynamic Stats Section (if present)
                    if (statsList.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: statsList.map((st) {
                            final map = st is Map ? st : {};
                            final val = map['value']?.toString() ?? '';
                            final lbl = map['label']?.toString() ?? '';
                            return Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    val,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lbl.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white70,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Our Story Section
                    if (ourStoryText.isNotEmpty || ourStoryTitle.isNotEmpty) ...[
                      _sectionTitle(ourStoryTitle.toUpperCase()),
                      const SizedBox(height: 12),
                      if (ourStoryText.isNotEmpty) _paragraph(ourStoryText),
                      if (ourStoryText2.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _paragraph(ourStoryText2),
                      ],
                      const SizedBox(height: 32),
                    ],

                    // Extra Sections (Sequential admin sections)
                    if (extraSections.isNotEmpty) ...[
                      ...extraSections.map((sec) {
                        final map = sec is Map ? sec : {};
                        final secTitle = _cleanContent(map['title']);
                        final secDesc = _cleanContent(map['description']);
                        if (secTitle.isEmpty && secDesc.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (secTitle.isNotEmpty) ...[
                              _sectionTitle(secTitle.toUpperCase()),
                              const SizedBox(height: 12),
                            ],
                            if (secDesc.isNotEmpty) ...[
                              _paragraph(secDesc),
                              const SizedBox(height: 28),
                            ],
                          ],
                        );
                      }),
                    ],

                    // Brand Values Grid (Why Tobeque)
                    _sectionTitle('WHY TOBEQUE'),
                    const SizedBox(height: 16),
                    _valuesGrid(),
                    const SizedBox(height: 32),
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
    final rawImg = data['missionImage'] ?? data['bannerImage'] ?? data['heroImage'] ?? data['image'] ?? '';
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
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D0D0D),
            ),
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

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({this.height});
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEEEEE),
      highlightColor: const Color(0xFFFAFAFA),
      child: Container(
        width: double.infinity,
        height: height ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _AboutSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF0F0F0),
      highlightColor: Colors.white,
      child: Column(
        children: [
          Container(height: 200, color: const Color(0xFFF0F0F0)),
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
