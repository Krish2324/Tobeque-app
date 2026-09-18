// somewhere global (e.g., a utils file)
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tobeque/constants/api_constants.dart';

Future<void> openNativeAppSettings(BuildContext context) async {
  final ok = await openAppSettings();
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open Settings')),
    );
  }
}


Color? guessColor(String s) {
  final v = s.toLowerCase().trim();
  if (v.isEmpty) return null;

  // 1. Hex parsing: 0x..., #RGB, #RRGGBB, #AARRGGBB
  if (v.startsWith('0x')) {
    final hexVal = int.tryParse(v);
    if (hexVal != null) return Color(hexVal);
  }
  
  final hexClean = v.replaceAll('#', '').trim();
  if (RegExp(r'^[0-9a-fA-F]{3}$').hasMatch(hexClean)) {
    final r = hexClean[0];
    final g = hexClean[1];
    final b = hexClean[2];
    final fullHex = int.parse('$r$r$g$g$b$b', radix: 16);
    return Color(0xFF000000 | fullHex);
  } else if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hexClean)) {
    final fullHex = int.parse(hexClean, radix: 16);
    return Color(0xFF000000 | fullHex);
  } else if (RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(hexClean)) {
    final fullHex = int.parse(hexClean, radix: 16);
    return Color(fullHex);
  }

  // 2. Comprehensive Fashion & Apparel Colors Map
  const names = <String, int>{
    'black': 0xFF000000,
    'white': 0xFFFFFFFF,
    'off white': 0xFFFAFAFA,
    'off-white': 0xFFFAFAFA,
    'ivory': 0xFFFFFFF0,
    'cream': 0xFFF6F4E8,
    'beige': 0xFFF5F5DC,
    'nude': 0xFFE3C6B4,
    'tan': 0xD2B48C,
    'khaki': 0xFFC3B091,
    'camel': 0xFFC19A6B,
    'brown': 0xFF5C4033,
    'red': 0xFFEF4444,
    'crimson': 0xFFDC143C,
    'maroon': 0xFF800020,
    'burgundy': 0xFF800020,
    'wine': 0xFF722F37,
    'rust': 0xFFB7410E,
    'blue': 0xFF3B82F6,
    'navy': 0xFF1D3557,
    'sky': 0xFF87CEEB,
    'sky blue': 0xFF87CEEB,
    'royal blue': 0xFF4169E1,
    'denim': 0xFF1560BD,
    'teal': 0xFF14B8A6,
    'cyan': 0xFF06B6D4,
    'turquoise': 0xFF40E0D0,
    'green': 0xFF10B981,
    'olive': 0xFF556B2F,
    'sage': 0xFF9CAF88,
    'sage green': 0xFF9CAF88,
    'mint': 0xFF98FF98,
    'forest green': 0xFF228B22,
    'yellow': 0xFFFBBF24,
    'mustard': 0xFFE1AD01,
    'amber': 0xFFFFBF00,
    'gold': 0xFFD97706,
    'orange': 0xFFF97316,
    'coral': 0xFFFF7F50,
    'peach': 0xFFFFDAB9,
    'pink': 0xFFEC4899,
    'dusty rose': 0xFFDCAE96,
    'rose': 0xFFFF007F,
    'magenta': 0xFFFF00FF,
    'fuchsia': 0xFFFF00FF,
    'purple': 0xFFA855F7,
    'lavender': 0xFFE6E6FA,
    'plum': 0xFF8E4585,
    'violet': 0xFF8F00FF,
    'indigo': 0xFF4B0082,
    'grey': 0xFF9CA3AF,
    'gray': 0xFF9CA3AF,
    'charcoal': 0xFF36454F,
    'silver': 0xFFC0C0C0,
    'multi': 0xFF6366F1,
    'multicolor': 0xFF6366F1,
  };

  for (final entry in names.entries) {
    if (v.contains(entry.key)) return Color(entry.value);
  }

  // Consistent muted earth tone fallback instead of bright random HSL
  final int hash = v.hashCode.abs();
  final double hue = (hash % 360).toDouble();
  return HSLColor.fromAHSL(1.0, hue, 0.25, 0.45).toColor();
}

class ColorSwatchData {
  final String name;
  final String? image;
  final Color color;

  const ColorSwatchData({required this.name, this.image, required this.color});
}

