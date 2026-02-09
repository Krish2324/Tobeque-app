import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'style_journal_controller.dart';
import 'journal_post_page.dart';

class StyleJournalPage extends StatelessWidget {
  StyleJournalPage({super.key});

  final c = Get.put(StyleJournalController());
  final _scrollCtl = ScrollController();

  @override
  Widget build(BuildContext context) {
    _scrollCtl.addListener(() {
      if (_scrollCtl.position.pixels >=
          _scrollCtl.position.maxScrollExtent - 300) {
        c.loadMore();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Style Journal'),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Obx(() {
        if (c.loading.value && c.posts.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Colors.grey));
        }
        if (c.error.value != null && c.posts.isEmpty) {
          return _ErrorState(message: c.error.value!, onRetry: c.refreshNow);
        }

        return RefreshIndicator(
          onRefresh: c.refreshNow,
          child: ListView.separated(
            controller: _scrollCtl,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: c.posts.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              if (i == c.posts.length) {
                if (c.loading.value && c.posts.isNotEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(color: Colors.grey)),
                  );
                }
                return const SizedBox.shrink();
              }

              final p = c.posts[i];
              return InkWell(
                onTap: () => Get.to(() => JournalPostPage(postId: p.id)),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xffeeeeee)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // thumbnail
                     // thumbnail
SizedBox(
  width: 140, // controls overall thumb size
  child: _JournalThumb(
    url: p.imageUrl,
    heroTag: 'post_${p.id}_img', // for smooth transition
    aspect: 3/5,               // keep it consistent across list & detail
    radius: 0,
  ),
),

                      // text
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatDate(p.date),
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                              if (p.excerpt.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  p.excerpt,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  String _formatDate(DateTime d) =>
      '${_pad(d.day)} ${_month(d.month)} ${d.year}';
  String _month(int m) =>
      const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];
  String _pad(int n) => n < 10 ? '0$n' : '$n';
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
class _JournalThumb extends StatelessWidget {
  const _JournalThumb({
    required this.url,
    this.heroTag,
    this.aspect = 4 / 5,
    this.radius = 10,
    super.key,
  });

  final String? url;
  final String? heroTag;
  final double aspect;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final img = (url == null || url!.isEmpty)
        ? const ColoredBox(color: Color(0xFFF2F2F2))
        : Image.network(
            url!,
            fit: BoxFit.cover,
            // lightweight skeleton-esque placeholder
            loadingBuilder: (ctx, child, evt) {
              if (evt == null) return child;
              return const ColoredBox(color: Color(0xFFF6F6F6));
            },
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: Color(0xFFEFEFEF)),
          );

    final content = AspectRatio(
      aspectRatio: aspect,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            img,
            // subtle hairline stroke for a crisp card edge
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Optional Hero for a smooth to-detail transition
    return heroTag == null ? content : Hero(tag: heroTag!, child: content);
  }
}
