import 'package:tobeque/view/cetegory/category_page.dart';
import 'package:tobeque/view/prodduct_details/product_detail_binding.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:get/get.dart';

import 'package:tobeque/view/search/search_controller.dart';
import 'package:tobeque/view/search/search_binding.dart';
import 'package:tobeque/view/prodduct_details/product_details_page.dart'; // adjust import if your file name differs

class SearchScreen extends GetView<SearchController> {
  SearchScreen({super.key}) {
    // ensure controller exists when this screen is opened directly
    SearchBinding().dependencies();
  }

  final _scrollCtl = ScrollController();

  @override
  Widget build(BuildContext context) {
    TextEditingController controllerT=TextEditingController();
    _scrollCtl.addListener(() {
      if (_scrollCtl.position.pixels >=
          _scrollCtl.position.maxScrollExtent - 300) {
        controller.loadMore();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.bottomLeft,
          child: const Text(' Search products')),
       // centerTitle: true,
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // search field
         Padding(
  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: TextField(
      controller:controllerT ,
      textInputAction: TextInputAction.search,
      onChanged: controller.onQueryChanged,
      onSubmitted: controller.onQueryChanged,
      decoration: InputDecoration(
        hintText: 'Search products…',
        hintStyle: const TextStyle(color: Colors.black54, fontSize: 15),
        prefixIcon: const Icon(Icons.search, color: Colors.black87),
        suffixIcon: Obx(() {
          if (controller.query.value.isEmpty) return const SizedBox.shrink();
          return IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () {
              controllerT.clear();
            },
          );
        }),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black, width: 1.4),
        ),
      ),
    ),
  ),
),


          // content
          Expanded(
            child: Obx(() {
              final q = controller.query.value.trim();
              final loading = controller.loading.value;
              final err = controller.error.value;
              final items = controller.results;

              if (q.isEmpty) {
                return const _Placeholder(
                  icon: Icons.search,
                  title: 'Start typing to search',
                  subtitle: 'We’ll show products that match your query',
                );
              }

              if (err != null) {
                return _ErrorState(
                  message: err,
                  onRetry: controller.refreshNow,
                );
              }

              if (loading && items.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: Colors.black,));
              }

              if (items.isEmpty) {
                return const _Placeholder(
                  icon: Icons.search_off,
                  title: 'No results',
                  subtitle:
                      'Try a different keyword or check the spelling.',
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshNow,
                child: CustomScrollView(
                  controller: _scrollCtl,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final p = items[index];
                           
                            final id = (p['_id'] ?? p['id'] ?? '').toString();

                            return InkWell(
                               onTap: () {
                                Get.to(
            () => ProductDetailPage(key: ValueKey(id), productId: id),
            binding: ProductDetailBinding(id),
          );},
                              child: SmallTile(p: p,));
                          },
                          childCount: items.length,
                        ),
                        gridDelegate:
                             SliverGridDelegateWithFixedCrossAxisCount(
                       crossAxisCount:  2 ,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 4,
                  childAspectRatio:  0.588 ,
                        ),
                      ),
                    ),

                    // infinite scroll footer
                    SliverToBoxAdapter(
                      child: Obx(() {
                        if (controller.loading.value && controller.results.isNotEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator(color: Colors.black,)),
                          );
                        }
                        if (!controller.hasMore) {
                          return const SizedBox(height: 24);
                        }
                        return const SizedBox.shrink();
                      }),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ UI widgets ------------------------------ */

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 10),
            Text('Something went wrong', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

