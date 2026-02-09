// lib/view/home/home_repository.dart
import 'dart:convert';
import 'package:html_unescape/html_unescape.dart';
import 'package:dio/dio.dart';
import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/data/dio_client.dart';

import 'models.dart'; // expects WpPageHero, WcCategory, WcProduct

class HomeRepository {
  final Dio _dio = DioClient.build();
/// Returns direct children (sub-categories) of the given parent category.
/// Tries Woo Store API → WP REST (product_cat) → Woo v3 (if enabled).
Future<List<Map<String, dynamic>>> fetchSubcategories({
  required int parentId,
  int perPage = 50,
}) async {
  Future<List> _get(String url) async {
    final res = await _dio.get(url);
    return (res.data is List) ? (res.data as List) : const [];
  }

  // 1) WooCommerce Store API (public, no auth)
  final storeUrl =
      '${ApiConstant.baseUrl}/wp-json/wc/store/v1/products/categories?parent=$parentId&per_page=$perPage&hide_empty=true';

  // 2) WordPress REST: taxonomy terms for product_cat (usually public)
  //    Returns: id, name, slug, parent, count (no image)
  final wpTermsUrl =
      '${ApiConstant.baseUrl}/wp-json/wp/v2/product_cat?parent=$parentId&per_page=$perPage&_fields=id,name,slug,parent,count';

  // 3) WooCommerce REST v3 (may require CK/CS depending on site policy)
  //    Add your CK/CS if needed: …?consumer_key=xxx&consumer_secret=yyy
  final wcV3Url =
      '${ApiConstant.baseUrl}/wp-json/wc/v3/products/categories?parent=$parentId&per_page=$perPage&hide_empty=true';

  List data = const [];
  String used = '';

  // Try Store API
  try {
    data = await _get(storeUrl);
    used = 'store';
  } catch (_) {}

  // If Store API empty or failed, try WP terms
  if (data.isEmpty) {
    try {
      data = await _get(wpTermsUrl);
      used = 'wp';
    } catch (_) {}
  }

  // If still empty, try Woo v3
  if (data.isEmpty) {
    try {
      data = await _get(wcV3Url);
      used = 'v3';
    } catch (_) {}
  }

  // Normalize shape → {id, name, slug, parent, count, image}
  final out = <Map<String, dynamic>>[];

  for (final e in data) {
    if (e is! Map) continue;
    final m = e.cast<String, dynamic>();
    final id    = (m['id'] ?? 0) as int;
    final name  = (m['name'] ?? '').toString().trim();
    final slug  = (m['slug'] ?? '').toString();
    final parent = (m['parent'] ?? parentId) as int;
    final count  = (m['count'] is num) ? (m['count'] as num).toInt() : null;

    // Image can be present on Store API and WC v3; WP terms usually don’t include it.
    String? image;
    if (used == 'store') {
      final img = m['image'];
      if (img is Map) image = (img['src'] ?? img['url'] ?? '').toString();
    } else if (used == 'v3') {
      final img = m['image'];
      if (img is Map) image = (img['src'] ?? '').toString();
    }

    if (id > 0 && name.isNotEmpty) {
      out.add({
        'id': id,
        'name': name,
        'slug': slug,
        'parent': parent,
        'count': count,
        'image': image, // may be null if API doesn’t return it
      });
    }
  }

  // Sort by name
  out.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  return out;
}

  /// Extract Elementor hero video (YouTube/Vimeo/direct) reliably from the Home page.
  Future<String?> fetchHeroVideoUrl() async {
    // TIP: make sure ApiConstant.baseUrl == https://tobeque.com/
    // Prefer slug to avoid hardcoding:
    // final pageUrl = ApiConstant.wp('pages?slug=home-v1&_embed');
    final pageUrl = ApiConstant.wp('pages/21?_embed');

    final res = await _dio.get(pageUrl, options: Options(headers: {
      'Accept': 'application/json',
    }));

    // WordPress returns a list for ?slug=..., or a map for /pages/{id}
    String html = '';
    if (res.data is Map) {
      html = (res.data['content']?['rendered'] as String?) ?? '';
    } else if (res.data is List && (res.data as List).isNotEmpty) {
      final first = res.data[0] as Map<String, dynamic>;
      html = (first['content']?['rendered'] as String?) ?? '';
    }
    if (html.isEmpty) return null;

    // --- Find ALL data-settings attributes (Elementor sections) ---
    final dataSettingsRe = RegExp(
      r'''data-settings\s*=\s*(?:"([^"]*)"|'([^']*)')''',
      caseSensitive: false,
      dotAll: true,
    );

    final unescape = HtmlUnescape();
    for (final m in dataSettingsRe.allMatches(html)) {
      // group(1) if it was double quotes, group(2) if single quotes
      final raw = m.group(1) ?? m.group(2) ?? '';
      if (raw.isEmpty) continue;

      // Decode &quot;, &#039; etc.
      final decoded = unescape.convert(raw);

      // Some themes escape slashes
      final normalized = decoded.replaceAll(r'\/', '/');

      try {
        final Map<String, dynamic> settings = jsonDecode(normalized);

        // Elementor key for background video
        final link = (settings['background_video_link'] as String?)?.trim();
        if (link != null && link.isNotEmpty) {
          return _normalizeUrl(link);
        }
      } catch (_) {
        // ignore and try next match
      }
    }

    // --- Fallback: <iframe src="youtube|vimeo"> anywhere on page ---
    final iframeRe = RegExp(
      r'src="(https?:\/\/(?:www\.)?(?:youtube\.com\/embed\/[^"\s]+|player\.vimeo\.com\/video\/\d+)[^"]*)"',
      caseSensitive: false,
      dotAll: true,
    );
    final iframe = iframeRe.firstMatch(html)?.group(1);
    if (iframe != null) return _normalizeUrl(iframe);

    // --- Fallback: direct file (.mp4/.webm/.m3u8) ---
    final directRe = RegExp(
      r'src="([^"]+\.(?:mp4|webm|m3u8)[^"]*)"',
      caseSensitive: false,
      dotAll: true,
    );
    final direct = directRe.firstMatch(html)?.group(1);
    if (direct != null) {
      return direct.startsWith('http')
          ? direct
          : '${ApiConstant.baseUrl}${direct.startsWith('/') ? '' : '/'}$direct';
    }

    return null;
  }

