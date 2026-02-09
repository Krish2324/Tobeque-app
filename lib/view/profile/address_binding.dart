// lib/view/profile/address_binding.dart
import 'package:get/get.dart';
import 'address_controller.dart';

class AddressBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddressController>(() => AddressController());
  }
}
