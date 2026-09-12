// lib/view/community_style/community_style_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/data/dio_client.dart';

// ─── Repository ───────────────────────────────────────────────────────────────

class CommunityStyleRepository {
  final Dio _dio = DioClient.build();

  Future<List<Map<String, dynamic>>> fetchStyles() async {
    try {
      final res  = await _dio.get(ApiConstant.communityStyles);
      final data = res.data;
      List list  = [];
      if (data is Map && data['data'] is List) {
        list = data['data'];
      } else if (data is List) {
        list = data;
      }
      return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
    } catch (_) {
      return [];
    }
  }
}

// ─── Controller ───────────────────────────────────────────────────────────────

class CommunityStyleController extends GetxController {
  final _repo = CommunityStyleRepository();

  final loading = true.obs;
  final error   = RxnString();
  final styles  = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    loading.value = true;
    error.value   = null;
    try {
      final data = await _repo.fetchStyles();
      styles.assignAll(data);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class CommunityStylePage extends StatelessWidget {
  const CommunityStylePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(CommunityStyleController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
          onPressed: Get.back,
        ),
        title: const Column(
          children: [
            Text(
              'STEAL THE STYLE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 3.0,
                color: Colors.black,
              ),
            ),
            Text(
              'Community Looks',
              style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w400),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: Obx(() {
        if (c.loading.value) return _CommunityStyleSkeleton();
        if (c.error.value != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.black26),
                const SizedBox(height: 12),
                Text(c.error.value!, style: const TextStyle(color: Color(0xFF6B6B6B))),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: c.fetchAll,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                  ),
                ),
              ],
            ),
          );
        }

        if (c.styles.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.style_outlined, size: 64, color: Color(0xFFDDDDDD)),
                SizedBox(height: 12),
                Text(
                  'No community styles yet',
                  style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 15),
                ),
                SizedBox(height: 4),
                Text(
                  'Check back soon for fresh looks!',
                  style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: c.fetchAll,
          color: Colors.black,
          child: CustomScrollView(
            slivers: [
              // Header description
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    'Get inspired by how our community wears Tobeque. Tag us @tobeque to be featured.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B6B6B),
                      height: 1.6,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Masonry-style staggered grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                    childAspectRatio: 0.72, // portrait ~3:4
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _CommunityCard(style: c.styles[i], index: i),
                    childCount: c.styles.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Community Card ───────────────────────────────────────────────────────────

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({required this.style, required this.index});
  final Map<String, dynamic> style;
  final int index;

  @override
  Widget build(BuildContext context) {
    final rawImg = style['imageUrl'] ?? style['image'] ?? style['photo'] ?? '';
    final imgUrl = ApiConstant.getImageUrl(rawImg.toString());
    final title  = style['title']?.toString() ?? '';
    final handle = style['handle']?.toString() ?? style['username']?.toString() ?? '';
    final tags   = (style['tags'] is List) ? (style['tags'] as List).map((e) => e.toString()).toList() : <String>[];

    return GestureDetector(
      onTap: () => _showStyleDetail(context, style),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          imgUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imgUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Shimmer.fromColors(
                    baseColor: const Color(0xFFF0F0F0),
                    highlightColor: Colors.white,
                    child: Container(color: const Color(0xFFF0F0F0)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFFF0F0F0),
                    child: const Icon(Icons.image_not_supported_outlined, color: Colors.black12),
                  ),
                )
              : Container(color: const Color(0xFFF0F0F0)),

          // Bottom gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.65),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),

          // Info at bottom
          Positioned(
            left: 10,
            right: 10,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (handle.isNotEmpty)
                  Text(
                    '@$handle',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 4,
                    runSpacing: 3,
                    children: tags.take(3).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),

          // Heart icon top-right
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_border, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showStyleDetail(BuildContext context, Map<String, dynamic> style) {
    final rawImg = style['imageUrl'] ?? style['image'] ?? style['photo'] ?? '';
    final imgUrl = ApiConstant.getImageUrl(rawImg.toString());
    final title  = style['title']?.toString() ?? '';
    final handle = style['handle']?.toString() ?? style['username']?.toString() ?? '';
    final desc   = style['description']?.toString() ?? '';
    final tags   = (style['tags'] is List) ? (style['tags'] as List).map((e) => e.toString()).toList() : <String>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: EdgeInsets.zero,
                  children: [
                    // Full image
                    if (imgUrl.isNotEmpty)
                      AspectRatio(
                        aspectRatio: 3 / 4,
                        child: CachedNetworkImage(imageUrl: imgUrl, fit: BoxFit.cover),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (handle.isNotEmpty)
                            Text('@$handle',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0D0D0D))),
                          if (title.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF6B6B6B), height: 1.5)),
                          ],
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(desc, style: const TextStyle(fontSize: 13, color: Color(0xFF6B6B6B), height: 1.6)),
                          ],
                          if (tags.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: tags.map((tag) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F0F0),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text('#$tag',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B6B6B))),
                              )).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _CommunityStyleSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.72,
      ),
      itemCount: 8,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFFF0F0F0),
        highlightColor: Colors.white,
        child: Container(color: const Color(0xFFF0F0F0)),
      ),
    );
  }
}
