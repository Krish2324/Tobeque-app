// lib/data/wp_service.dart
import 'package:tobeque/constants/api_constants.dart';
import 'package:dio/dio.dart';


class WPService {
  final Dio _dio;
  WPService(this._dio);

  // WP Core
  Future<List<dynamic>> fetchPages({String? slug}) async {
    final res = await _dio.get(
      ApiConstant.wp('pages'),
      queryParameters: {'_embed': 1, if (slug != null) 'slug': slug},
    );
    return res.data as List<dynamic>;
  }

  // Woo Store API (public, no auth)
  Future<List<dynamic>> fetchProducts({
    int page = 1, int perPage = 12, String? category, String? search,
    String orderby = 'date', String order = 'desc',
  }) async {
    final res = await _dio.get(
      ApiConstant.wcStore('products'),
      queryParameters: {
        'page': page, 'per_page': perPage,
        if (category != null) 'category': category,
        if (search != null && search.isNotEmpty) 'search': search,
        'orderby': orderby, 'order': order,
      },
    );
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> fetchCategories({int perPage = 100}) async {
    final res = await _dio.get(
      ApiConstant.wcStore('products/categories'),
      queryParameters: {'per_page': perPage, 'hide_empty': true},
    );
    return res.data as List<dynamic>;
  }

  // Woo REST v3 (needs CK/CS) — avoid in client if possible
  Future<List<dynamic>> adminProductsV3({int page = 1, int perPage = 10}) async {
    final res = await _dio.get(
      ApiConstant.wcV3('products'),
      queryParameters: {
        'page': page, 'per_page': perPage,
        'consumer_key': ApiConstant.consumerKey,
        'consumer_secret': ApiConstant.consumerSecret,
      },
    );
    return res.data as List<dynamic>;
  }
}
