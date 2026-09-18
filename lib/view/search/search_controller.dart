import 'dart:async';
import 'package:get/get.dart';

import 'package:tobeque/data/network/network_api_sarvices.dart';

class SearchController extends GetxController {
  // deps
  final _net = NetworkApi();

  // state
  final query = ''.obs;
  final loading = false.obs;
  final error = RxnString();
  final results = <Map<String, dynamic>>[].obs;

  // paging
  final _perPage = 12;
  int _page = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  Timer? _debounce;

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  void onQueryChanged(String q) {
    query.value = q;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _startSearch(q);
    });
  }

  Future<void> _startSearch(String q) async {
    _page = 1;
    _hasMore = true;
    results.clear();
    error.value = null;

    if (q.trim().isEmpty) {
      loading.value = false;
      return;
    }

    await _fetchPage();
  }

  Future<void> refreshNow() async {
    await _startSearch(query.value);
  }

  Future<void> loadMore() async {
    if (loading.value || !_hasMore || query.value.trim().isEmpty) return;
    _page += 1;
    await _fetchPage(append: true);
  }

  Future<void> _fetchPage({bool append = false}) async {
    try {
      loading.value = true;
      error.value = null;

      // Woo Store API search
      // NOTE: This mirrors /?s= by using /products?search=<q>
      final path =
          'products?search=${Uri.encodeQueryComponent(query.value)}&limit=$_perPage&page=$_page';
      final data = await _net.getApi(path);

      List list = [];
      if (data is Map) {
        if (data['data'] != null && data['data']['products'] is List) {
          list = data['data']['products'];
        } else if (data['products'] is List) {
          list = data['products'];
        }
      } else if (data is List) {
        list = data;
      }

      var mapped = list.map((e) => (e as Map).cast<String, dynamic>()).toList();

      final searchedColor = _detectColor(query.value);
      if (searchedColor != null && searchedColor.isNotEmpty) {
        mapped = mapped.where((p) => _matchesColor(p, searchedColor)).map((p) {
          final copy = Map<String, dynamic>.from(p);
          final colorImg = _resolveColorVariationImage(copy, searchedColor);
          if (colorImg != null && colorImg.isNotEmpty) {
            copy['thumbnail'] = colorImg;
            copy['image'] = colorImg;
            copy['featuredImage'] = colorImg;
          }
          return copy;
        }).toList();
      }

      if (append) {
        results.addAll(mapped);
      } else {
        results.assignAll(mapped);
      }

      // if fewer than perPage returned, we’re done
      _hasMore = mapped.length >= _perPage;
    } catch (e) {
      error.value = e.toString();
      _hasMore = false;
    } finally {
      loading.value = false;
    }
  }

  static const _knownColors = [
    'red', 'blue', 'black', 'white', 'green', 'yellow', 'pink',
    'purple', 'orange', 'navy', 'grey', 'gray', 'brown', 'beige',
    'gold', 'silver', 'maroon', 'lavender', 'cyan', 'magenta',
  ];

  String? _detectColor(String text) {
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    for (final w in words) {
      final clean = w.replaceAll(RegExp(r'[^a-z]'), '');
      if (_knownColors.contains(clean)) {
        return clean;
      }
    }
    return null;
  }

  String? _resolveColorVariationImage(Map<String, dynamic> product, String color) {
    final c = color.trim().toLowerCase();
    final regex = RegExp(r'\b' + RegExp.escape(c) + r'\b', caseSensitive: false);

    // 1. Check variations array for color attribute matching `color`
    final vars = product['variations'] ?? product['variants'];
    if (vars is List) {
      for (final v in vars) {
        if (v is Map) {
          final attrs = (v['attributes'] as List?) ?? (v['attrs'] as List?);
          bool isMatch = false;
          if (attrs != null) {
            for (final a in attrs) {
              if (a is Map) {
                final opt = (a['option'] ?? a['value'] ?? a['name'] ?? '').toString();
                if (regex.hasMatch(opt)) {
                  isMatch = true;
                  break;
                }
              }
            }
          }
          final vName = (v['name'] ?? v['color'] ?? v['title'] ?? '').toString();
          if (regex.hasMatch(vName)) isMatch = true;

          if (isMatch) {
            final vImg = v['image'] ?? v['imageUrl'] ?? v['src'] ?? v['thumbnail'];
            String? u;
            if (vImg is Map) {
              u = (vImg['url'] ?? vImg['src'] ?? vImg['imageUrl'] ?? vImg['thumbnail'])?.toString();
            } else if (vImg != null) {
              u = vImg.toString();
            }
            if (u != null && u.isNotEmpty) {
              return u;
            }
          }
        }
      }
    }

    // 2. Check images array for images with color attribute or alt matching `color`
    dynamic imgs = product['images'];
    if (imgs is List) {
      for (final item in imgs) {
        if (item is Map) {
          final alt = (item['color'] ?? item['alt'] ?? item['name'] ?? item['title'] ?? '').toString();
          final src = (item['imageUrl'] ?? item['url'] ?? item['src'] ?? item['thumbnail'])?.toString();
          if (regex.hasMatch(alt) || (src != null && regex.hasMatch(src))) {
            if (src != null && src.isNotEmpty) return src;
          }
        } else if (item != null) {
          final src = item.toString();
          if (regex.hasMatch(src)) return src;
        }
      }
    }

    return null;
  }

  bool _matchesColor(Map<String, dynamic> product, String color) {
    final c = color.trim().toLowerCase();
    final regex = RegExp(r'\b' + RegExp.escape(c) + r'\b', caseSensitive: false);
    
    // 1. Check title / name / slug
    final name = (product['name'] ?? product['title'] ?? '').toString();
    final slug = (product['slug'] ?? '').toString();
    if (regex.hasMatch(name) || regex.hasMatch(slug)) {
      return true;
    }

    // 2. Check direct color fields / attributes / variations
    final colorField = (product['color'] ?? product['colors'])?.toString() ?? '';
    if (regex.hasMatch(colorField)) return true;

    final attrs = product['attributes'];
    if (attrs is List) {
      for (final a in attrs) {
        if (a is Map) {
          final n = (a['name'] ?? a['attribute'] ?? '').toString().toLowerCase();
          final opts = (a['options'] ?? a['values'] ?? a['option'] ?? '').toString();
          if ((n.contains('color') || n.contains('colour')) && regex.hasMatch(opts)) {
            return true;
          }
        }
      }
    }

    final vars = product['variations'] ?? product['variants'];
    if (vars is List) {
      for (final v in vars) {
        final vStr = v.toString();
        if (regex.hasMatch(vStr)) return true;
      }
    }

    // 3. Check image URLs for color keyword
    dynamic imgs = product['images'];
    if (imgs is List) {
      for (final item in imgs) {
        final u = item is Map ? (item['imageUrl'] ?? item['url'] ?? item['src'])?.toString() : item?.toString();
        if (u != null && regex.hasMatch(u)) {
          return true;
        }
      }
    }

    final thumb = (product['thumbnail'] ?? product['thumbnailImage'] ?? product['featuredImage'] ?? product['image'])?.toString();
    if (thumb != null && regex.hasMatch(thumb)) {
      return true;
    }

    return false;
  }

  String? pickImage(Map<String, dynamic> product) {
    final searchedColor = _detectColor(query.value);
    if (searchedColor != null && searchedColor.isNotEmpty) {
      final thumb = (product['thumbnail'] ?? product['thumbnailImage'] ?? product['featuredImage'] ?? product['image'])?.toString();
      if (thumb != null && thumb.toLowerCase().contains(searchedColor)) {
        return thumb;
      }

      dynamic imgs = product['images'];
      if (imgs is List) {
        for (final item in imgs) {
          String? u;
          if (item is Map) {
            u = (item['imageUrl'] ?? item['url'] ?? item['src'] ?? item['thumbnail'])?.toString();
          } else {
            u = item?.toString();
          }
          if (u != null && u.toLowerCase().contains(searchedColor)) {
            return u;
          }
        }
      }
    }

    final thumb = (product['thumbnail'] ?? product['thumbnailImage'] ?? product['featuredImage'] ?? product['image'])?.toString();
    if (thumb != null && thumb.isNotEmpty) {
      return thumb;
    }
    dynamic imgs = product['images'];
    if (imgs is List && imgs.isNotEmpty) {
      final first = imgs.first;
      if (first is Map) {
        return (first['imageUrl'] ?? first['url'] ?? first['src'] ?? first['thumbnail'])?.toString();
      }
      return first?.toString();
    }
    return null;
  }

  String priceText(Map<String, dynamic> product) {
    var p = (product['price'] ?? product['regularPrice'] ?? 0).toString().trim();
    if (p.endsWith('.00')) p = p.substring(0, p.length - 3);
    final d = double.tryParse(p);
    if (d != null && d == d.toInt()) p = d.toInt().toString();
    return '₹$p'.replaceFirst(RegExp(r'\.00$'), '').replaceAll('.00', '');
  }
}
