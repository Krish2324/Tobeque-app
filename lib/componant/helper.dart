// somewhere global (e.g., a utils file)
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

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

  // hex: #RRGGBB or RRGGBB
  final hex = RegExp(r'^#?([0-9a-f]{6})$');
  final m = hex.firstMatch(v);
  if (m != null) {
    final n = int.parse(m.group(1)!, radix: 16);
    return Color(0xFF000000 | n);
  }

  // common names
  const names = {
    'black': 0xFF000000, 'white': 0xFFFFFFFF, 'red': 0xFFF44336,
    'blue':  0xFF2196F3, 'green': 0xFF4CAF50, 'yellow': 0xFFFFEB3B,
    'orange':0xFFFF9800, 'purple':0xFF9C27B0, 'pink': 0xFFE91E63,
    'brown': 0xFF795548, 'grey': 0xFF9E9E9E, 'gray': 0xFF9E9E9E,
    'beige': 0xFFF5F5DC, 'navy': 0xFF001F3F,  'maroon':0xFF800000,
    'teal':  0xFF008080, 'olive':0xFF808000,  'gold': 0xFFFFD700,
    'silver':0xFFC0C0C0, 'cream':0xFFFFFDD0,  'multi':0xFF9E9E9E,
  };
  for (final entry in names.entries) {
    if (v.contains(entry.key)) return Color(entry.value);
  }
  return null;
}
