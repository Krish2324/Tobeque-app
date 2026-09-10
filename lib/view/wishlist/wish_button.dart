import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'wishlist_service.dart';
import 'package:tobeque/view/home/models.dart';

class WishButton extends StatelessWidget {
  const WishButton.fromProduct(
    this.product, {
    super.key,
    this.size = 22,
    this.activeColor,
    this.inactiveColor,
  })  : id = null,
        name = null,
        priceHtml = null,
        image = null;

  const WishButton({
    super.key,
    required this.id,
    required this.name,
    this.priceHtml,
    this.image,
    this.size = 22,
    this.activeColor,
    this.inactiveColor,
  }) : product = null;

  final WcProduct? product;
  final String? id;  // MongoDB _id string
  final String? name;
  final String? priceHtml;
  final String? image;

  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    final svc = Get.find<WishlistService>();

    // SAFELY derive fields with null-aware access
    final String? pid = id ?? product?.id;
    if (pid == null || pid.isEmpty) {
      return const SizedBox.shrink();
    }

    final String nm  = (name ?? product?.name ?? '').trim();
    final String? ph = priceHtml ?? product?.priceHtml;
    final String? img = image ?? product?.image;

    final item = WishItem(id: pid, name: nm, priceHtml: ph, image: img);

    return Obx(() {
      final isFav = svc.isIn(pid);
      return IconButton(
        iconSize: size,
        padding: EdgeInsets.zero,
      //  visualDensity: VisualDensity.compact,
        icon: Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          color: isFav ? (activeColor ?? Colors.redAccent)
                       : (inactiveColor ?? Colors.black54),
        ),
        onPressed: () => svc.toggle(item),
        tooltip: isFav ? 'Remove from favourites' : 'Add to favourites',
      );
    });
  }
}
