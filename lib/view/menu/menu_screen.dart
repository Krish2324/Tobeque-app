// lib/view/menu/menu_screen.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/constants/string_constant.dart';
import 'package:tobeque/utills/helper_func.dart';
import 'package:tobeque/componant/shimmer_componant.dart';
import 'package:tobeque/view/cetegory/category_page.dart';
import 'package:tobeque/view/community_style/community_style_page.dart';
import 'package:tobeque/view/faq/faq_page.dart';
import 'package:tobeque/view/about/about_page.dart';
import 'package:tobeque/view/contact/contact_page.dart';
import 'package:tobeque/view/refund/refund_request_page.dart';

/// ─── Data layer ───────────────────────────────────────────────────────────────

class WcCat {
  final String id, parent, name, slug;
  WcCat({required this.id, required this.parent, required this.name, required this.slug});
  factory WcCat.fromJson(Map j) => WcCat(
    id:     (j['_id'] ?? j['id'] ?? '').toString(),
    parent: (j['parent'] ?? '').toString(),
    name:   (j['name'] ?? '').toString(),
    slug:   (j['slug'] ?? '').toString(),
  );
}

class CatRepo {
  final Dio _dio = Dio();
  Future<List<WcCat>> fetchAllCats() async {
    final res = await _dio.get(ApiConstant.categories);
    final data = res.data;
    List list = [];
    if (data is Map && data['categories'] is List) {
      list = data['categories'];
    } else if (data is List) {
      list = data;
    }
    return list.map((j) => WcCat.fromJson(j as Map)).toList();
  }
}

/// ─── Screen ───────────────────────────────────────────────────────────────────

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _repo = CatRepo();
  bool _loading = true;
  String? _error;
  List<WcCat> _all = [];
  final Set<String> _open = {};

  List<WcCat> _childrenOf(String parentId) =>
      _all.where((c) => c.parent == parentId).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _all = await _repo.fetchAllCats();
    } on DioException catch (e) {
      _error = (e.response?.data is Map ? e.response!.data['message']?.toString() : null) ?? 'Failed to load categories';
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  WcCat? _findByNameStarts(String prefix, {String? withinParent}) {
    final p = prefix.toLowerCase();
    for (final c in _all) {
      if ((withinParent == null || c.parent == withinParent) &&
          c.name.toLowerCase().startsWith(p)) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: _MenuSkeleton());
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B6B6B))),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.black, side: const BorderSide(color: Colors.black)),
            ),
          ]),
        ),
      );
    }

    int categorySeq(String name) {
      final n = name.toUpperCase().trim();
      if (n == 'TOPS' || n.startsWith('TOP')) return 1;
      if (n.contains('T-SHIRT') || n.contains('VEST')) return 2;
      if (n.contains('SHIRT') || n.contains('BLOUSE')) return 3;
      if (n.contains('DRESS')) return 4;
      if (n.contains('SKIRT') || n.contains('SHORT')) return 5;
      if (n.contains('JEAN') || n.contains('PANT') || n.contains('TROUSER')) return 6;
      return 100;
    }

    // Top-level categories (no parent) sorted in exact sequence
    final topCats = _all.where((c) => c.parent == '' || c.parent == '0').toList()
      ..sort((a, b) {
        final sa = categorySeq(a.name);
        final sb = categorySeq(b.name);
        if (sa != sb) return sa.compareTo(sb);
        return a.name.compareTo(b.name);
      });

    final root     = topCats.isNotEmpty ? topCats.first : null;
    final newCat   = _findByNameStarts('new',     withinParent: root?.id);
    final bestCat  = _findByNameStarts('best',    withinParent: root?.id);
    final specCat  = _findByNameStarts('special', withinParent: root?.id);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            const SizedBox(height: 16),

            // ── Brand header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick links row
                  Row(
                    children: [
                      _PillChip(
                        label: 'Subscribe',
                        onTap: () => launchEmail(Constent.email),
                        filled: true,
                      ),
                      const SizedBox(width: 8),
                      _PillChip(label: 'Limited Drops', filled: false),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                ],
              ),
            ),

            // ── Category list ─────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                color: Colors.black,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Featured links (if available)
                    if (newCat != null || bestCat != null || specCat != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (newCat != null) _BigCatLink(cat: newCat),
                            if (bestCat != null) _BigCatLink(cat: bestCat),
                            if (specCat != null) _BigCatLink(cat: specCat, color: const Color(0xFFE53935)),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    // All categories with expandable subcategories
                    ...topCats.map((c) {
                      final subs   = _childrenOf(c.id);
                      final isOpen = _open.contains(c.id);
                      return _CatWithSubs(
                        cat: c,
                        subs: subs,
                        isOpen: isOpen,
                        onTapParent: () => Get.to(() => CategoryPage(categoryId: c.id, title: c.name)),
                        onToggle: () => setState(() {
                          isOpen ? _open.remove(c.id) : _open.add(c.id);
                        }),
                      );
                    }),

                    // ALL PRODUCTS at the last of category list
                    _MenuRow(
                      title: 'ALL PRODUCTS',
                      onTap: () => Get.to(() => const CategoryPage(categoryId: 'all', title: 'All Products')),
                    ),

                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),

                    // ── Explore section ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Text(
                        'EXPLORE',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 3.5,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    _NavTile(
                      icon: Icons.style_outlined,
                      title: 'Steal The Style',
                      subtitle: 'Community looks & inspiration',
                      onTap: () => Get.to(() => const CommunityStylePage()),
                    ),
                    _NavTile(
                      icon: Icons.star_border_outlined,
                      title: 'Featured Collections',
                      subtitle: 'Curated picks by our team',
                      onTap: () => Get.to(() => const CategoryPage(categoryId: 'all', title: 'Featured Collections')),
                    ),

                    // ── Help & Info section ─────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Text(
                        'HELP & INFO',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 3.5,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    _NavTile(
                      icon: Icons.help_outline,
                      title: 'FAQs',
                      subtitle: 'Frequently asked questions',
                      onTap: () => Get.to(() => const FaqPage()),
                    ),
                    _NavTile(
                      icon: Icons.email_outlined,
                      title: 'Contact Us',
                      subtitle: 'Get in touch with our team',
                      onTap: () => Get.to(() => const ContactPage()),
                    ),
                    _NavTile(
                      icon: Icons.replay_outlined,
                      title: 'Return & Refund',
                      subtitle: '7-day easy return policy',
                      onTap: () => Get.to(() => const RefundRequestPage()),
                    ),
                    _NavTile(
                      icon: Icons.info_outline,
                      title: 'About Tobeque',
                      subtitle: 'Our story and mission',
                      onTap: () => Get.to(() => const AboutPage()),
                    ),
                    _NavTile(
                      icon: Icons.phone_outlined,
                      title: 'Call / WhatsApp',
                      subtitle: 'Talk to us directly',
                      onTap: () => _showContactSheet(context),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      useSafeArea: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Contact us',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.call_outlined, color: Colors.black),
                title: Text(
                  'Call ${Constent.phone.trim()}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
                ),
                subtitle: const Text('From Monday to Saturday from 09:00 to 18:00'),
                onTap: () {
                  Navigator.pop(ctx);
                  launchPhoneCall(Constent.phone, context: context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.black),
                title: const Text(
                  'Start WhatsApp chat',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
                ),
                subtitle: const Text('From Monday to Saturday from 09:00 to 17:30'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await openWhatsAppChat(
                    Constent.phone,
                    message: 'Hello 👋 Need some info.',
                    defaultCountryCode: '91',
                  );
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open WhatsApp on this device')),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

/// ─── UI Components ───────────────────────────────────────────────────────────

class _BigCatLink extends StatelessWidget {
  const _BigCatLink({required this.cat, this.color = const Color(0xFF0D0D0D)});
  final WcCat cat;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(() => CategoryPage(categoryId: cat.id, title: cat.name)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          cat.name.toUpperCase(),
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            height: 1.1,
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
  final VoidCallback onTapParent, onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Text(
            cat.name.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3, fontSize: 15, color: Color(0xFF0D0D0D)),
          ),
          onTap: onTapParent,
          trailing: subs.isNotEmpty
              ? IconButton(
                  icon: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: isOpen ? 0.5 : 0.0,
                    child: const Icon(Icons.expand_more, color: Color(0xFF0D0D0D)),
                  ),
                  onPressed: onToggle,
                )
              : const Icon(Icons.chevron_right, size: 18, color: Color(0xFF9E9E9E)),
        ),
        if (subs.isNotEmpty && isOpen)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subs.length,
              separatorBuilder: (_, __) => const Divider(height: 6, color: Color(0xFFF0F0F0)),
              itemBuilder: (_, i) {
                final sc = subs[i];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 28),
                  leading: const Icon(Icons.circle, size: 5, color: Color(0xFF9E9E9E)),
                  title: Text(sc.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                  trailing: const Icon(Icons.chevron_right, size: 16, color: Color(0xFF9E9E9E)),
                  onTap: () => Get.to(() => CategoryPage(categoryId: sc.id, title: sc.name)),
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
        style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 13, color: Color(0xFF0D0D0D)),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF9E9E9E)),
    );
  }
}

