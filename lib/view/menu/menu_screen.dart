// lib/view/menu/menu_screen.dart
import 'package:tobeque/constants/string_constant.dart';
import 'package:tobeque/utills/helper_func.dart';
import 'package:tobeque/view/cetegory/category_page.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/componant/shimmer_componant.dart';


/// ---------- Data layer (self-contained) ----------
// const _base = 'https://tobeque.com/wp-json/wc/v3';
const _base = "${ApiConstant.baseUrl}/${ApiConstant.restPrefix}/wc/v3";
class WcCat {
  final int id, parent;
  final String name, slug;
  WcCat({required this.id, required this.parent, required this.name, required this.slug});
  factory WcCat.fromJson(Map j) => WcCat(
        id: (j['id'] as num).toInt(),
        parent: (j['parent'] as num).toInt(),
        name: (j['name'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
      );
}

class CatRepo {
  final Dio _dio = Dio();

  Future<List<WcCat>> fetchAllCats({bool hideEmpty = true}) async {
    final out = <WcCat>[];
    int page = 1;
    const per = 100;

    while (true) {
      final res = await _dio.get('$_base/products/categories', queryParameters: {
        'page': page,
        'per_page': per,
        'consumer_key': ApiConstant.consumerKey,
        'consumer_secret': ApiConstant.consumerSecret,
        if (hideEmpty) 'hide_empty': 'true',
        'orderby': 'name',
        'order': 'asc',
      });

      final list = (res.data as List).cast<Map>();
      out.addAll(list.map(WcCat.fromJson));

      if (list.length < per) break;
      page++;
    }
    return out;
  }
}

/// ---------- Screen ----------
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  final _repo = CatRepo();
  bool _loading = true;
  String? _error;
  List<WcCat> _all = [];

  // “top bars” like the screenshot
  static const _tabs = ['POPULER', ];
  late final TabController _tab = TabController(length: _tabs.length, vsync: this);
final Set<int> _open = <int>{}; // which parent categories are expanded
List<WcCat> _childrenOf(int parentId) =>
    _all.where((c) => c.parent == parentId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _all = await _repo.fetchAllCats(hideEmpty: true);
    } on DioException catch (e) {
      final m = (e.response?.data is Map) ? (e.response!.data['message']?.toString()) : e.message;
      _error = m ?? 'Failed to load categories';
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  // Try to find a top “root” category by name/slug; if not found, fall back to
  // just showing *all* top-level categories (parent == 0)
  // WcCat? _findRoot(String label) {
  //   final l = label.toLowerCase();
  //   return _all.firstWhereOrNull((c) =>
  //       c.parent == 0 && (c.name.toLowerCase() == l || c.slug.toLowerCase() == l));
  // }



  // Utility: find a category by (contains) name for big “NEW”, “BEST SELLERS”, etc.
  // WcCat? _findByNameStarts(String prefix, {int? withinParent}) {
  //   final p = prefix.toLowerCase();
  //   Iterable<WcCat> pool = _all;
  //   if (withinParent != null) pool = pool.where((c) => c.parent == withinParent);
  //   return pool.firstWhereOrNull((c) => c.name.toLowerCase().startsWith(p));
  // }
WcCat? _findRoot(String label) {
  final l = label.toLowerCase();
  for (final c in _all) {
    if (c.parent == 0 &&
        (c.name.toLowerCase() == l || c.slug.toLowerCase() == l)) {
      return c;
    }
  }
  return null;
}

WcCat? _findByNameStarts(String prefix, {int? withinParent}) {
  final p = prefix.toLowerCase();
  for (final c in _all) {
    if ((withinParent == null || c.parent == withinParent) &&
        c.name.toLowerCase().startsWith(p)) {
      return c;
    }
  }
  return null;
}

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
      //  appBar: _MenuAppBar(),
        body: _MenuSkeleton(),
      );
    }
    if (_error != null) {
      return Scaffold(
     //   appBar: const _MenuAppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
      //  appBar: const _MenuAppBar(),
        body: Column(
          children: [
            SizedBox(
              height: 20,
            ),

            Material(
              color: Colors.white60,
              child: TabBar(
                controller: _tab,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.black54,
                indicatorColor: Colors.black,
                indicatorWeight: 2,
                isScrollable: true,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
           Padding(
  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const BigUnderbarTitle('NEW'),
      const SizedBox(height: 14),
      const OutlinedTitle('TRENDS. BY TOBEQUE'),
      const SizedBox(height: 14),
      RedCapsLink('SPECIAL PRICES', onTap: () {/* navigate */}),
      const SizedBox(height: 18),
      Row(
        children:  [
          GestureDetector(
            onTap: (){
              launchEmail(Constent.email);
            },
            child: PillBadge('Subscribe')),
          SizedBox(width: 8),
          PillBadge('Limited', color: Colors.white, textColor: Colors.black),
        ],
      ),
    ],
  ),
),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: _tabs.map((t) {
                  final root = _findRoot(t);
                  final children = (root == null)
                      ? (_all.where((c) => c.parent == 0).toList()..sort((a, b) => a.name.compareTo(b.name)))
                      : _childrenOf(root.id);
      
                  // Try to pick the 4 “headline” categories (NEW / ECKŌ… / BEST SELLERS / SPECIAL PRICES)
                  final newCat = _findByNameStarts('new', withinParent: root?.id);
                  final bestCat = _findByNameStarts('best', withinParent: root?.id);
                  final specialCat = _findByNameStarts('special', withinParent: root?.id);
                  final eckoCat = _findByNameStarts('eck', withinParent: root?.id); // matches “ECKŌ…”
      
                  return RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      children: [
                        // Headline links (when available)
                        if (newCat != null || eckoCat != null || bestCat != null || specialCat != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (newCat != null) _BigLink(newCat, color: Colors.black),
                                if (eckoCat != null) _BigLink(eckoCat, color: Colors.black),
                                if (bestCat != null) _BigLink(bestCat, color: Colors.black),
                                if (specialCat != null)
                                  _BigLink(specialCat, color: const Color(0xffcf2e2e)), // red like screenshot
                              ],
                            ),
                          ),
      
                    //    const Divider(height: 24, thickness: 1),
      SizedBox(
        height: 25,
      ),
                        // “VIEW ALL” (parent itself)
                        if (root != null)
                          _MenuRow(
                            title: 'VIEW ALL',
                            onTap: () => Get.to(() => CategoryPage(categoryId: root.id, title: root.name)),
                          ),
      
                        // Child categories list
                       // Child categories with nested sub-categories (expand/collapse)
...children.map((c) {
  final subs = _childrenOf(c.id);
  final isOpen = _open.contains(c.id);
  return _CatWithSubs(
    cat: c,
    subs: subs,
    isOpen: isOpen,
    onTapParent: () =>
        Get.to(() => CategoryPage(categoryId: c.id, title: c.name)),
    onToggle: () => setState(() {
      isOpen ? _open.remove(c.id) : _open.add(c.id);
    }),
  );
}),

                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------- UI bits ----------

class _BigLink extends StatelessWidget {
  const _BigLink(this.cat, {required this.color});
  final WcCat cat;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(() => CategoryPage(categoryId: cat.id, title: cat.name)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          cat.name.toUpperCase(),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            height: 1.12,
            letterSpacing: .4,
            color: color,
          ),
        ),
      ),
    );
  }
}
class _CatWithSubs extends StatelessWidget {
  const _CatWithSubs({
    required this.cat,
    required this.subs,
    required this.isOpen,
    required this.onTapParent,
    required this.onToggle,
  });

  final WcCat cat;
  final List<WcCat> subs;
  final bool isOpen;
  final VoidCallback onTapParent;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final hasSubs = subs.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Text(
            cat.name.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
              fontSize: 16,
            ),
          ),
          onTap: onTapParent, // go to parent category products
          trailing: hasSubs
              ? IconButton(
                  icon: AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: isOpen ? 0.5 : 0.0, // rotate ▼
                    child: const Icon(Icons.expand_more),
                  ),
                  onPressed: onToggle,
                )
              : const Icon(Icons.chevron_right, size: 20),
        ),

        if (hasSubs && isOpen)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subs.length,
              separatorBuilder: (_, __) => const Divider(height: 6),
              itemBuilder: (_, i) {
                final sc = subs[i];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 28),
                  leading: const Icon(Icons.circle, size: 6, color: Colors.black54),
                  title: Text(
                    sc.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => Get.to(
                    () => CategoryPage(categoryId: sc.id, title: sc.name),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}


class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.title, this.onTap});
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: .3,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }
}

