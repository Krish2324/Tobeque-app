// product_detail_binding.dart
import 'package:get/get.dart';
import 'product_detail_controller.dart';

class ProductDetailBinding extends Bindings {
  final int productId;
  ProductDetailBinding(this.productId);

  @override
  void dependencies() {
    // Create a NEW controller instance tied to this route, disposed on pop
    Get.create<ProductDetailController>(
      () => ProductDetailController(productId),
      tag: 'p:$productId',
    );
  }
}