  // Optional helper to detect site's front page id (requires REST perms on some hosts)
  Future<int?> fetchFrontPageId() async {
    try {
      final settingsRes = await _dio.get(ApiConstant.wp('settings'));
      final frontId = settingsRes.data?['page_on_front'];
      if (frontId is int) return frontId;
    } catch (_) {/* some sites require auth for /settings */}
    return null;
  }

  String _normalizeUrl(String url) {
    var u = url.trim();
    u = u.replaceAll(r'\/', '/');
    u = u.replaceAll('\\', '');
    return u;
  }

  /// Featured image from page "home" (adjust slug if needed)
  Future<WpPageHero> fetchHero() async {
    final url = ApiConstant.wp('pages?slug=home-v1&_embed'); // or 'home'
    final res = await _dio.get(url);
    if (res.data is List && res.data.isNotEmpty) {
      final page = res.data[0];
      final media = page['_embedded']?['wp:featuredmedia'];
      final img = (media is List && media.isNotEmpty)
          ? media[0]['source_url'] as String?
          : null;
      return WpPageHero(imageUrl: img);
    }
    return WpPageHero(imageUrl: null);
  }

  /// WooCommerce product categories
Future<List<WcCategory>> fetchCategories({int perPage = 25}) async {
  // 1) fetch categories (prefer not to show truly empty ones)
  final url = ApiConstant.wcStore('products/categories?per_page=$perPage&hide_empty=false');
  final res = await _dio.get(url);
  final List data = res.data is List ? res.data : [];
print(data);
  // base list
  final cats = data.map<WcCategory>((c) {
    String? img;
    if (c['image'] != null) img = (c['image']['src'] as String?)?.trim();
    return WcCategory(
      id: (c['id'] ?? 0) as int,
      name: (c['name'] ?? '') as String,
      image: img,
    );
  }).toList();

  // 2) collect ids that need fallback images
  final needFallback = cats.where((c) => (c.image == null || c.image!.isEmpty)).toList();
  if (needFallback.isEmpty) return cats;

  // 3) fetch one product per category (popular/newest) to grab an image
  final futures = needFallback.map((c) async {
    try {
      final pRes = await _dio.get(
        ApiConstant.wcStore('products'),
        queryParameters: {
          'per_page': 1,
          'category': c.id,
          'orderby': 'popularity', // or 'date'
        },
      );
      final List plist = pRes.data is List ? pRes.data : [];
      if (plist.isNotEmpty) {
        final images = (plist.first['images'] as List? ?? []);
        if (images.isNotEmpty) {
          final src = (images.first['src'] as String?)?.trim();
          if (src != null && src.isNotEmpty) {
            c.image = src; // mutate fallback
          }
        }
      }
    } catch (_) {/* ignore per-cat errors */}
  }).toList();

  await Future.wait(futures);
  return cats;
}

  /// WooCommerce best sellers (by popularity)
  Future<List<WcProduct>> fetchBestSellers({int perPage = 12}) async {
    final url = ApiConstant.wcStore(
      'products?orderby=popularity&per_page=$perPage',
    );
    final res = await _dio.get(url);
    final List list = res.data is List ? res.data : [];
    return list.map((p) {
      final imgs = p['images'] as List?;
      final img = (imgs != null && imgs.isNotEmpty)
          ? imgs[0]['src'] as String?
          : null;
      return WcProduct(
        id: (p['id'] ?? 0) as int,
        name: (p['name'] ?? '') as String,
        priceHtml: p['price_html'] as String?,
        image: img,
      );
    }).toList();
  }
  Future<Map<String, dynamic>> fetchProduct(int id) async {
    // WooCommerce Store API (no auth needed typically)
    final url = ApiConstant.wcStore('products/$id');
    final res = await _dio.get(url);
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> fetchProductsByCategory({
    required int categoryId,
    int perPage = 20,
    int page = 1,
  }) async {
    final url = ApiConstant.wcStore(
      'products?per_page=$perPage&page=$page&category=$categoryId',
    );
    final res = await _dio.get(url);
    final list = (res.data is List) ? (res.data as List) : const [];
    return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }



  
}
