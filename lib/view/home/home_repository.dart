import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/data/dio_client.dart';
import 'package:tobeque/services/shared_pref.dart';
import 'models.dart';

String _cleanPrice(dynamic raw) {
  if (raw == null) return '0';
  var s = raw.toString().trim();
  if (s.endsWith('.00')) {
    s = s.substring(0, s.length - 3);
  }
  final d = double.tryParse(s);
  if (d != null && d == d.toInt()) {
    return d.toInt().toString();
  }
  return s.replaceFirst(RegExp(r'\.00$'), '').replaceAll('.00', '');
}

class HomeRepository {
  final Dio _dio = DioClient.build();

  // Static in-memory cache to prevent repeated API calls & enable instant transitions
  static final Map<String, dynamic> _cacheMap = {};

  Future<void> _saveDiskCache(String key, dynamic data) async {
    try {
      final jsonStr = jsonEncode(data);
      await SharedPrefService.setString(key, jsonStr);
    } catch (_) {}
  }

  Future<dynamic> _readDiskCache(String key) async {
    try {
      final jsonStr = await SharedPrefService.getString(key);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return jsonDecode(jsonStr);
      }
    } catch (_) {}
    return null;
  }


  Future<List<Map<String, dynamic>>> fetchSubcategories({
    required dynamic parentId,
    int perPage = 50,
  }) async {
    try {
      final res = await _dio.get(ApiConstant.categories);
      final data = res.data;
      List list = [];
      if (data is Map && data['categories'] is List) {
        list = data['categories'];
      } else if (data is List) {
        list = data;
      }
      return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> fetchHeroVideoUrl() async {
    try {
      final res = await _dio.get(ApiConstant.banners);
      final data = res.data;
      List list = [];
      if (data is Map && data['banners'] is List) {
        list = data['banners'];
      } else if (data is List) {
        list = data;
      }
      for (final b in list) {
        if (b is Map) {
          final u = (b['videoUrl'] ?? b['bannerLink'] ?? b['linkUrl'] ?? b['mobileImageUrl'] ?? b['imageUrl'] ?? '').toString();
          if (u.contains('.mp4') || u.contains('youtube.com') || u.contains('youtu.be') || u.contains('.m3u8')) {
            return ApiConstant.getImageUrl(u);
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<WpPageHero> fetchHero() async {
    const key = 'home_hero';
    if (_cacheMap.containsKey(key) && _cacheMap[key] != null) {
      return _cacheMap[key] as WpPageHero;
    }
    final disk = await _readDiskCache(key);
    if (disk is Map) {
      final cached = WpPageHero.fromJson((disk as Map).cast<String, dynamic>());
      _cacheMap[key] = cached;
      return cached;
    }
    try {
      final res = await _dio.get(ApiConstant.banners);
      final data = res.data;
      List list = [];
      if (data is Map && data['banners'] is List) {
        list = data['banners'];
      } else if (data is List) {
        list = data;
      }
      WpPageHero hero;
      if (list.isNotEmpty) {
        final mobileAppBanners = list.where((b) => b['position'] == 'mobile_app' || b['position'] == 'mobile_banner' || b['position'] == 'home_slider').toList();
        if (mobileAppBanners.isNotEmpty) {
          final mobileImages = mobileAppBanners.map((b) {
            final img = b['mobileImageUrl'] ?? b['mobileImage'] ?? b['imageUrl'] ?? b['image'];
            return ApiConstant.getImageUrl(img?.toString());
          }).whereType<String>().toList();
          hero = WpPageHero(
            imageUrl: mobileImages.isNotEmpty ? mobileImages.first : null,
            mobileBanners: mobileImages,
          );
        } else {
          final b = list.first as Map;
          final img = b['mobileImageUrl'] ?? b['mobileImage'] ?? b['image'] ?? b['imageUrl'] ?? b['desktopImage'];
          final url = ApiConstant.getImageUrl(img?.toString());
          hero = WpPageHero(imageUrl: url, mobileBanners: url != null ? [url] : []);
        }
      } else {
        hero = WpPageHero(imageUrl: null);
      }
      _cacheMap[key] = hero;
      _saveDiskCache(key, hero.toJson());
      return hero;
    } catch (_) {}
    return _cacheMap[key] ?? WpPageHero(imageUrl: null);
  }

  Future<List<WcCategory>> fetchCategories({int perPage = 25}) async {
    const key = 'home_categories';
    if (_cacheMap.containsKey(key) && (_cacheMap[key] as List).isNotEmpty) {
      return List<WcCategory>.from(_cacheMap[key]);
    }
    final disk = await _readDiskCache(key);
    if (disk is List && disk.isNotEmpty) {
      final cached = disk.map((e) => WcCategory.fromJson(e as Map<String, dynamic>)).toList();
      _cacheMap[key] = cached;
      return cached;
    }
    try {
      final res = await _dio.get(ApiConstant.seasonCollection);
      final data = res.data;
      List list = [];
      if (data is Map && data['data'] is List) {
        list = data['data'];
      } else if (data is Map && data['categories'] is List) {
        list = data['categories'];
      } else if (data is List) {
        list = data;
      }
      final result = list.map<WcCategory>((c) {
        // Support both Season Collection schema and standard Category schema
        final categoryObj = c['category'] is Map ? c['category'] : c;
        
        dynamic rawImg = c['imageOverride'] ?? c['customImage'] ?? categoryObj['image'];
        String? img;
        if (rawImg is Map) {
          img = (rawImg['url'] ?? rawImg['src'])?.toString();
        } else {
          img = rawImg?.toString();
        }
        
        return WcCategory(
          id: (c['categoryId'] ?? categoryObj['_id'] ?? categoryObj['id'] ?? c['_id'] ?? c['id'] ?? '').toString(),
          name: (c['displayLabel'] ?? c['customLabel'] ?? categoryObj['name'] ?? c['name'] ?? '').toString(),
          image: ApiConstant.getImageUrl(img?.toString()),
        );
      }).toList();
      _cacheMap[key] = result;
      _saveDiskCache(key, result.map((e) => e.toJson()).toList());
      return result;
    } catch (_) {
      return List<WcCategory>.from(_cacheMap[key] ?? []);
    }
  }

  Future<List<WcProduct>> fetchBestSellers({int perPage = 50}) async {
    const key = 'home_bestsellers_v3';
    if (_cacheMap.containsKey(key) && (_cacheMap[key] as List).isNotEmpty) {
      return List<WcProduct>.from(_cacheMap[key]);
    }
    final disk = await _readDiskCache(key);
    if (disk is List && disk.isNotEmpty) {
      final cached = disk.map((e) => WcProduct.fromJson(e as Map<String, dynamic>)).toList();
      _cacheMap[key] = cached;
      return cached;
    }
    try {
      final res = await _dio.get('${ApiConstant.products}?status=published&featured=true&limit=$perPage');
      final data = res.data;
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
      final result = list.map<WcProduct>((p) {
        final imageList = <String>[];
        final thumb = ApiConstant.getImageUrl(
          (p['thumbnail'] ?? p['thumbnailImage'] ?? p['featuredImage'] ?? p['featured_image'] ?? p['coverImage'] ?? p['mainImage'] ?? p['image'] ?? p['imageUrl'])?.toString(),
        );
        if (thumb.isNotEmpty) {
          imageList.add(thumb);
        }

        dynamic imgs = p['images'];
        if (imgs is List) {
          for (final item in imgs) {
            String? u;
            if (item is Map) {
              u = (item['imageUrl'] ?? item['url'] ?? item['src'] ?? item['thumbnail'])?.toString();
            } else {
              u = item?.toString();
            }
            final fullUrl = ApiConstant.getImageUrl(u);
            if (fullUrl.isNotEmpty && !imageList.contains(fullUrl)) {
              imageList.add(fullUrl);
            }
          }
        }

        final primary = imageList.isNotEmpty ? imageList.first : null;

        return WcProduct(
          id: (p['_id'] ?? p['id'] ?? '').toString(),
          name: (p['name'] ?? p['title'] ?? '').toString(),
          priceHtml: '₹${_cleanPrice(p['price'] ?? p['regularPrice'] ?? 0)}',
          image: primary,
          images: imageList,
          rawMap: (p as Map).cast<String, dynamic>(),
        );
      }).toList();
      _cacheMap[key] = result;
      _saveDiskCache(key, result.map((e) => e.toJson()).toList());
      return result;
    } catch (_) {
      return List<WcProduct>.from(_cacheMap[key] ?? []);
    }
  }

  Future<Map<String, dynamic>> fetchProduct(dynamic id) async {
    final res = await _dio.get('${ApiConstant.products}/$id');
    final data = res.data;
    if (data is Map && data['product'] != null) {
      return (data['product'] as Map).cast<String, dynamic>();
    }
    return (data as Map).cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> fetchProductsByCategory({
    required dynamic categoryId,
    int perPage = 20,
    int page = 1,
  }) async {
    final key = 'category_${categoryId}_$page';
    if (_cacheMap.containsKey(key) && (_cacheMap[key] as List).isNotEmpty) {
      return List<Map<String, dynamic>>.from(_cacheMap[key]);
    }
    final disk = await _readDiskCache(key);
    if (disk is List && disk.isNotEmpty) {
      final cached = List<Map<String, dynamic>>.from(disk);
      _cacheMap[key] = cached;
      return cached;
    }
    try {
      final isAll = categoryId == null || categoryId.toString().isEmpty || categoryId == 'all';
      final url = isAll
          ? '${ApiConstant.products}?status=published&page=$page&limit=$perPage'
          : '${ApiConstant.products}?category=$categoryId&page=$page&limit=$perPage';
      final res = await _dio.get(url);
      final data = res.data;
      List<Map<String, dynamic>> list = [];
      if (data is Map) {
        if (data['data'] != null && data['data']['products'] is List) {
          list = (data['data']['products'] as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
        } else if (data['products'] is List) {
          list = (data['products'] as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
        }
      }
      _cacheMap[key] = list;
      _saveDiskCache(key, list);
      return list;
    } catch (_) {
      return List<Map<String, dynamic>>.from(_cacheMap[key] ?? []);
    }
  }

  // ── NEW: On Sale products ──────────────────────────────────────────────────
  Future<List<WcProduct>> fetchOnSaleProducts({int perPage = 15}) async {
    const key = 'home_onsale_v3';
    if (_cacheMap.containsKey(key) && (_cacheMap[key] as List).isNotEmpty) {
      return List<WcProduct>.from(_cacheMap[key]);
    }
    final disk = await _readDiskCache(key);
    if (disk is List && disk.isNotEmpty) {
      final cached = disk.map((e) => WcProduct.fromJson(e as Map<String, dynamic>)).toList();
      _cacheMap[key] = cached;
      return cached;
    }
    try {
      final res = await _dio.get('${ApiConstant.products}?status=published&isOnSaleSection=true&limit=$perPage');
      final data = res.data;
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
      final result = list.map<WcProduct>((p) {
        final imageList = <String>[];
        final thumb = ApiConstant.getImageUrl(
          (p['thumbnail'] ?? p['thumbnailImage'] ?? p['featuredImage'] ?? p['featured_image'] ?? p['coverImage'] ?? p['mainImage'] ?? p['image'] ?? p['imageUrl'])?.toString(),
        );
        if (thumb.isNotEmpty) {
          imageList.add(thumb);
        }

        dynamic imgs = p['images'];
        if (imgs is List) {
          for (final item in imgs) {
            String? u;
            if (item is Map) {
              u = (item['imageUrl'] ?? item['url'] ?? item['src'] ?? item['thumbnail'])?.toString();
            } else {
              u = item?.toString();
            }
            final fullUrl = ApiConstant.getImageUrl(u);
            if (fullUrl.isNotEmpty && !imageList.contains(fullUrl)) {
              imageList.add(fullUrl);
            }
          }
        }

        final primary = imageList.isNotEmpty ? imageList.first : null;
        final salePrice    = _cleanPrice(p['salePrice'] ?? p['price'] ?? 0);
        final regularPrice = _cleanPrice(p['regularPrice'] ?? p['price'] ?? 0);
        return WcProduct(
          id: (p['_id'] ?? p['id'] ?? '').toString(),
          name: (p['name'] ?? p['title'] ?? '').toString(),
          priceHtml: '₹$salePrice',
          image: primary,
          images: imageList,
          originalPrice: regularPrice != salePrice ? '₹$regularPrice' : null,
          rawMap: (p as Map).cast<String, dynamic>(),
        );
      }).toList();
      _cacheMap[key] = result;
      _saveDiskCache(key, result.map((e) => e.toJson()).toList());
      return result;
    } catch (_) {
      return List<WcProduct>.from(_cacheMap[key] ?? []);
    }
  }

  // ── NEW: Hot Right Now trending products ───────────────────────────────────
  Future<List<WcProduct>> fetchHotRightNow({int perPage = 10}) async {
    const key = 'home_hotrightnow_v3';
    if (_cacheMap.containsKey(key) && (_cacheMap[key] as List).isNotEmpty) {
      return List<WcProduct>.from(_cacheMap[key]);
    }
    final disk = await _readDiskCache(key);
    if (disk is List && disk.isNotEmpty) {
      final cached = disk.map((e) => WcProduct.fromJson(e as Map<String, dynamic>)).toList();
      _cacheMap[key] = cached;
      return cached;
    }
    try {
      final res = await _dio.get('${ApiConstant.products}?status=published&isHotRightNow=true&limit=$perPage');
      final data = res.data;
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
      final result = list.map<WcProduct>((p) {
        final imageList = <String>[];
        final thumb = ApiConstant.getImageUrl(
          (p['thumbnail'] ?? p['thumbnailImage'] ?? p['featuredImage'] ?? p['featured_image'] ?? p['coverImage'] ?? p['mainImage'] ?? p['image'] ?? p['imageUrl'])?.toString(),
        );
        if (thumb.isNotEmpty) {
          imageList.add(thumb);
        }

        dynamic imgs = p['images'];
        if (imgs is List) {
          for (final item in imgs) {
            String? u;
            if (item is Map) {
              u = (item['imageUrl'] ?? item['url'] ?? item['src'] ?? item['thumbnail'])?.toString();
            } else {
              u = item?.toString();
            }
            final fullUrl = ApiConstant.getImageUrl(u);
            if (fullUrl.isNotEmpty && !imageList.contains(fullUrl)) {
              imageList.add(fullUrl);
            }
          }
        }

        final primary = imageList.isNotEmpty ? imageList.first : null;
        final hotMedia     = p['hotRightNowMedia']?.toString();
        final salePrice    = _cleanPrice(p['salePrice'] ?? p['price'] ?? 0);
        final regularPrice = _cleanPrice(p['regularPrice'] ?? p['price'] ?? 0);
        final catSlug      = (p['category'] is Map ? p['category']['slug'] : p['categorySlug'])?.toString() ?? 'all';
        final slug         = (p['slug'] ?? p['_id'] ?? p['id'] ?? '').toString();
        return WcProduct(
          id: (p['_id'] ?? p['id'] ?? '').toString(),
          name: (p['name'] ?? p['title'] ?? '').toString(),
          priceHtml: '₹$salePrice',
          image: primary,
          images: imageList,
          originalPrice: regularPrice != salePrice ? '₹$regularPrice' : null,
          hotMedia: hotMedia != null && hotMedia.isNotEmpty ? ApiConstant.getImageUrl(hotMedia) : null,
          categorySlug: catSlug,
          slug: slug,
          rawMap: (p as Map).cast<String, dynamic>(),
        );
      }).toList();
      _cacheMap[key] = result;
      _saveDiskCache(key, result.map((e) => e.toJson()).toList());
      return result;
    } catch (_) {
      return List<WcProduct>.from(_cacheMap[key] ?? []);
    }
  }

  // ── NEW: Bottom promo banner ───────────────────────────────────────────────
  Future<Map<String, dynamic>?> fetchBottomBanner() async {
    const key = 'home_bottom_banner';
    if (_cacheMap.containsKey(key)) {
      return _cacheMap[key] as Map<String, dynamic>?;
    }
    final disk = await _readDiskCache(key);
    if (disk is Map) {
      final cached = (disk as Map).cast<String, dynamic>();
      _cacheMap[key] = cached;
      return cached;
    }
    try {
      final res = await _dio.get(ApiConstant.banners);
      final data = res.data;
      List list = [];
      if (data is Map && data['banners'] is List) {
        list = data['banners'];
      } else if (data is List) {
        list = data;
      }
      final active = list.where((b) => b['status'] == true || b['status'] == 'active').toList();
      final bottom = active.firstWhere(
        (b) => b['position'] == 'promo_bottom',
        orElse: () => null,
      );
      if (bottom == null) return null;
      final bottomMap = (bottom as Map).cast<String, dynamic>();
      _cacheMap[key] = bottomMap;
      _saveDiskCache(key, bottomMap);
      return bottomMap;
    } catch (_) {
      return _cacheMap[key];
    }
  }
}

