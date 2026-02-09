import 'package:get/get.dart';
import 'wishlist_service.dart';

class WishlistBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<WishlistService>()) {
      Get.put(WishlistService(), permanent: true);
    }
  }
}
