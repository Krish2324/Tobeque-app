import 'package:tobeque/utills/helper_func.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsAndConditionsTobequePage extends StatelessWidget {
  const TermsAndConditionsTobequePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Colors.teal.shade800, fontWeight: FontWeight.bold,
    );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions – Tobeque"),
        backgroundColor: Colors.teal.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome to Tobeque", style: headlineStyle),
            const SizedBox(height: 12),
            Text(
              "An online fashion brand owned and operated by AJ Clothing. By accessing or using our website [www.tobeque.com], you agree to comply with the following Terms & Conditions. Please read them carefully before making any purchase.",
              style: bodyStyle,
            ),
            const SizedBox(height: 22),
            _sectionTitle("1. General Information", context),
            _sectionBody(
              "Company: AJ Clothing, operating under the brand name Tobeque.\n"
              "Jurisdiction: Currently serving customers in India, with future expansion planned.\n"
              "Updates: Terms may be updated; continued use signifies acceptance.",
              bodyStyle,
            ),
            _sectionTitle("2. Use of Website", context),
            _sectionBody(
              "- The website is for personal shopping only.\n"
              "- Misuse (fraud, hacking, unauthorized access) is prohibited.\n"
              "- All content is property of AJ Clothing; reproduction requires permission.",
              bodyStyle,
            ),
            _sectionTitle("3. Product Information", context),
            _sectionBody(
              "- We strive for accuracy in descriptions, sizing, and colors. Minor variations may occur.\n"
              "- Prices are in INR, subject to change without notice.",
              bodyStyle,
            ),
            _sectionTitle("4. Orders & Payments", context),
            _sectionBody(
              "- Orders are accepted via email confirmation only.\n"
              "- Payment accepted via UPI, credit/debit cards, PayPal, and COD (where available).\n"
              "- AJ Clothing may cancel orders in case of payment failure or fraud.",
              bodyStyle,
            ),
            _sectionTitle("5. Shipping & Delivery", context),
            _sectionBody(
              "- Timelines are shown at checkout. Shipping charges, if any, shown before payment.\n"
              "- Tracking details provided post-shipment.\n"
              "See our Shipping Policy for details.",
              bodyStyle,
            ),
            _sectionTitle("6. Returns, Exchanges & Refunds", context),
            _sectionBody(
              "Policies governed by our separate Returns & Refund Policy. Please review before purchase.",
              bodyStyle,
            ),
            _sectionTitle("7. Data Protection & Privacy", context),
            _sectionBody(
              "- Personal details used only for order completion and support.\n"
              "- Data not sold or rented to third parties.\n"
              "- May be shared with service providers solely to fulfill orders.\n"
              "See our Privacy Policy for details.",
              bodyStyle,
            ),
            _sectionTitle("8. Limitation of Liability", context),
            _sectionBody(
              "- Not responsible for courier delays, design/color variations, or unauthorized use of your account.\n"
              "- Liability limited to product value.",
              bodyStyle,
            ),
            _sectionTitle("9. Governing Law", context),
            _sectionBody(
                "These terms are governed by the laws of India. Disputes fall under the exclusive jurisdiction of Indian courts.",
                bodyStyle,
            ),
            _sectionTitle("10. Contact Us", context),
            _sectionBody(
                "For any queries, reach us at: ",
                bodyStyle,
            ),
            GestureDetector(
              onTap: () async {
                final uri = Uri.parse("mailto:support@tobeque.com");
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },

              child: InkWell(
                onTap: () {
                  launchEmail("support@tobeque.com");
                },
                child: Text(
                  "📧 support@tobeque.com",
                  style: TextStyle(
                    color: Colors.teal.shade800,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Colors.teal.shade900, fontWeight: FontWeight.bold,
    )),
  );

  Widget _sectionBody(String text, TextStyle? style) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: style),
  );
}
