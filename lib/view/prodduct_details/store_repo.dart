import 'package:dio/dio.dart';

class StoreRepository {
  final Dio _dio = Dio(
    BaseOptions(baseUrl: "https://tobeque.com/wp-json/wc/store/products"),
  );

  Future<Map<String, dynamic>> fetchProduct(int id) async {
    final res = await _dio.get("/$id");
    return res.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchRelatedByCategory(
    int categoryId, {
    int excludeId = 0,
  }) async {
    final res = await _dio.get("",
        queryParameters: {"category": categoryId, "per_page": 10, "exclude": excludeId});
    return (res.data as List).cast<Map<String, dynamic>>();
  }
}
