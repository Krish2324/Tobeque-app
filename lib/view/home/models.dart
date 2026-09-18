// lib/view/home/models.dart
import 'package:tobeque/utills/html_decode.dart';

class WpPageHero {
  final String? imageUrl;
  List<String> mobileBanners;
  WpPageHero({this.imageUrl, this.mobileBanners = const []});

  Map<String, dynamic> toJson() => {
        'imageUrl': imageUrl,
        'mobileBanners': mobileBanners,
      };

  factory WpPageHero.fromJson(Map<String, dynamic> json) => WpPageHero(
        imageUrl: json['imageUrl'],
        mobileBanners: List<String>.from(json['mobileBanners'] ?? []),
      );
}

class WcCategory {
  final String id;   // MongoDB _id string
  final String name;
  late final String? image;
  WcCategory({required this.id, required this.name, this.image});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
      };

  factory WcCategory.fromJson(Map<String, dynamic> json) => WcCategory(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        image: json['image'],
      );
}

class WcProduct {
  final String id;           // MongoDB _id string
  final String name;
  final String? priceHtml;
  final String? image;
  final List<String> images;
  final String? originalPrice;  // non-null when on sale
  final String? hotMedia;       // hotRightNowMedia URL (video or image)
  final String? categorySlug;   // for routing
  final String? slug;           // product slug for routing

  WcProduct({
    required this.id,
    required this.name,
    this.priceHtml,
    this.image,
    this.images = const [],
    this.originalPrice,
    this.hotMedia,
    this.categorySlug,
    this.slug,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'priceHtml': priceHtml,
        'image': image,
        'images': images,
        'originalPrice': originalPrice,
        'hotMedia': hotMedia,
        'categorySlug': categorySlug,
        'slug': slug,
      };

  factory WcProduct.fromJson(Map<String, dynamic> json) {
    final imgs = List<String>.from(json['images'] ?? []);
    final primary = imgs.isNotEmpty ? imgs.first : json['image'];
    return WcProduct(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      priceHtml: json['priceHtml'],
      image: primary,
      images: imgs,
      originalPrice: json['originalPrice'],
      hotMedia: json['hotMedia'],
      categorySlug: json['categorySlug'],
      slug: json['slug'],
    );
  }

  String get displayName => HtmlDecode.text(name);

  /// Returns true if this product has a valid sale (salePrice < regularPrice)
  bool get isOnSale {
    if (originalPrice == null || originalPrice!.isEmpty) return false;
    final sale = _parsePrice(priceHtml);
    final orig = _parsePrice(originalPrice);
    return orig > 0 && sale < orig;
  }

  int get savePercent {
    if (!isOnSale) return 0;
    final sale = _parsePrice(priceHtml);
    final orig = _parsePrice(originalPrice);
    return ((1 - sale / orig) * 100).round();
  }

  static double _parsePrice(String? raw) {
    if (raw == null || raw.isEmpty) return 0;
    return double.tryParse(raw.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
  }
}

// lib/view/home/models.dart
class HeroMedia {
  final String? videoUrl;
  final String? posterUrl;
  HeroMedia({this.videoUrl, this.posterUrl});
}
