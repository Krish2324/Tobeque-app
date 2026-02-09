import 'dart:ui';
import 'package:tobeque/view/profile/address_screen.dart';
import 'package:tobeque/view/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'checkout_controller.dart';
import 'checkout_binding.dart';

class CheckoutScreen extends GetView<CheckoutController> {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    CheckoutBinding().dependencies();

    return Obx(() {
      if (controller.loading.value) {
        return const Scaffold(
          appBar: _CheckoutAppBar(),
          body: Center(child: CircularProgressIndicator(color: Colors.grey)),
        );
      }
      if (controller.error.value != null) {
  final msg = controller.error.value!;
  final needsLogin = msg.contains('rest_not_logged_in') ||
      msg.contains('"status":401') ||
      msg.toLowerCase().contains('not currently logged in');

  return Scaffold(
    appBar: const _CheckoutAppBar(),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(needsLogin ? Icons.lock_outline : Icons.error_outline,
                size: 48, color: Colors.black54),
            const SizedBox(height: 12),

            // show only the server message
            Text(msg, textAlign: TextAlign.center),

            const SizedBox(height: 16),

            // if login error -> show only "Log in" button
            if (needsLogin)
              ElevatedButton.icon(
                onPressed: () => Get.to(ProfileScreen(
                  
                )),
                icon: const Icon(Icons.login),
                label: const Text('Log in'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
              )
            else
              OutlinedButton(
                onPressed: controller.refreshAll,
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    ),
  );
}

      final totals = controller.totals;
      final subtotal = totals['subtotal']?.toString() ?? totals['subtotal_price']?.toString() ?? '';
      final total = totals['total_price']?.toString() ?? totals['total']?.toString() ?? '';

      return Scaffold(
        appBar: const _CheckoutAppBar(),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: controller.refreshAll,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                children: [
                  _LoginBanner(),
const _SavedAddressesCard(),
                  // Billing details
                  const SizedBox(height: 10),
                  const Text('Billing details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Form(
                    key: controller.formKey,
                    child: _BillingForm(),
                  ),

                  const SizedBox(height: 20),
                  // Shipping (rates + coupon + order summary)
                  _OrderSummaryCard(
                    subtotal: controller.formatPrice(subtotal),
                    total: controller.formatPrice(total),
                  ),

                  const SizedBox(height: 20),
                  _PaymentSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // busy overlay
            Obx(() {
              final show = controller.mutating.value;
              return IgnorePointer(
                ignoring: !show,
                child: AnimatedOpacity(
                  opacity: show ? 1 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: Stack(
                    children: [
                      Positioned.fill(child: Container(color: Colors.black.withOpacity(0.04))),
                      Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: const SizedBox())),
                      const Positioned.fill(child: Center(child: CircularProgressIndicator())),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),

        bottomSheet: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xffeeeeee))),
            color: Colors.white,
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TotalsRow(label: 'Subtotal', value: controller.formatPrice(subtotal)),
                const SizedBox(height: 6),
                _TotalsRow(label: 'Total', value: controller.formatPrice(total), bold: true),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.mutating.value ? null : controller.placeOrder,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Place order', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/* ------------------------------ AppBar ------------------------------ */
class _CheckoutAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CheckoutAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Checkout'),
      centerTitle: true,
      elevation: 0.5,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    );
  }
}

/* ------------------------------ Login banner ------------------------------ */
class _LoginBanner extends GetView<CheckoutController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final me = controller.me.value;
      if (me == null) {
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xfff4f6f8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_outline),
              const SizedBox(width: 8),
              const Expanded(child: Text('Have an account? Log in for faster checkout.', maxLines: 2)),
              TextButton(
                onPressed: () => Get.toNamed('/login'),
                child: const Text('Log in'),
              ),
            ],
          ),
        );
      } else {
        final name = '${me['name'] ?? ''}'.trim();
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xffeefbf3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(child: Text('Logged in as $name', maxLines: 2)),
              const SizedBox(width: 8),
            ],
          ),
        );
      }
    });
  }
}

/* ------------------------------ Billing Form ------------------------------ */
class _BillingForm extends GetView<CheckoutController> {
  const _BillingForm();

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: TextFormField(controller: controller.firstName, decoration: _dec('First name *'), validator: (v)=> (v==null||v.trim().isEmpty)?'Required':null)),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: controller.lastName, decoration: _dec('Last name *'), validator: (v)=> (v==null||v.trim().isEmpty)?'Required':null)),
        ]),
        const SizedBox(height: 10),
        TextFormField(controller: controller.company, decoration: _dec('Company name')),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextFormField(controller: controller.country, decoration: _dec('Country / Region *'), validator: (v)=> (v==null||v.trim().isEmpty)?'Required':null)),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: controller.phone, decoration: _dec('Phone *'), keyboardType: TextInputType.phone, validator: (v)=> (v==null||v.trim().isEmpty)?'Required':null)),
        ]),
        const SizedBox(height: 10),
        TextFormField(controller: controller.address1, decoration: _dec('Street address *'), validator: (v)=> (v==null||v.trim().isEmpty)?'Required':null),
        const SizedBox(height: 10),
        TextFormField(controller: controller.address2, decoration: _dec('Apartment, suite, unit etc. (optional)')),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextFormField(controller: controller.city, decoration: _dec('Town / City *'), validator: (v)=> (v==null||v.trim().isEmpty)?'Required':null)),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: controller.state, decoration: _dec('State'))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextFormField(controller: controller.postcode, decoration: _dec('Postcode / ZIP'))),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: controller.email, decoration: _dec('Email address *'), keyboardType: TextInputType.emailAddress, validator: (v)=> (v==null||!v.contains('@'))?'Enter valid email':null)),
        ]),
      ],
    );
  }
}

