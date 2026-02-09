import 'dart:async';
import 'package:get/get.dart';

import 'package:tobeque/data/network/network_api_sarvices.dart';
import 'package:tobeque/view/prodduct_details/product_api_repo.dart';

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
          'products?search=${Uri.encodeQueryComponent(query.value)}&per_page=$_perPage&page=$_page';
      final data = await _net.getApi(path);

      final list = (data as List?) ?? const [];
      final mapped = list.map((e) => (e as Map).cast<String, dynamic>()).toList();

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

  /// Pick the best image from a product object
  String? pickImage(Map<String, dynamic> product) {
    final imgs = (product['images'] as List?) ?? const [];
    if (imgs.isEmpty) return null;
    final m = (imgs.first as Map).cast<String, dynamic>();
    return m['src']?.toString() ?? m['thumbnail']?.toString();
  }

  String priceText(Map<String, dynamic> product) {
    return ProductApi.formatPrice(
      (product['prices'] as Map?)?.cast<String, dynamic>(),
    );
  }
}
