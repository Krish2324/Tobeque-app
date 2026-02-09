import 'package:tobeque/utills/helper_func.dart';
import 'package:flutter/material.dart';


class PrivacyPolicyTobequePage extends StatelessWidget {
  const PrivacyPolicyTobequePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sectionTitleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Colors.deepPurple.shade700, fontWeight: FontWeight.bold,
    );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy – Tobeque'),
        backgroundColor: Colors.deepPurple.shade600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section("1. Information We Collect", sectionTitleStyle, bodyStyle, 
              "• Personal details like name, email, phone number, shipping address, and payment information.\n"
              "• Non-personal information such as browsing behavior and device details."),
            _section("2. How We Use Your Information", sectionTitleStyle, bodyStyle,
              "• To process orders and payments.\n"
              "• To provide customer support and respond to inquiries.\n"
              "• To improve website functionality and shopping experience.\n"
              "• To send promotional offers (only if you opt-in)."),
            _section("3. Sharing of Information", sectionTitleStyle, bodyStyle,
              "• We do not sell or rent your personal information.\n"
              "• Data may be shared with trusted third parties (payment gateways, delivery partners) for completing orders."),
            _section("4. Data Security", sectionTitleStyle, bodyStyle,
              "• We use secure encryption and industry-standard practices to protect your information.\n"
              "• However, no online platform can guarantee 100% security."),
            _section("5. Your Rights", sectionTitleStyle, bodyStyle,
              "• You may request correction or deletion of your data by contacting us at "),
            GestureDetector(
              onTap: () async {
               launchEmail("support@tobeque.com");
              },
              child: Text(
                'support@tobeque.com',
                style: TextStyle(
                  color: Colors.deepPurple.shade700,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text("• You may unsubscribe from marketing emails anytime.", style: bodyStyle),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, TextStyle? titleStyle, TextStyle? bodyStyle, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RichText(
        text: TextSpan(
          text: "$title\n",
          style: titleStyle,
          children: [
            TextSpan(
              text: body,
              style: bodyStyle,
            ),
          ],
        ),
      ),
    );
  }
}
