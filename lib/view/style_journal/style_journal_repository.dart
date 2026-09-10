import 'package:dio/dio.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/data/dio_client.dart';

class JournalPost {
  final dynamic id;
  final String title;
  final String link;
  final String? imageUrl;
  final DateTime date;
  final String excerpt;

  JournalPost({
    required this.id,
    required this.title,
    required this.link,
    required this.imageUrl,
    required this.date,
    required this.excerpt,
  });
}

class JournalPostDetails {
  final dynamic id;
  final String title;
  final String link;
  final String? imageUrl;
  final DateTime date;
  final String contentHtml;

  JournalPostDetails({
    required this.id,
    required this.title,
    required this.link,
    required this.imageUrl,
    required this.date,
    required this.contentHtml,
  });
}

class StyleJournalRepository {
  final Dio _dio = DioClient.build();
  final _un = HtmlUnescape();

  Future<List<JournalPost>> fetchPosts({int page = 1, int perPage = 10}) async {
    try {
      final res = await _dio.get('${ApiConstant.apiBase}/blogs?status=published&page=$page&limit=$perPage');
      final data = res.data;
      List list = [];
      if (data is Map && data['blogs'] is List) {
        list = data['blogs'];
      } else if (data is List) {
        list = data;
      }

      return list.map<JournalPost>((p) {
        final id = (p['_id'] ?? p['id'] ?? 0).hashCode;
        final title = (p['title'] ?? '').toString();
        final img = ApiConstant.getImageUrl(p['featuredImage'] ?? p['image']);
        final dateStr = (p['createdAt'] ?? p['date'] ?? '').toString();
        final dt = DateTime.tryParse(dateStr) ?? DateTime.now();
        final excerpt = (p['summary'] ?? p['excerpt'] ?? '').toString();

        return JournalPost(
          id: id,
          title: _un.convert(title),
          link: '',
          imageUrl: img,
          date: dt,
          excerpt: _un.convert(excerpt),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<JournalPostDetails> fetchPost(dynamic id) async {
    final res = await _dio.get('${ApiConstant.apiBase}/blogs/$id');
    final p = (res.data is Map && res.data['blog'] != null) ? res.data['blog'] as Map<String, dynamic> : res.data as Map<String, dynamic>;

    final img = ApiConstant.getImageUrl(p['featuredImage'] ?? p['image']);
    final dateStr = (p['createdAt'] ?? p['date'] ?? '').toString();
    final dt = DateTime.tryParse(dateStr) ?? DateTime.now();

    return JournalPostDetails(
      id: (p['_id'] ?? p['id'] ?? 0).hashCode,
      title: _un.convert((p['title'] ?? '').toString()),
      link: '',
      imageUrl: img,
      date: dt,
      contentHtml: (p['content'] ?? '').toString(),
    );
  }
}

