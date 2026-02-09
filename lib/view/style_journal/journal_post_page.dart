import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_html/flutter_html.dart';
import 'style_journal_repository.dart';

class JournalPostPage extends StatefulWidget {
  const JournalPostPage({super.key, required this.postId});
  final int postId;

  @override
  State<JournalPostPage> createState() => _JournalPostPageState();
}

class _JournalPostPageState extends State<JournalPostPage> {
  final repo = StyleJournalRepository();
  JournalPostDetails? post;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() => error = null);
      final p = await repo.fetchPost(widget.postId);
      setState(() => post = p);
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = post;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Style Journal'),
          centerTitle: true,
          elevation: 0.5,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    if (p == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.grey)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: [
          if ((p.imageUrl ?? '').isNotEmpty)
            AspectRatio(
              aspectRatio: 4/6,
              child: Image.network(
                p.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: Color(0xFFEFEFEF)),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            _formatDate(p.date),
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            p.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),

          // Render post content HTML as Flutter widgets
          Html(
            data: p.contentHtml,
            style: {
              "p": Style(fontSize: FontSize(16), lineHeight: LineHeight(1.5)),
              "h1": Style(fontWeight: FontWeight.w800),
              "h2": Style(fontWeight: FontWeight.w800),
              "h3": Style(fontWeight: FontWeight.w700),
            },
            onLinkTap: (url, _, __) {
              if (url != null) {
                // Let system browser handle external links
                // (Optional) use url_launcher here if you want
              }
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${_pad(d.day)} ${_month(d.month)} ${d.year}';
  String _month(int m) =>
      const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];
  String _pad(int n) => n < 10 ? '0$n' : '$n';
}
