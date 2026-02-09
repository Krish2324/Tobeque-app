import 'package:flutter/material.dart';

class SustainabilityAtTobequePage extends StatelessWidget {
  const SustainabilityAtTobequePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sustainability at Tobeque'),
        backgroundColor: Colors.green.shade700,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Fashion with a Purpose',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'At Tobeque, fashion isn’t just about looking good – it’s about feeling good knowing that your choices support a better tomorrow. '
            'We believe that style and sustainability go hand in hand, and we’re committed to creating fashion that is not only premium and trend-forward, '
            'but also responsible and conscious.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 28),
          Text(
            'Our Commitment to Sustainability',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
          ),
          const SizedBox(height: 12),
          _buildCommitmentRow('✨ Thoughtful Design', 'Every Tobeque piece is designed to be timeless, so our customers can enjoy them season after season, reducing wasteful consumption.'),
          _buildCommitmentRow('✨ Quality Fabrics', 'We prioritize durable, high-quality fabrics that last longer and encourage mindful shopping over fast fashion.'),
          _buildCommitmentRow('✨ Eco-Friendly Packaging', 'We are moving towards using recyclable and reusable packaging materials, reducing plastic usage wherever possible.'),
          _buildCommitmentRow('✨ Responsible Production', 'Our production partners follow ethical workplace practices, ensuring fair wages and safe working environments.'),
          const SizedBox(height: 28),
          Text(
            'Why It Matters',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'The fashion industry has a huge impact on the planet, and as a brand for the next generation, we feel responsible for making a difference. '
            'Teenage girls today care deeply about the environment, and we want to empower them to make fashion choices that align with their values.\n\n'
            'When you wear Tobeque, you’re not only embracing style but also supporting sustainable fashion practices that respect both people and the planet.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 28),
          Text(
            'Our Future Goals',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
          ),
          const SizedBox(height: 12),
          _buildGoal('Expanding the use of organic and natural fabrics in our collections.'),
          _buildGoal('Introducing eco-conscious seasonal collections.'),
          _buildGoal('Reducing our overall carbon footprint in packaging and logistics.'),
          _buildGoal('Partnering with organizations that promote environmental awareness and ethical fashion.'),
          const SizedBox(height: 28),
          Text(
            'At Tobeque, we want every purchase to feel meaningful. By choosing Tobeque, you become part of a growing movement – one where style, confidence, and sustainability coexist. '
            'Together, we can inspire positive change and create a brighter, more stylish, and more sustainable world.\n\nBecause real fashion is future-friendly. 🌱',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.green.shade800,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommitmentRow(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.green.shade600)),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: title + ' ',
                style: TextStyle(
                  color: Colors.green.shade900,
                  fontWeight: FontWeight.bold,
                ),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoal(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