List<ColorSwatchData> extractColorsFromProductMap(Map<String, dynamic> p) {
  final List<ColorSwatchData> result = [];
  final Map<String, ColorSwatchData> mapBySlug = {};

  void addOrUpdateSwatch(String nameStr, [String? rawImg, String? hexColor]) {
    final cleanName = nameStr.trim();
    if (cleanName.isEmpty) return;
    final slug = cleanName.toLowerCase();

    String? fullImg;
    if (rawImg != null && rawImg.trim().isNotEmpty) {
      fullImg = ApiConstant.getImageUrl(rawImg.trim());
    }

    Color colorVal = Colors.transparent;
    if (hexColor != null && hexColor.trim().isNotEmpty) {
      colorVal = guessColor(hexColor) ?? guessColor(cleanName) ?? const Color(0xFF9CA3AF);
    } else {
      colorVal = guessColor(cleanName) ?? const Color(0xFF9CA3AF);
    }

    if (mapBySlug.containsKey(slug)) {
      final existing = mapBySlug[slug]!;
      if ((existing.image == null || existing.image!.isEmpty) && fullImg != null && fullImg.isNotEmpty) {
        final updated = ColorSwatchData(name: existing.name, image: fullImg, color: existing.color);
        mapBySlug[slug] = updated;
        final idx = result.indexWhere((e) => e.name.trim().toLowerCase() == slug);
        if (idx != -1) result[idx] = updated;
      }
      return;
    }

    final swatch = ColorSwatchData(name: cleanName, image: fullImg, color: colorVal);
    mapBySlug[slug] = swatch;
    result.add(swatch);
  }

  // 1. Check colorSwatches / swatches FIRST (stores admin custom fabric/color images)
  final swatches = (p['colorSwatches'] as List?) ?? (p['swatches'] as List?) ?? const [];
  for (final s in swatches) {
    if (s is Map) {
      final name = (s['color'] ?? s['name'] ?? s['label'] ?? s['title'])?.toString();
      final img = (s['image'] ?? s['imageUrl'] ?? s['photo'] ?? s['swatch'] ?? s['src'] ?? s['icon'])?.toString();
      final hex = (s['hex'] ?? s['code'] ?? s['colorCode'] ?? s['value'])?.toString();
      if (name != null) addOrUpdateSwatch(name, img, hex);
    }
  }

  // 2. Direct colors list (strings or maps)
  final cols = (p['colors'] as List?) ?? const [];
  for (final c in cols) {
    if (c is Map) {
      final name = (c['name'] ?? c['color'] ?? c['label'] ?? c['title'])?.toString();
      final img = (c['image'] ?? c['imageUrl'] ?? c['photo'] ?? c['swatch'] ?? c['src'] ?? c['icon'])?.toString();
      final hex = (c['hex'] ?? c['code'] ?? c['colorCode'] ?? c['value'])?.toString();
      if (name != null) addOrUpdateSwatch(name, img, hex);
    } else if (c != null) {
      addOrUpdateSwatch(c.toString());
    }
  }

  // 3. Single color field
  if (p['color'] is String && (p['color'] as String).trim().isNotEmpty) {
    for (final splitted in (p['color'] as String).split(',')) {
      addOrUpdateSwatch(splitted);
    }
  }

  // 4. Images list with color tags
  final imgs = (p['images'] as List?) ?? const [];
  for (final item in imgs) {
    if (item is Map && item['color'] != null) {
      final c = item['color'].toString().trim();
      final img = (item['imageUrl'] ?? item['url'] ?? item['src'] ?? item['image'])?.toString();
      addOrUpdateSwatch(c, img);
    }
  }

  // 5. Attributes
  final attrs = (p['attributes'] as List?) ?? const [];
  for (final a in attrs.whereType<Map>()) {
    final key = ((a['taxonomy'] ?? a['name'])?.toString() ?? '').toLowerCase();
    if (key.contains('color') || key == 'pa_color' || key.contains('colour')) {
      final terms = a['terms'] ?? a['options'] ?? a['options_json'] ?? a['value'];
      if (terms is List) {
        for (final t in terms) {
          if (t is Map) {
            final val = (t['name'] ?? t['value'] ?? t['label'] ?? '').toString();
            final img = (t['image'] ?? t['imageUrl'] ?? t['photo'] ?? t['swatch'] ?? t['src'] ?? t['icon'])?.toString();
            final hex = (t['hex'] ?? t['code'] ?? t['colorCode'] ?? t['value'] ?? t['color'])?.toString();
            addOrUpdateSwatch(val, img, hex);
          } else if (t != null) {
            addOrUpdateSwatch(t.toString());
          }
        }
      } else if (terms is String && terms.trim().isNotEmpty) {
        for (final s in terms.split(',')) {
          addOrUpdateSwatch(s);
        }
      }
    }
  }

  // 6. Variants
  final vars = (p['variants'] as List?) ?? (p['variations'] as List?) ?? const [];
  for (final v in vars.whereType<Map>()) {
    final c = (v['color'] ?? v['attributes']?['color'] ?? v['attributes']?['pa_color'])?.toString();
    final img = (v['image'] ?? v['imageUrl'] ?? v['thumbnail'])?.toString();
    final hex = (v['colorCode'] ?? v['hex'])?.toString();
    if (c != null) addOrUpdateSwatch(c, img, hex);
  }

  // 7. Title fallback
  if (result.isEmpty) {
    final name = (p['name'] ?? p['title'] ?? '').toString();
    final g = guessColor(name);
    if (g != null) {
      addOrUpdateSwatch(name);
    }
  }

  return result;
}
