import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'address_controller.dart';
import 'address_binding.dart';

class AddressScreen extends GetView<AddressController> {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AddressBinding().dependencies();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Addresses'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Obx(() => Column(
        children: [
          // tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(value: 0, label: Text('Billing')),
                ButtonSegment<int>(value: 1, label: Text('Shipping')),
              ],
              selected: {controller.tabIndex.value},
              onSelectionChanged: (s) => controller.tabIndex.value = s.first,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                if (controller.tabIndex.value == 0)
                  _AddressForm(
                    first: controller.bFirst,
                    last: controller.bLast,
                    company: controller.bCompany,
                    country: controller.bCountry,
                    addr1: controller.bAddr1,
                    addr2: controller.bAddr2,
                    city: controller.bCity,
                    state: controller.bState,
                    post: controller.bPost,
                    phone: controller.bPhone,
                    email: controller.bEmail,
                    onSave: controller.saveBilling,
                  )
                else
                  _AddressForm(
                    first: controller.sFirst,
                    last: controller.sLast,
                    company: controller.sCompany,
                    country: controller.sCountry,
                    addr1: controller.sAddr1,
                    addr2: controller.sAddr2,
                    city: controller.sCity,
                    state: controller.sState,
                    post: controller.sPost,
                    phone: controller.sPhone,
                    email: controller.sEmail,
                    onSave: controller.saveShipping,
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      )),
    );
  }
}

class _AddressForm extends StatelessWidget {
  const _AddressForm({
    required this.first, required this.last, required this.company,
    required this.country, required this.addr1, required this.addr2,
    required this.city, required this.state, required this.post,
    required this.phone, required this.email, required this.onSave,
  });

  final TextEditingController first, last, company, country, addr1, addr2,
      city, state, post, phone, email;
  final Future<void> Function() onSave;

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    border: const OutlineInputBorder(),
    isDense: true,
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0, color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: TextField(controller: first, decoration: _dec('First name'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: last,  decoration: _dec('Last name'))),
            ]),
            const SizedBox(height: 10),
            TextField(controller: company, decoration: _dec('Company')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(enabled: false, controller: country, decoration: _dec('Country/Region'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: phone,   decoration: _dec('Phone'), keyboardType: TextInputType.phone)),
            ]),
            const SizedBox(height: 10),
            TextField(controller: addr1, decoration: _dec('Address line 1')),
            const SizedBox(height: 10),
            TextField(controller: addr2, decoration: _dec('Address line 2')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: city,  decoration: _dec('City'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: state, decoration: _dec('State'))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: post,  decoration: _dec('Postcode'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: email, decoration: _dec('Email'), keyboardType: TextInputType.emailAddress)),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
