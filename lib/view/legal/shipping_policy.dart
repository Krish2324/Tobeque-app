import 'package:flutter/material.dart';

class ShippingPolicyTobequePage extends StatelessWidget {
  const ShippingPolicyTobequePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sectionTitleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Colors.teal.shade700, fontWeight: FontWeight.bold,
    );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipping Policy – Tobeque'),
        backgroundColor: Colors.teal.shade600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('1. Delivery Locations', sectionTitleStyle, bodyStyle,
                'Currently, we deliver across India.\nInternational shipping will be introduced soon, starting with Dubai.'),
            _section('2. Shipping Time', sectionTitleStyle, bodyStyle,
                'Orders are usually processed within 1–2 business days.\nDelivery time varies between 3–7 business days depending on the location.'),
            _section('3. Shipping Charges', sectionTitleStyle, bodyStyle,
                'Shipping charges, if any, will be displayed at checkout.\nFree shipping may be offered during special promotions.'),
            _section('4. Tracking Orders', sectionTitleStyle, bodyStyle,
                'Customers will receive tracking details once the order is shipped.\nIn case of delivery delays, our support team can assist.'),
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
