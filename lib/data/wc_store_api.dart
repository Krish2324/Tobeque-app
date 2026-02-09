// lib/data/wc_store_api.dart
import 'package:dio/dio.dart';

class WcStoreApi {
  final Dio dio;
  WcStoreApi(this.dio);

  Future<List<ProductCategory>> getCategories({int perPage = 20}) async {
    final res = await dio.get(
      '/wp-json/wc/store/v1/products/categories',
      queryParameters: {
        'hide_empty': true,
        'per_page': perPage,
        '_fields': 'id,name,slug,image,count',
      },
      options: Options(headers: {
        // make sure there is NO Authorization header for public calls
        'Accept': 'application/json',
      }),
    );
    final data = (res.data as List).cast<Map<String, dynamic>>();
    return data.map(ProductCategory.fromJson).toList();
  }
}

class ProductCategory {
  final int id;
  final String name;
  final String slug;
  final String? imageUrl;
  final int count;

  ProductCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.imageUrl,
    required this.count,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> j) {
    final img = j['image'] as Map<String, dynamic>?;
    return ProductCategory(
      id: j['id'] as int,
      name: j['name'] as String,
      slug: j['slug'] as String,
      imageUrl: img?['src'] as String?,
      count: (j['count'] ?? 0) as int,
    );
  }
}
