import 'package:get/get.dart';
import 'orders_controller.dart';

class OrdersBinding extends Bindings {
  @override
  void dependencies() {
    // Recreate each time you open Orders (or make it permanent if you prefer)
    Get.put<OrdersController>(OrdersController());
  }
}
