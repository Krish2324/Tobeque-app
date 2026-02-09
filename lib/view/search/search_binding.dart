import 'package:get/get.dart';
import 'package:tobeque/view/search/search_controller.dart';

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SearchController());
  }
}
