// lib/data/wc_store_api.dart
import 'package:dio/dio.dart';
import 'package:tobeque/constants/api_constants.dart';

class WcStoreApi {
  final Dio dio;
  WcStoreApi(this.dio);

  Future<List<ProductCategory>> getCategories({int perPage = 20}) async {
    final res = await dio.get(
      ApiConstant.categories,
      options: Options(headers: {
        'Accept': 'application/json',
      }),
    );
    final data = res.data;
    List list = [];
    if (data is Map && data['categories'] is List) {
      list = data['categories'];
    } else if (data is List) {
      list = data;
    }
    return list.map((e) => ProductCategory.fromJson((e as Map).cast<String, dynamic>())).toList();
  }
}

class ProductCategory {
  final String id;
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
    String imgUrl = '';
    if (j['image'] != null) {
      if (j['image'] is String) {
        imgUrl = j['image'];
      } else if (j['image'] is Map) {
        imgUrl = j['image']['url'] ?? j['image']['src'] ?? '';
      }
    }
    return ProductCategory(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      slug: (j['slug'] ?? '').toString(),
      imageUrl: ApiConstant.getImageUrl(imgUrl),
      count: (j['productCount'] ?? j['count'] ?? 0) as int,
    );
  }
}

