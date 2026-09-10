// product_detail_binding.dart
import 'package:get/get.dart';
import 'product_detail_controller.dart';

class ProductDetailBinding extends Bindings {
  final dynamic productId; // Accepts String (MongoDB _id) or int
  ProductDetailBinding(this.productId);

  @override
  void dependencies() {
    Get.create<ProductDetailController>(
      () => ProductDetailController(productId),
      tag: 'p:$productId',
    );
  }
}
