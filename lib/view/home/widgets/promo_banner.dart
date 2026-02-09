import 'package:flutter/material.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({
    super.key,
    required this.assetPath,
    required this.title,
    this.onTap,
  });

  final String assetPath;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        // Tall hero like the screenshot (width / height)
        aspectRatio: 0.8,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.asset(assetPath, fit: BoxFit.cover),

            // Subtle bottom gradient for text readability
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Color(0xAA000000), Color(0x00000000)],
                  stops: [0.0, 0.6],
                ),
              ),
            ),

            // Text + CTA (bottom-right)
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 22, 12 + safeBottom),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Big headline
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        height: 1.02,
                        fontWeight: FontWeight.bold,
                        letterSpacing: .6,
                        shadows: [
                          Shadow(blurRadius: 6, color: Colors.black54, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Pill "Shop" button
                    ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: const StadiumBorder(),
                        elevation: 1.5,
                      ),
                      child: const Text(
                        'Shop',
                        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
