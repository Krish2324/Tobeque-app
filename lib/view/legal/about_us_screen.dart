import 'package:flutter/material.dart';

class AboutUsTobequePage extends StatelessWidget {
  const AboutUsTobequePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: Colors.pink.shade800, fontWeight: FontWeight.bold,
    );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;

    return Scaffold(
      appBar: AppBar(
        title: const Text("About Us – Tobeque"),
        backgroundColor: Colors.pink.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome to Tobeque", style: headlineStyle),
            const SizedBox(height: 12),
            Text(
              "Where fashion meets individuality.\n\nAt Tobeque, we believe that clothing is more than just fabric – it is a form of self-expression. Designed exclusively for teenage girls who dream big, stand tall, and live confidently, our collections bring together the perfect balance of style, comfort, and quality.",
              style: bodyStyle,
            ),
            const SizedBox(height: 28),
            Text("Our Story", style: headlineStyle),
            const SizedBox(height: 10),
            Text(
              "Tobeque is a proud creation of AJ Clothing, a registered fashion house based in India. Born with the vision to offer premium-quality apparel for modern teenage girls, the brand reflects a spirit of confidence and uniqueness. "
              "We saw that young girls often had to choose between trendy fast fashion and expensive designer wear – and that’s where Tobeque steps in. We bring you fashion-forward designs crafted with attention to detail, using quality fabrics, at prices that feel just right.",
              style: bodyStyle,
            ),
            const SizedBox(height: 28),
            Text("What We Stand For", style: headlineStyle),
            const SizedBox(height: 12),
            _buildValue("✨ Premium Quality", "Every piece is designed with carefully selected fabrics and modern tailoring to ensure lasting wear."),
            _buildValue("✨ Trend-Forward Designs", "Inspired by global fashion trends but styled for today’s Indian teenage girls."),
            _buildValue("✨ Comfort Meets Style", "Fashion that feels as good as it looks."),
            _buildValue("✨ Empowerment", "We design not just clothes, but confidence – helping young girls express their personality through fashion."),
            const SizedBox(height: 28),
            Text("Our Collections", style: headlineStyle),
            const SizedBox(height: 12),
            _buildCollection("Trendy Tops, Shirts & Kurtas"),
            _buildCollection("Stylish Dresses & Overlays"),
            _buildCollection("Comfortable Bottoms"),
            _buildCollection("Limited-Edition Seasonal Collections"),
            _buildCollection("Accessories to complete your look"),
            const SizedBox(height: 10),
            Text(
              "Each collection is carefully curated to keep our customers ahead of trends while maintaining timeless elegance.",
              style: bodyStyle,
            ),
            const SizedBox(height: 28),
            Text("Looking Ahead", style: headlineStyle),
            const SizedBox(height: 12),
            Text(
              "Currently, Tobeque serves customers across India through our online store, with plans to expand to Dubai and other global markets soon. Our journey is just beginning, and we’re committed to making Tobeque a name synonymous with teenage premium fashion worldwide.",
              style: bodyStyle,
            ),
            const SizedBox(height: 28),
            Text("Join the Tobeque Tribe", style: headlineStyle),
            const SizedBox(height: 12),
            Text(
              "Tobeque is more than a clothing brand – it’s a community of dreamers, achievers, and go-getters. Whether it’s a casual day at college, a festive celebration, or a special evening out, Tobeque ensures you look stylish, feel confident, and own your moment.\n\nBecause at Tobeque, your style tells your story.",
              style: bodyStyle?.copyWith(fontStyle: FontStyle.italic, color: Colors.pink.shade800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValue(String title, String desc) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("• ", style: TextStyle(color: Colors.pink.shade600)),
        Expanded(
            child: RichText(
              text: TextSpan(
                text: title + " ",
                style: TextStyle(color: Colors.pink.shade900, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: desc,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
          )),
      ],
    ),
  );

  Widget _buildCollection(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        const Text("👗", style: TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
