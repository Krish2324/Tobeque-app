import 'package:dio/dio.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/data/dio_client.dart';

class JournalPost {
  final int id;
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
  final int id;
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

  Future<int?> _categoryIdBySlug(String slug) async {
    final url = ApiConstant.wp('categories?slug=$slug');
    final res = await _dio.get(url);
    if (res.data is List && (res.data as List).isNotEmpty) {
      return (res.data[0]['id'] as num).toInt();
    }
    return null;
  }

  /// List posts from the `style-journal` category using WP JSON
  Future<List<JournalPost>> fetchPosts({int page = 1, int perPage = 10}) async {
    final catId = await _categoryIdBySlug('style-journal');

    final qp = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      '_embed': '1',
      if (catId != null) 'categories': catId,
    };

    final res = await _dio.get(ApiConstant.wp('posts'), queryParameters: qp);
    final List data = (res.data is List) ? res.data : const [];

    return data.map<JournalPost>((p) {
      final id = (p['id'] as num).toInt();
      final title = _stripHtml(p['title']?['rendered'] ?? '');
      final link = (p['link'] ?? '').toString();
      final dateStr = (p['date'] ?? '').toString();
      final dt = DateTime.tryParse(dateStr) ?? DateTime.now();

      String? img;
      final media = p['_embedded']?['wp:featuredmedia'];
      if (media is List && media.isNotEmpty) {
        img = (media[0]['source_url'] as String?)?.trim();
      }

      final excerpt = _stripHtml(p['excerpt']?['rendered'] ?? '');

      return JournalPost(
        id: id,
        title: _un.convert(title),
        link: link,
        imageUrl: img,
        date: dt,
        excerpt: _un.convert(excerpt),
      );
    }).toList();
  }

  /// Single post detail (HTML content in JSON)
  Future<JournalPostDetails> fetchPost(int id) async {
    final res = await _dio.get(
      ApiConstant.wp('posts/$id'),
      queryParameters: {'_embed': '1'},
    );
    final p = res.data as Map<String, dynamic>;

    String? img;
    final media = p['_embedded']?['wp:featuredmedia'];
    if (media is List && media.isNotEmpty) {
      img = (media[0]['source_url'] as String?)?.trim();
    }

    final dateStr = (p['date'] ?? '').toString();
    final dt = DateTime.tryParse(dateStr) ?? DateTime.now();

    return JournalPostDetails(
      id: (p['id'] as num).toInt(),
      title: _un.convert(_stripHtml(p['title']?['rendered'] ?? '')),
      link: (p['link'] ?? '').toString(),
      imageUrl: img,
      date: dt,
      contentHtml: (p['content']?['rendered'] ?? '').toString(),
    );
  }

  String _stripHtml(String s) =>
      s.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
}