class _MenuSkeleton extends StatelessWidget {
  const _MenuSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ShimmerWave.box(width: 220, height: 36), // big headline
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ShimmerWave.box(width: 260, height: 36),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ShimmerWave.box(width: 200, height: 36),
        ),
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ShimmerWave.box(width: double.infinity, height: 18),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ShimmerWave.box(width: double.infinity, height: 18),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ShimmerWave.box(width: double.infinity, height: 18),
        ),
      ],
    );
  }
}


/// 1) Big title with a short accent underline
class BigUnderbarTitle extends StatelessWidget {
  const BigUnderbarTitle(this.text, {super.key, this.barColor = Colors.black});
  final String text;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: .4,
          ),
        ),
        const SizedBox(height: 6),
        Container(width: 52, height: 2, color: barColor),
      ],
    );
  }
}

/// 2) Red, all-caps “linky” line (e.g., SPECIAL PRICES)
class RedCapsLink extends StatelessWidget {
  const RedCapsLink(this.text, {super.key, this.onTap});
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: .5,
        ),
      ),
    );
  }
}

/// 3) Outlined headline (stroke + fill)
class OutlinedTitle extends StatelessWidget {
  const OutlinedTitle(this.text, {super.key, this.fill = Colors.black, this.stroke = Colors.white});
  final String text;
  final Color fill, stroke;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text( // stroke
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: .4,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = stroke,
          ),
        ),
        Text( // fill
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: .4,
            color: fill,
          ),
        ),
      ],
    );
  }
}

/// 4) Subtle gradient text (black → grey)
class GradientCaps extends StatelessWidget {
  const GradientCaps(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Colors.black, Color(0xFF9E9E9E)],
      ).createShader(r),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: .4, color: Colors.white,
        ),
      ),
    );
  }
}

/// 5) Pill badge (e.g., “Subscribe”, “New”)
class PillBadge extends StatelessWidget {
  const PillBadge(this.text, {super.key, this.color = Colors.black, this.textColor = Colors.white});
  final String text;
  final Color color, textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.w800)),
    );
  }
}
