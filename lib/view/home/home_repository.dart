// lib/view/home/home_repository.dart
import 'package:dio/dio.dart';
import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/data/dio_client.dart';
import 'models.dart';

class HomeRepository {
  final Dio _dio = DioClient.build();

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
    return 'https://www.youtube.com/shorts/EmVHGtpCT2Y';
  }

  Future<WpPageHero> fetchHero() async {
    try {
      final res = await _dio.get(ApiConstant.banners);
      final data = res.data;
      List list = [];
      if (data is Map && data['banners'] is List) {
        list = data['banners'];
      } else if (data is List) {
        list = data;
      }
      if (list.isNotEmpty) {
        final mobileAppBanners = list.where((b) => b['position'] == 'mobile_app' || b['position'] == 'mobile_banner' || b['position'] == 'home_slider').toList();
        if (mobileAppBanners.isNotEmpty) {
          final mobileImages = mobileAppBanners.map((b) {
            final img = b['mobileImageUrl'] ?? b['mobileImage'] ?? b['imageUrl'] ?? b['image'];
            return ApiConstant.getImageUrl(img?.toString());
          }).whereType<String>().toList();
          return WpPageHero(
            imageUrl: mobileImages.isNotEmpty ? mobileImages.first : null,
            mobileBanners: mobileImages,
          );
        } else {
          final b = list.first as Map;
          final img = b['mobileImageUrl'] ?? b['mobileImage'] ?? b['image'] ?? b['imageUrl'] ?? b['desktopImage'];
          final url = ApiConstant.getImageUrl(img?.toString());
          return WpPageHero(imageUrl: url, mobileBanners: url != null ? [url] : []);
        }
      }
    } catch (_) {}
    return WpPageHero(imageUrl: null);
  }

  Future<List<WcCategory>> fetchCategories({int perPage = 25}) async {
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
      return list.map<WcCategory>((c) {
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
    } catch (_) {
      return [];
    }
  }

  Future<List<WcProduct>> fetchBestSellers({int perPage = 50}) async {
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
      return list.map<WcProduct>((p) {
        String? img;
        dynamic imgs = p['images'];
        if (imgs is List && imgs.isNotEmpty) {
           final first = imgs.first;
           if (first is Map) {
             // New backend uses 'imageUrl', fallback to 'url' and 'src'
             img = (first['imageUrl'] ?? first['url'] ?? first['src'] ?? '').toString();
           } else {
             img = first?.toString();
           }
        }
        // Fallback to featuredImage only if images array was empty or had no valid URL
        if (img == null || img.isEmpty) {
           img = p['featuredImage']?.toString();
        }
        return WcProduct(
          id: (p['_id'] ?? p['id'] ?? '').toString(),
          name: (p['name'] ?? p['title'] ?? '').toString(),
          priceHtml: '₹${p['price'] ?? p['regularPrice'] ?? 0}',
          image: ApiConstant.getImageUrl(img),
        );
      }).toList();
    } catch (_) {
      return [];
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
    final res = await _dio.get('${ApiConstant.products}?category=$categoryId&page=$page&limit=$perPage');
    final data = res.data;
    if (data is Map) {
      if (data['data'] != null && data['data']['products'] is List) {
        return (data['data']['products'] as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
      } else if (data['products'] is List) {
        return (data['products'] as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
      }
    }
    return [];
  }
}
