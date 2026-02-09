// lib/features/home/sections/season_collection.dart
import 'package:flutter/material.dart';
import 'package:tobeque/data/wc_store_api.dart';

class SeasonCollection extends StatefulWidget {
  final WcStoreApi api;
  const SeasonCollection({super.key, required this.api});

  @override
  State<SeasonCollection> createState() => _SeasonCollectionState();
}

class _SeasonCollectionState extends State<SeasonCollection> {
  late Future<List<ProductCategory>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getCategories(perPage: 12);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductCategory>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 210, child: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load categories: ${snap.error}'),
          );
        }
        final items = snap.data!;
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text('Season Collection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ),
            SizedBox(
              height: 210,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _CategoryCard(cat: items[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ProductCategory cat;
  const _CategoryCard({required this.cat});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: push to a category products screen using cat.id or cat.slug
      },
      child: SizedBox(
        width: 160,
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (cat.imageUrl != null)
                Image.network(cat.imageUrl!, fit: BoxFit.cover)
              else
                Container(color: Colors.grey.shade200),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(0, -0.6),
                    end: Alignment(0, 1),
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Text(cat.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        )),
                    Text('${cat.count} items',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
