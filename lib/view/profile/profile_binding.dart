// lib/view/profile/auth_binding.dart
import 'package:get/get.dart';
import 'profile_controller.dart'; // your AuthController file

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Lazy is fine; it gets created on first use.
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}
