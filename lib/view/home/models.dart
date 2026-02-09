// lib/view/home/models.dart
import 'package:tobeque/utills/html_decode.dart';

class WpPageHero {
  final String? imageUrl;
  WpPageHero({this.imageUrl});
}

class WcCategory {
  final int id;
  final String name;
  late final String? image;
  WcCategory({required this.id, required this.name, this.image});
}

class WcProduct {
  final int id;
  final String name;        // keep original
  final String? priceHtml;
  final String? image;

  WcProduct({required this.id, required this.name, this.priceHtml, this.image});

  String get displayName => HtmlDecode.text(name);
}

// lib/view/home/models.dart
class HeroMedia {
  final String? videoUrl;
  final String? posterUrl;
  HeroMedia({this.videoUrl, this.posterUrl});
}
