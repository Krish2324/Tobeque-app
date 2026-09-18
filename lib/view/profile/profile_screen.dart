import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tobeque/view/profile/address_binding.dart';
import 'package:tobeque/view/profile/address_controller.dart';
import 'package:tobeque/view/profile/address_screen.dart';
import 'package:tobeque/view/profile/orders_binding.dart';
import 'package:tobeque/view/profile/orders_controller.dart';
import 'package:tobeque/view/profile/orders_screen.dart';
import 'package:tobeque/view/profile/order_view_screen.dart';
import 'package:tobeque/view/profile/profile_binding.dart';
import 'package:tobeque/view/profile/sign_in_up.dart';
import 'profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0; // 0: Account Details, 1: Saved Addresses, 2: Orders

  @override
  Widget build(BuildContext context) {
    AuthBinding().dependencies();
    final controller = Get.find<AuthController>();

    return Obx(() {
      // If not logged in, return SignInScreen (do NOT unmount during loading!)
      if (!controller.loggedIn.value) {
        return const SignInScreen();
      }

      final name = controller.displayName;
      final email = controller.email;
      final phone = controller.phone;
      final photo = controller.profilePhoto;

      return Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          title: const Text(
            'MY ACCOUNT',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
        ),
        body: RefreshIndicator(
          onRefresh: () => controller.fetchUserProfile(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Profile Banner Card ─────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x0A000000),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFEFEFEF)),
                  ),
                  child: Row(
                    children: [
                      // Avatar with Photo Pick Trigger
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (ctx) => SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Profile Photo',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 12),
                                    ListTile(
                                      leading: const Icon(Icons.photo_library_outlined, color: Colors.black),
                                      title: const Text('Choose from Gallery'),
                                      onTap: () async {
                                        Navigator.pop(ctx);
                                        final ok = await controller.pickAndUploadProfilePhoto(ImageSource.gallery);
                                        if (ok) {
                                          Get.snackbar(
                                            'Success',
                                            'Profile photo updated successfully',
                                            snackPosition: SnackPosition.BOTTOM,
                                            backgroundColor: Colors.black87,
                                            colorText: Colors.white,
                                            margin: const EdgeInsets.all(16),
                                            duration: const Duration(seconds: 3),
                                          );
                                        } else if (controller.error.value != null && controller.error.value!.isNotEmpty) {
                                          Get.snackbar(
                                            'Error',
                                            controller.error.value!,
                                            snackPosition: SnackPosition.BOTTOM,
                                            backgroundColor: Colors.redAccent,
                                            colorText: Colors.white,
                                            margin: const EdgeInsets.all(16),
                                            duration: const Duration(seconds: 3),
                                          );
                                        }
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.camera_alt_outlined, color: Colors.black),
                                      title: const Text('Take a Photo'),
                                      onTap: () async {
                                        Navigator.pop(ctx);
                                        final ok = await controller.pickAndUploadProfilePhoto(ImageSource.camera);
                                        if (ok) {
                                          Get.snackbar(
                                            'Success',
                                            'Profile photo updated successfully',
                                            snackPosition: SnackPosition.BOTTOM,
                                            backgroundColor: Colors.black87,
                                            colorText: Colors.white,
                                            margin: const EdgeInsets.all(16),
                                            duration: const Duration(seconds: 3),
                                          );
                                        } else if (controller.error.value != null && controller.error.value!.isNotEmpty) {
                                          Get.snackbar(
                                            'Error',
                                            controller.error.value!,
                                            snackPosition: SnackPosition.BOTTOM,
                                            backgroundColor: Colors.redAccent,
                                            colorText: Colors.white,
                                            margin: const EdgeInsets.all(16),
                                            duration: const Duration(seconds: 3),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black12,
                                border: Border.all(color: Colors.black12, width: 2),
                              ),
                              child: ClipOval(
                                child: photo.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: photo,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        errorWidget: (_, __, ___) => Center(
                                          child: Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                            style: const TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            if (controller.loading.value)
                              Container(
                                width: 68,
                                height: 68,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black38,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0x0F000000),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'TOBEQUE MEMBER',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              name.isEmpty ? 'Tobeque User' : name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (phone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                phone,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Tab Bar Navigation ──────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEFEFEF)),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _buildTabItem(0, 'Account Details', Icons.person_outline),
                      _buildTabItem(1, 'Addresses', Icons.location_on_outlined),
                      _buildTabItem(2, 'Orders', Icons.shopping_bag_outlined),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Tab Content ─────────────────────────────────────────────
                if (_selectedTab == 0)
                  AccountDetailsForm(controller: controller)
                else if (_selectedTab == 1)
                  _buildSavedAddressesTab(context, controller)
                else
                  _buildOrdersTab(context, controller),

                const SizedBox(height: 28),

                // ── Logout Button ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Log Out'),
                          content: const Text('Are you sure you want to log out of your account?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Log Out'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        controller.logout();
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTabItem(int index, String title, IconData icon) {
    final active = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: active ? Colors.white : Colors.black54,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? Colors.white : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedAddressesTab(BuildContext context, AuthController controller) {
    void openAddresses({required int initialTab}) {
      Get.to(() => const AddressScreen(), binding: AddressBinding());
      Future.microtask(() {
        if (Get.isRegistered<AddressController>()) {
          Get.find<AddressController>().tabIndex.value = initialTab;
        }
      });
    }

    final billing = controller.billing;
    final shipping = controller.shipping;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Saved Addresses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            TextButton.icon(
              onPressed: () => openAddresses(initialTab: 0),
              icon: const Icon(Icons.edit, size: 16, color: Colors.black),
              label: const Text('Manage', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _AddressCard(
          title: 'Billing Address',
          line1: [billing['first_name'], billing['last_name']].whereType<String>().where((s) => s.trim().isNotEmpty).join(' '),
          address: [billing['address_1'], billing['address_2']].whereType<String>().where((s) => s.trim().isNotEmpty).join(', '),
          cityStateZip: [billing['city'], billing['state'], billing['postcode']].whereType<String>().where((s) => s.trim().isNotEmpty).join(', '),
          fallbackAddress: controller.address,
          fallbackCityStateZip: [controller.city, controller.state, controller.zipCode].where((s) => s.isNotEmpty).join(', '),
          onEdit: () => openAddresses(initialTab: 0),
        ),
        const SizedBox(height: 14),
        _AddressCard(
          title: 'Shipping Address',
          line1: [shipping['first_name'], shipping['last_name']].whereType<String>().where((s) => s.trim().isNotEmpty).join(' '),
          address: [shipping['address_1'], shipping['address_2']].whereType<String>().where((s) => s.trim().isNotEmpty).join(', '),
          cityStateZip: [shipping['city'], shipping['state'], shipping['postcode']].whereType<String>().where((s) => s.trim().isNotEmpty).join(', '),
          fallbackAddress: controller.shippingAddress.isNotEmpty ? controller.shippingAddress : controller.address,
          fallbackCityStateZip: [
            controller.shippingCity.isNotEmpty ? controller.shippingCity : controller.city,
            controller.shippingState.isNotEmpty ? controller.shippingState : controller.state,
            controller.shippingZipCode.isNotEmpty ? controller.shippingZipCode : controller.zipCode
          ].where((s) => s.isNotEmpty).join(', '),
          onEdit: () => openAddresses(initialTab: 1),
        ),
      ],
    );
  }

  Widget _buildOrdersTab(BuildContext context, AuthController authCtrl) {
    if (!Get.isRegistered<OrdersController>()) {
      OrdersBinding().dependencies();
    }
    final ordersCtrl = Get.find<OrdersController>();

    return Obx(() {
      final orders = ordersCtrl.orders;
      final loading = ordersCtrl.loading.value;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEFEFEF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 20, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      'Recent Orders',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Get.to(() => const OrdersScreen(), binding: OrdersBinding()),
                  child: const Text('View All', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (loading && orders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                ),
              )
            else if (orders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F7F8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_outlined, size: 36, color: Colors.black38),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No orders yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Once you place an order, it will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: orders.take(3).map((ord) {
                  final id = (ord['number'] ?? ord['id'] ?? ord['_id'] ?? '').toString();
                  final status = (ord['status'] ?? 'processing').toString().toUpperCase();
                  final total = (ord['total'] ?? ord['orderTotal'] ?? '0').toString();
                  final items = (ord['line_items'] ?? ord['items'] ?? []) as List;

                  Color statusBg = Colors.blue.shade50;
                  Color statusFg = Colors.blue.shade900;
                  if (status == 'COMPLETED' || status == 'DELIVERED') {
                    statusBg = Colors.green.shade50;
                    statusFg = Colors.green.shade800;
                  } else if (status == 'CANCELLED' || status == 'FAILED') {
                    statusBg = Colors.red.shade50;
                    statusFg = Colors.red.shade800;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ORDER #$id',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(color: statusFg, fontWeight: FontWeight.w800, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${items.length} Item${items.length == 1 ? '' : 's'}',
                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                            Text(
                              '₹$total',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Get.to(() => OrderViewScreen(orderId: id, order: ord)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.black12),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('View Order Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => Get.to(() => const OrdersScreen(), binding: OrdersBinding()),
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('VIEW ALL ORDERS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Account Details Form Component (Personal Info, Email, Phone, Gender, Addresses)
/// ─────────────────────────────────────────────────────────────────────────────
class AccountDetailsForm extends StatefulWidget {
  const AccountDetailsForm({super.key, required this.controller});
  final AuthController controller;

  @override
  State<AccountDetailsForm> createState() => _AccountDetailsFormState();
}

class _AccountDetailsFormState extends State<AccountDetailsForm> {
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _zipCtrl;
  late final TextEditingController _sAddressCtrl;
  late final TextEditingController _sCityCtrl;
  late final TextEditingController _sStateCtrl;
  late final TextEditingController _sZipCtrl;

  String _gender = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _populateControllers();
  }

  void _populateControllers() {
    final c = widget.controller;
    _firstCtrl = TextEditingController(text: c.firstName);
    _lastCtrl = TextEditingController(text: c.lastName);
    _emailCtrl = TextEditingController(text: c.email);
    _addressCtrl = TextEditingController(text: c.address);
    _cityCtrl = TextEditingController(text: c.city);
    _stateCtrl = TextEditingController(text: c.state);
    _zipCtrl = TextEditingController(text: c.zipCode);
    _sAddressCtrl = TextEditingController(text: c.shippingAddress);
    _sCityCtrl = TextEditingController(text: c.shippingCity);
    _sStateCtrl = TextEditingController(text: c.shippingState);
    _sZipCtrl = TextEditingController(text: c.shippingZipCode);
    _gender = c.gender;
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    _sAddressCtrl.dispose();
    _sCityCtrl.dispose();
    _sStateCtrl.dispose();
    _sZipCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final payload = {
      'firstName': _firstCtrl.text.trim(),
      'lastName': _lastCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'gender': _gender,
      'address': _addressCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'state': _stateCtrl.text.trim(),
      'zipCode': _zipCtrl.text.trim(),
      'shippingAddress': _sAddressCtrl.text.trim(),
      'shippingCity': _sCityCtrl.text.trim(),
      'shippingState': _sStateCtrl.text.trim(),
      'shippingZipCode': _sZipCtrl.text.trim(),
    };

    final ok = await widget.controller.updateUserProfile(payload);
    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        Get.snackbar(
          'Saved',
          'Account details updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 10,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Error',
          widget.controller.error.value ?? 'Failed to update account details',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFC62828),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 10,
        );
      }
    }
  }

  InputDecoration _inputDec(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.black54) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDBDBDB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Personal Information Card ───────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEFEFEF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Update your name, email, and personal preferences.',
                style: TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstCtrl,
                      decoration: _inputDec('First Name *', icon: Icons.person_outline),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastCtrl,
                      decoration: _inputDec('Last Name *'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDec('Email Address *', icon: Icons.email_outlined),
              ),
              const SizedBox(height: 14),

              // Disabled Phone Field (Read-only)
              TextFormField(
                initialValue: c.phone.isNotEmpty ? c.phone : 'Not set',
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Mobile Number (Registered)',
                  isDense: true,
                  prefixIcon: const Icon(Icons.phone_iphone, size: 20, color: Colors.black45),
                  suffixIcon: const Icon(Icons.lock_outline, size: 18, color: Colors.black38),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  fillColor: const Color(0xFFF5F5F5),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),

              // Gender Selector
              const Text(
                'Gender',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _genderChip('male', 'Male'),
                  const SizedBox(width: 8),
                  _genderChip('female', 'Female'),
                  const SizedBox(width: 8),
                  _genderChip('other', 'Other'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ── Billing Address Card ────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEFEFEF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Billing Address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _addressCtrl,
                decoration: _inputDec('Street Address', icon: Icons.home_outlined),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: _inputDec('City'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stateCtrl,
                      decoration: _inputDec('State'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _zipCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDec('ZIP / Postal Code', icon: Icons.pin_drop_outlined),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ── Shipping Address Card ───────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEFEFEF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shipping Address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _sAddressCtrl,
                decoration: _inputDec('Street Address', icon: Icons.local_shipping_outlined),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sCityCtrl,
                      decoration: _inputDec('City'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sStateCtrl,
                      decoration: _inputDec('State'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sZipCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDec('ZIP / Postal Code', icon: Icons.pin_drop_outlined),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Save Changes Button ─────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Save Account Details',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _genderChip(String value, String label) {
    final selected = _gender.toLowerCase() == value.toLowerCase();
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (bool sel) {
        if (sel) setState(() => _gender = value);
      },
      selectedColor: Colors.black,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? Colors.black : const Color(0xFFDBDBDB)),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.title,
    required this.line1,
    required this.address,
    required this.cityStateZip,
    required this.fallbackAddress,
    required this.fallbackCityStateZip,
    required this.onEdit,
  });

  final String title;
  final String line1;
  final String address;
  final String cityStateZip;
  final String fallbackAddress;
  final String fallbackCityStateZip;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final displayAddr = address.isNotEmpty ? address : fallbackAddress;
    final displayCityState = cityStateZip.isNotEmpty ? cityStateZip : fallbackCityStateZip;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0x0D000000),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on, color: Colors.black),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                if (line1.isNotEmpty)
                  Text(line1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                if (displayAddr.isNotEmpty)
                  Text(displayAddr, style: const TextStyle(color: Colors.black87, fontSize: 13)),
                if (displayCityState.isNotEmpty)
                  Text(displayCityState, style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
                if (displayAddr.isEmpty && displayCityState.isEmpty)
                  const Text(
                    'No address configured yet.',
                    style: TextStyle(color: Colors.black38, fontSize: 12.5, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
