import 'package:tobeque/view/cart/cart_events.dart';
import 'package:get/get.dart';

import 'package:tobeque/view/cart/cart_controller.dart';

class CartBinding extends Bindings {
  @override
  void dependencies() {
    // ensure a single CartEvents service lives in app
    if (!Get.isRegistered<CartEvents>()) {
      Get.put(CartEvents(), permanent: true);
    }
    Get.put(CartController(Get.find<CartEvents>()));
  }
}