/* ------------------------------ Order summary + shipping + coupon ------------------------------ */
class _OrderSummaryCard extends GetView<CheckoutController> {
  const _OrderSummaryCard({required this.subtotal, required this.total});
  final String subtotal;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order summary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 10),

            // items
            ...controller.items.map((item) {
              final name = item['name']?.toString() ?? '';
              final img = controller.lineImage(item);
              final qty = (item['quantity'] as num?)?.toInt() ?? 1;
              final totals = (item['totals'] as Map?)?.cast<String, dynamic>() ?? {};
              final lineTotal = totals['line_total_rendered']?.toString() ?? totals['line_total']?.toString() ?? '';
              final attrs = controller.attrText(item);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        color: const Color(0xfff3f3f3),
                        width: 54, height: 54,
                        child: img.isEmpty ? const SizedBox() : Image.network(img, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                        if (attrs.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text(attrs, style: const TextStyle(color: Colors.black54, fontSize: 12))),
                        Padding(padding: const EdgeInsets.only(top: 2), child: Text('x$qty', style: const TextStyle(fontSize: 12))),
                      ]),
                    ),
                    Text(controller.formatPrice(lineTotal), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              );
            }).toList(),

            const Divider(height: 24),
        

            const SizedBox(height: 12),
            // Shipping selector
            const Text('Shipping', style: TextStyle(fontWeight: FontWeight.w700)),
            Obx(() {
              final rates = controller.shippingRates;
              if (rates.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 8),
                  child: Text('Enter address to calculate shipping.'),
                );
              }
              return Column(
                children: rates.map((r) {
                  final key = '${r['package_id']}|${r['rate_id']}';
                  final label = '${r['name']} ${r['price'] != null && r['price'].toString().isNotEmpty ? ' – ${r['price']}' : ''}';
                  return RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(label),
                    value: key,
                    groupValue: controller.selectedShippingKey.value,
                    onChanged: (v) {
                      if (v != null) {
                        controller.selectedShippingKey.value = v;
                        controller.selectShipping(v);
                      }
                    },
                  );
                }).toList(),
              );
            }),

            const SizedBox(height: 6),
            // Coupon
            Row(children: [
              Expanded(child: TextField(controller: controller.couponCtrl, decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: 'Coupon code'))),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: controller.applyCoupon, child: const Text('Apply')),
            ]),
            Obx(() {
              if (controller.appliedCoupons.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: controller.appliedCoupons.map((c) =>
                    InputChip(label: Text(c), onDeleted: () => controller.removeCoupon(c))
                  ).toList(),
                ),
              );
            }),

            const Divider(height: 24),
            _TotalsRow(label: 'Total', value: total, bold: true),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------ Payment ------------------------------ */
class _PaymentSection extends GetView<CheckoutController> {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white, elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Payment information', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          Obx(() {
            final methods = controller.paymentMethods;
            if (methods.isEmpty) {
              return const Text('No payment methods are available.');
            }
            return Column(
              children: methods.map((m) {
                final id = m['id']?.toString() ?? '';
                final title = m['title']?.toString() ?? id;
                final desc = m['description']?.toString() ?? '';
                return RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(title),
                  subtitle: desc.isEmpty ? null : Text(desc),
                  value: id,
                  groupValue: controller.selectedPaymentId.value,
                  onChanged: (v) => controller.selectedPaymentId.value = v ?? id,
                );
              }).toList(),
            );
          }),
          const SizedBox(height: 10),
          TextField(
            controller: controller.noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), labelText: 'Order notes (optional)'),
          ),
        ]),
      ),
    );
  }
}

/* ------------------------------ Shared ------------------------------ */
class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.label, required this.value, this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w700, fontSize: bold ? 16 : 14);
    return Row(children: [Text(label, style: style), const Spacer(), Text(value, style: style)]);
  }
}
// lib/view/checkout/checkout_screen.dart  (add this widget)
class _SavedAddressesCard extends GetView<CheckoutController> {
  const _SavedAddressesCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bill = controller.savedBilling;
      final ship = controller.savedShipping;

      if (bill.isEmpty && ship.isEmpty) {
        return const SizedBox.shrink(); // nothing to show
      }

      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Saved addresses',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),

              if (bill.isNotEmpty)
                RadioListTile<int>(
                  contentPadding: EdgeInsets.zero,
                  value: 0,
                  groupValue: controller.selectedSaved.value,
                  onChanged: (_) => controller.useSaved(true),
                  title: const Text('Billing'),
                  subtitle: Text(controller.addressPretty(bill)),
                ),

              if (ship.isNotEmpty)
                RadioListTile<int>(
                  contentPadding: EdgeInsets.zero,
                  value: 1,
                  groupValue: controller.selectedSaved.value,
                  onChanged: (_) => controller.useSaved(false),
                  title: const Text('Shipping'),
                  subtitle: Text(controller.addressPretty(ship)),
                ),

              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Get.to(AddressScreen()), // route to AddressScreen
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit addresses'),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
