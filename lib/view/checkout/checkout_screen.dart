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
          backgroundColor: Colors.white,
          appBar: _CheckoutAppBar(),
          body: Center(child: CircularProgressIndicator(color: Colors.black)),
        );
      }
      if (controller.error.value != null) {
        final msg = controller.error.value!;
        final needsLogin = msg.contains('rest_not_logged_in') ||
            msg.contains('"status":401') ||
            msg.toLowerCase().contains('not currently logged in');

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: const _CheckoutAppBar(),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(needsLogin ? Icons.lock_outline : Icons.error_outline, size: 48, color: Colors.black54),
                  const SizedBox(height: 12),
                  Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 16),
                  if (needsLogin)
                    ElevatedButton.icon(
                      onPressed: () => Get.to(() => const ProfileScreen()),
                      icon: const Icon(Icons.login),
                      label: const Text('Log in'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
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

      return Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: const _CheckoutAppBar(),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: controller.refreshAll,
              color: Colors.black,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // Step Indicator Header
                  const _StepHeader(),
                  const SizedBox(height: 14),

                  // Login status banner
                  const _LoginBanner(),

                  // Saved addresses shortcut
                  const _SavedAddressesCard(),

                  // 1. Delivery & Billing Form Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 20, color: Colors.black),
                            SizedBox(width: 8),
                            Text('1. Delivery Address', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Enter your shipping details below', style: TextStyle(fontSize: 11.5, color: Colors.black54)),
                        const SizedBox(height: 16),
                        Form(
                          key: controller.formKey,
                          child: const _BillingForm(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  // 2. Order Summary Card
                  const _OrderSummaryCard(),

                  const SizedBox(height: 16),
                  // 3. Payment Method Card
                  const _PaymentSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Busy loading overlay
            Obx(() {
              final show = controller.mutating.value;
              return IgnorePointer(
                ignoring: !show,
                child: AnimatedOpacity(
                  opacity: show ? 1 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: Stack(
                    children: [
                      Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.06))),
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: const SizedBox(),
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: const BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.all(Radius.circular(10))),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                SizedBox(width: 12),
                                Text('Processing Order…', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),

        // Sticky Bottom Checkout Action Bar (Using bottomNavigationBar + SafeArea so Android system nav bar never overlaps)
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
            ],
          ),
          child: SafeArea(
            top: false,
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL AMOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Colors.black54)),
                      const SizedBox(height: 2),
                      Obx(() {
                        final totalsMap = controller.totals;
                        final grandTotal = totalsMap['total'] ?? totalsMap['total_price'] ?? 0.0;
                        return Text(
                          controller.formatPrice(grandTotal),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: Colors.black),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: Obx(() {
                        final busy = controller.mutating.value;
                        return ElevatedButton(
                          onPressed: busy ? null : controller.placeOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: busy
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_outline, size: 16),
                                  SizedBox(width: 8),
                                  Text('PLACE ORDER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1)),
                                ],
                              ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

/* ------------------------------ Step Header ------------------------------ */
class _StepHeader extends StatelessWidget {
  const _StepHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 16),
              SizedBox(width: 6),
              Text('1. Bag', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
            ],
          ),
          Icon(Icons.chevron_right, size: 16, color: Colors.black26),
          Row(
            children: [
              CircleAvatar(radius: 8, backgroundColor: Colors.black, child: Text('2', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
              SizedBox(width: 6),
              Text('2. Shipping', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black)),
            ],
          ),
          Icon(Icons.chevron_right, size: 16, color: Colors.black26),
          Row(
            children: [
              CircleAvatar(radius: 8, backgroundColor: Color(0xFFE0E0E0), child: Text('3', style: TextStyle(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.bold))),
              SizedBox(width: 6),
              Text('3. Payment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black45)),
            ],
          ),
        ],
      ),
    );
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
      title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black)),
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF2E7D32), size: 14),
                SizedBox(width: 4),
                Text('100% SECURE', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 9.5, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/* ------------------------------ Login banner ------------------------------ */
class _LoginBanner extends GetView<CheckoutController> {
  const _LoginBanner();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final me = controller.me.value;
      if (me == null) {
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_outline, color: Colors.black87),
              const SizedBox(width: 8),
              const Expanded(child: Text('Have an account? Log in for express checkout.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
              TextButton(
                onPressed: () => Get.to(() => const ProfileScreen()),
                child: const Text('Log in', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
              ),
            ],
          ),
        );
      } else {
        final name = '${me['firstName'] ?? me['name'] ?? 'Customer'}'.trim();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user, color: Color(0xFF2E7D32), size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Logged in as $name', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1B5E20)))),
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

  InputDecoration _dec(
    String label, {
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        errorStyle: const TextStyle(
          color: Color(0xFFEF4444),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name Row
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: controller.firstName,
              decoration: _dec(
                'First name *',
                prefixIcon: const Icon(Icons.person_outline, size: 18, color: Color(0xFF6B7280)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller.lastName,
              decoration: _dec(
                'Last name *',
                prefixIcon: const Icon(Icons.person_outline, size: 18, color: Color(0xFF6B7280)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Contact Row
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: controller.phone,
              decoration: _dec(
                'Phone *',
                hint: '10-digit number',
                prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF6B7280)),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller.email,
              decoration: _dec(
                'Email address (Optional)',
                prefixIcon: const Icon(Icons.email_outlined, size: 18, color: Color(0xFF6B7280)),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (!v.trim().contains('@')) return 'Valid email required';
                return null;
              },
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // PINCODE field with auto-lookup & Area modal trigger
        Obx(() {
          final isFetching = controller.fetchingPincode.value;
          final valid = controller.pincodeValid.value;
          final msg = controller.pincodeStatusMsg.value;
          final areas = controller.availableAreas;
          final selectedArea = controller.selectedArea.value;

          Widget? suffix;
          if (isFetching) {
            suffix = const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              ),
            );
          } else if (valid == true) {
            suffix = const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20);
          } else if (valid == false) {
            suffix = const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: controller.postcode,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: _dec(
                  'Pincode / ZIP *',
                  hint: '6-digit PIN code',
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF6B7280)),
                  suffixIcon: suffix,
                ).copyWith(counterText: ''),
                onChanged: (v) {
                  if (v.trim().length == 6) {
                    controller.lookupPincode(v.trim());
                  }
                },
                validator: (v) => (v == null || v.trim().length != 6) ? 'Enter valid 6-digit Pincode' : null,
              ),
              if (valid == true && areas.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.place, size: 16, color: Color(0xFF15803D)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          selectedArea != null
                              ? 'Area: ${selectedArea['Name']} (${selectedArea['District']})'
                              : (msg ?? 'Area details fetched'),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: controller.openAreaSelectionModal,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Select Area',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                              ),
                              Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFF15803D)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (msg != null && msg.isNotEmpty) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    children: [
                      Icon(
                        valid == false ? Icons.info_outline : Icons.location_on,
                        size: 14,
                        color: valid == false ? const Color(0xFFEF4444) : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        msg,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: valid == false ? const Color(0xFFEF4444) : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        }),
        const SizedBox(height: 12),

        // Company Name (Optional)
        TextFormField(
          controller: controller.company,
          onChanged: (val) {
            controller.hasCompany.value = val.trim().isNotEmpty;
          },
          decoration: _dec(
            'Company Name (Optional)',
            hint: 'Enter company name if applicable',
            prefixIcon: const Icon(Icons.business_outlined, size: 18, color: Color(0xFF6B7280)),
          ),
        ),
        const SizedBox(height: 12),

        // Dynamic Company GST Number (Mandatory when Company Name is provided)
        Obx(() {
          if (!controller.hasCompany.value) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: controller.gstNumber,
              textCapitalization: TextCapitalization.characters,
              decoration: _dec(
                'Company GST Number *',
                hint: 'e.g. 22AAAAA0000A1Z5',
                prefixIcon: const Icon(Icons.receipt_long_outlined, size: 18, color: Color(0xFF6B7280)),
              ),
              validator: (v) {
                if (controller.hasCompany.value && (v == null || v.trim().isEmpty)) {
                  return 'GST Number is required when Company Name is entered';
                }
                return null;
              },
            ),
          );
        }),

        // Address Line 1 (Building, Street)
        TextFormField(
          controller: controller.address1,
          decoration: _dec(
            'Flat, House no., Building, Street *',
            prefixIcon: const Icon(Icons.home_outlined, size: 18, color: Color(0xFF6B7280)),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),

        // Address Line 2 (Locality, Area)
        TextFormField(
          controller: controller.address2,
          decoration: _dec(
            'Area, Colony, Landmark (Optional)',
            prefixIcon: const Icon(Icons.near_me_outlined, size: 18, color: Color(0xFF6B7280)),
          ),
        ),
        const SizedBox(height: 12),

        // Town / City & State Row (Auto-filled by Pincode)
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: controller.city,
              decoration: _dec(
                'Town / City *',
                prefixIcon: const Icon(Icons.location_city_outlined, size: 18, color: Color(0xFF6B7280)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller.state,
              decoration: _dec(
                'State *',
                prefixIcon: const Icon(Icons.map_outlined, size: 18, color: Color(0xFF6B7280)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Country
        TextFormField(
          controller: controller.country,
          decoration: _dec(
            'Country / Region *',
            prefixIcon: const Icon(Icons.public_outlined, size: 18, color: Color(0xFF6B7280)),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }
}

/* ------------------------------ Order summary ------------------------------ */
class _OrderSummaryCard extends GetView<CheckoutController> {
  const _OrderSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('2. Order Summary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.2)),
              Obx(() => Text('${controller.items.length} ${controller.items.length == 1 ? 'Item' : 'Items'}', style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),

          // items list
          Obx(() => Column(
            children: controller.items.map((item) {
              final name = item['name']?.toString() ?? '';
              final img = controller.lineImage(item);
              final qty = (item['quantity'] as num?)?.toInt() ?? 1;
              final totalsMap = (item['totals'] as Map?)?.cast<String, dynamic>() ?? {};
              final lineTotal = totalsMap['line_total_rendered']?.toString() ?? totalsMap['line_total']?.toString() ?? '';
              final attrs = controller.attrText(item);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        color: const Color(0xFFF5F5F5),
                        width: 58, height: 68,
                        child: img.isEmpty
                            ? const Icon(Icons.image_not_supported_outlined, color: Colors.black26, size: 24)
                            : Image.network(img, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, height: 1.25)),
                          if (attrs.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(attrs, style: const TextStyle(color: Colors.black54, fontSize: 11.5)),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(4)),
                                child: Text('Qty: $qty', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(controller.formatPrice(lineTotal), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ],
                ),
              );
            }).toList(),
          )),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 14),

          // Coupon section
          const Text('Promotional Coupon', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5, color: Colors.black54)),
          const SizedBox(height: 8),
          Obx(() {
            final busy = controller.couponLoading.value;
            final hasCoupon = controller.appliedCoupons.isNotEmpty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: const Icon(Icons.confirmation_number_outlined, color: Colors.black87, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: controller.couponCtrl,
                        textCapitalization: TextCapitalization.characters,
                        enabled: !busy && !hasCoupon,
                        onChanged: (_) {
                          // Clear inline error as user types
                          if (controller.couponError.value != null) {
                            controller.couponError.value = null;
                          }
                        },
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: hasCoupon ? const Color(0xFFF0FDF4) : const Color(0xFFFAFAFA),
                          hintText: hasCoupon ? 'Coupon applied ✓' : 'Enter coupon code',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: hasCoupon ? const Color(0xFF15803D) : const Color(0xFF9CA3AF),
                            fontWeight: hasCoupon ? FontWeight.w700 : FontWeight.w400,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: hasCoupon ? const Color(0xFFBBF7D0) : const Color(0xFFE0E0E0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: hasCoupon ? const Color(0xFFBBF7D0) : const Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.black),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: (busy || hasCoupon) ? null : controller.applyCoupon,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFD1D5DB),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: busy
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('APPLY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),

                // Inline error banner
                if (controller.couponError.value != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            controller.couponError.value!,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Inline success banner + applied chips
                if (hasCoupon) ...[
                  const SizedBox(height: 8),
                  // Success banner with savings
                  if (controller.couponSuccess.value != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 15),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              controller.couponSuccess.value!,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  // Applied coupon chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: controller.appliedCoupons.map((c) =>
                      Chip(
                        avatar: const Icon(Icons.local_offer, color: Color(0xFF2E7D32), size: 14),
                        label: Text(c, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
                        backgroundColor: const Color(0xFFE8F5E9),
                        side: const BorderSide(color: Color(0xFFC8E6C9)),
                        deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF2E7D32)),
                        onDeleted: () => controller.removeCoupon(c),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                      )
                    ).toList(),
                  ),
                ],
              ],
            );
          }),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 14),

          // Dynamic Pricing Breakdown Table
          Obx(() {
            final disc = controller.discountAmount.value;
            final cod = controller.codFee.value;
            final isCod = controller.selectedPaymentId.value == 'cod';
            final totalsMap = controller.totals;
            final subtotalVal = totalsMap['subtotal'] ?? totalsMap['subtotal_price'] ?? 0.0;
            final totalVal = totalsMap['total'] ?? totalsMap['total_price'] ?? 0.0;

            final subtotalStr = controller.formatPrice(subtotalVal);
            final totalStr = controller.formatPrice(totalVal);

            return Column(
              children: [
                _PriceBreakdownRow(label: 'Bag Subtotal', value: subtotalStr),
                const SizedBox(height: 8),
                _PriceBreakdownRow(
                  label: 'Delivery Fee',
                  value: (controller.isFreeShippingCoupon.value || controller.shippingCost.value <= 0) ? 'FREE' : controller.formatPrice(controller.shippingCost.value),
                  valueColor: const Color(0xFF2E7D32),
                ),
                if (isCod && cod > 0) ...[
                  const SizedBox(height: 8),
                  _PriceBreakdownRow(
                    label: 'COD Handling Fee',
                    value: '+ ${controller.formatPrice(cod)}',
                    valueColor: const Color(0xFFB45309),
                  ),
                ],
                if (disc > 0) ...[
                  const SizedBox(height: 8),
                  _PriceBreakdownRow(
                    label: 'Coupon Discount',
                    value: '- ${controller.formatPrice(disc)}',
                    valueColor: const Color(0xFF2E7D32),
                  ),
                ],
                const SizedBox(height: 8),
                const _PriceBreakdownRow(label: 'Estimated Taxes', value: 'Included', valueColor: Colors.black54),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 12),
                _PriceBreakdownRow(label: 'Grand Total', value: totalStr, isBold: true),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _PriceBreakdownRow extends StatelessWidget {
  const _PriceBreakdownRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: isBold ? Colors.black : Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 17 : 13.5,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: valueColor ?? (isBold ? Colors.black : Colors.black87),
          ),
        ),
      ],
    );
  }
}

/* ------------------------------ Payment ------------------------------ */
class _PaymentSection extends GetView<CheckoutController> {
  const _PaymentSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment_outlined, size: 20, color: Colors.black),
              SizedBox(width: 8),
              Text('3. Payment Method', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.2)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Select your preferred payment option below', style: TextStyle(fontSize: 11.5, color: Colors.black54)),
          const SizedBox(height: 14),

          Obx(() {
            final selectedId = controller.selectedPaymentId.value;

            return Column(
              children: [
                // COD Option Card
                GestureDetector(
                  onTap: () => controller.selectedPaymentId.value = 'cod',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selectedId == 'cod' ? const Color(0xFFF9F9F9) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedId == 'cod' ? Colors.black : const Color(0xFFE0E0E0),
                        width: selectedId == 'cod' ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: 'cod',
                          groupValue: selectedId,
                          onChanged: (v) => controller.selectedPaymentId.value = 'cod',
                          activeColor: Colors.black,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.payments_outlined, color: Color(0xFF2E7D32), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              const SizedBox(height: 2),
                              const Text('Pay with cash upon package delivery', style: TextStyle(fontSize: 11, color: Colors.black54)),
                              Obx(() {
                                final fee = controller.codFee.value;
                                if (fee <= 0) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFFDE68A)),
                                    ),
                                    child: Text(
                                      '+ ${controller.formatPrice(fee)} COD handling fee applies',
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Online Payment Option Card
                GestureDetector(
                  onTap: () => controller.selectedPaymentId.value = 'razorpay',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selectedId == 'razorpay' ? const Color(0xFFF9F9F9) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedId == 'razorpay' ? Colors.black : const Color(0xFFE0E0E0),
                        width: selectedId == 'razorpay' ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: 'razorpay',
                          groupValue: selectedId,
                          onChanged: (v) => controller.selectedPaymentId.value = 'razorpay',
                          activeColor: Colors.black,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.credit_card_outlined, color: Color(0xFF1565C0), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Online Payment (Razorpay)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              SizedBox(height: 2),
                              Text('UPI (Google Pay, PhonePe), Cards & Netbanking', style: TextStyle(fontSize: 11, color: Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 16),
          // Order Notes
          TextField(
            controller: controller.noteCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              labelText: 'Order notes / Special instructions (Optional)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ Saved Addresses Shortcut ------------------------------ */
class _SavedAddressesCard extends GetView<CheckoutController> {
  const _SavedAddressesCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bill = controller.savedBilling;
      final ship = controller.savedShipping;

      if (bill.isEmpty && ship.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saved Addresses', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            if (bill.isNotEmpty)
              RadioListTile<int>(
                contentPadding: EdgeInsets.zero,
                value: 0,
                groupValue: controller.selectedSaved.value,
                onChanged: (_) => controller.useSaved(true),
                title: const Text('Billing Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                subtitle: Text(controller.addressPretty(bill), style: const TextStyle(fontSize: 11.5)),
                activeColor: Colors.black,
              ),
            if (ship.isNotEmpty)
              RadioListTile<int>(
                contentPadding: EdgeInsets.zero,
                value: 1,
                groupValue: controller.selectedSaved.value,
                onChanged: (_) => controller.useSaved(false),
                title: const Text('Shipping Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                subtitle: Text(controller.addressPretty(ship), style: const TextStyle(fontSize: 11.5)),
                activeColor: Colors.black,
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Get.to(() => AddressScreen()),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Manage addresses', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    });
  }
}
