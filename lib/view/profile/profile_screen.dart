// lib/view/profile/profile_screen.dart
import 'package:tobeque/view/profile/address_binding.dart';
import 'package:tobeque/view/profile/address_controller.dart';
import 'package:tobeque/view/profile/address_screen.dart';
import 'package:tobeque/view/profile/orders_binding.dart';
import 'package:tobeque/view/profile/orders_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:tobeque/view/profile/profile_binding.dart';
import 'package:tobeque/view/profile/sign_in_up.dart';
import 'profile_controller.dart';

// NEW: use the dedicated Address & Orders screens/bindings

class ProfileScreen extends GetView<AuthController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ensure binding
    AuthBinding().dependencies();

    // helper: open address screen and preselect tab (0=billing, 1=shipping)
    void _openAddresses({required int initialTab}) {
      Get.to(() => const AddressScreen(), binding: AddressBinding());
      // set the tab after controller is created
      Future.microtask(() {
        if (Get.isRegistered<AddressController>()) {
          Get.find<AddressController>().tabIndex.value = initialTab;
        }
      });
    }

    return Obx(() {
      if (controller.loading.value && !controller.loggedIn.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (!controller.loggedIn.value) {
        return const SignInScreen();
      }

      final name = controller.displayName;
      final email = controller.email;
      final billing = controller.billing;
      final shipping = controller.shipping;

      return Scaffold(
        appBar: AppBar(
          title: const Text('My Account'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: .5,
         
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 5),
          child: GestureDetector(
            onTap: (){
              controller.logout();
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.red,
              ),
              
              child:   Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.logout,),
                    
                     SizedBox(
                      width: 3,
                     ),
                    
                  Text("Logout",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),)
                  ,
                 
                ],
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.black,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.isEmpty ? '(No name)' : name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(email.isEmpty ? '(No email)' : email,
                          style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Addresses', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _AddressTile(
              title: 'Billing',
              map: billing,
              onEdit: () => _openAddresses(initialTab: 0),
            ),
            const SizedBox(height: 10),
            _AddressTile(
              title: 'Shipping',
              map: shipping,
              onEdit: () => _openAddresses(initialTab: 1),
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.receipt_long),
              title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.w700)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.to(() => const OrdersScreen(), binding: OrdersBinding()),
            ),
          ],
        ),
      );
    });
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.title, required this.map, required this.onEdit});
  final String title;
  final Map<String, dynamic> map;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    String line1 = [map['first_name'], map['last_name']]
        .whereType<String>().where((s) => s.trim().isNotEmpty).join(' ');
    String line2 = [map['address_1'], map['address_2']]
        .whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');
    final city = map['city']?.toString() ?? '';
    final state = map['state']?.toString() ?? '';
    final postcode = map['postcode']?.toString() ?? '';
    final country = map['country']?.toString() ?? '';
    String line3 = [city, state, postcode].where((s) => s.trim().isNotEmpty).join(', ');
    String line4 = country;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEAEAEA)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: DefaultTextStyle(
              style: const TextStyle(height: 1.28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800,color: Colors.black),),
                  const SizedBox(height: 6),
                  if (line1.isNotEmpty) Text(line1,style: const TextStyle(color: Colors.black),),
                  if (line2.isNotEmpty) Text(line2,style: const TextStyle(color: Colors.black),),
                  if (line3.isNotEmpty) Text(line3,style: const TextStyle(color: Colors.black),),
                  if (line4.isNotEmpty) Text(line4,style: const TextStyle(color: Colors.black),),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}
