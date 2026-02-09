import 'package:tobeque/utills/helper_func.dart';
import 'package:flutter/material.dart';


class ReturnsRefundPolicyTobequePage extends StatelessWidget {
  const ReturnsRefundPolicyTobequePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sectionTitleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Colors.deepOrange.shade700, fontWeight: FontWeight.bold,
    );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Returns & Refund Policy – Tobeque'),
        backgroundColor: Colors.deepOrange.shade600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('1. Eligibility', sectionTitleStyle, bodyStyle,
              'Products can be returned or exchanged within 7 days of delivery.\n'
              'Items must be unused, unwashed, and in original condition with tags attached.\n'
              'Certain items (like accessories or sale items) may not be eligible for return.'
            ),
            _section('2. Process', sectionTitleStyle, bodyStyle,
              'To initiate a return/exchange, contact us at '
            ),
            GestureDetector(
              onTap: () async {
               launchEmail("support@tobeque.com");
              },
              child: Text(
                'support@tobeque.com',
                style: TextStyle(
                  color: Colors.deepOrange.shade700,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 16),
              child: Text(
                'Once approved, ship the item back to the provided address.\n'
                'Customers are responsible for return shipping costs, unless the product received is defective or incorrect.',
                style: bodyStyle,
              ),
            ),
            _section('3. Refunds', sectionTitleStyle, bodyStyle,
              'Refunds will be processed to the original payment method within 7–10 business days after inspection.\n'
              'Cash on Delivery (COD) orders will be refunded via bank transfer or store credit.'
            ),
            _section('4. Exchanges', sectionTitleStyle, bodyStyle,
              'Exchanges are subject to product availability.\n'
              'If the desired product is unavailable, a refund or store credit will be provided.'
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, TextStyle? titleStyle, TextStyle? bodyStyle, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: 6),
          Text(body, style: bodyStyle),
        ],
      ),
    );
  }
}