/// New premium navigation tile for Explore / Help sections
class _NavTile extends StatelessWidget {
  const _NavTile({required this.icon, required this.title, this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              color: const Color(0xFFF6F6F5),
              child: Icon(icon, size: 18, color: const Color(0xFF0D0D0D)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0D0D0D)),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E), height: 1.4),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF9E9E9E)),
          ],
        ),
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({required this.label, required this.filled, this.onTap});
  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF0D0D0D) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: filled ? null : Border.all(color: const Color(0xFFDDDDDD)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : const Color(0xFF0D0D0D),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _MenuSkeleton extends StatelessWidget {
  const _MenuSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 16),
        ShimmerWave.box(width: 220, height: 36),
        const SizedBox(height: 10),
        ShimmerWave.box(width: 260, height: 36),
        const SizedBox(height: 10),
        ShimmerWave.box(width: 200, height: 36),
        const Divider(height: 32),
        ShimmerWave.box(width: double.infinity, height: 18),
        const SizedBox(height: 12),
        ShimmerWave.box(width: double.infinity, height: 18),
        const SizedBox(height: 12),
        ShimmerWave.box(width: double.infinity, height: 18),
      ],
    );
  }
}

// ─── Legacy UI components (kept for backward compat) ─────────────────────────

class BigUnderbarTitle extends StatelessWidget {
  const BigUnderbarTitle(this.text, {super.key, this.barColor = Colors.black});
  final String text;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text.toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: .4)),
        const SizedBox(height: 6),
        Container(width: 52, height: 2, color: barColor),
      ],
    );
  }
}

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
        style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: .5),
      ),
    );
  }
}
