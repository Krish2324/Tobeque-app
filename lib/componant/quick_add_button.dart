import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../view/prodduct_details/product_detail_controller.dart';
import '../view/prodduct_details/size_sheet.dart';

class QuickAddButton extends StatefulWidget {
  final dynamic productId;
  final bool isDark;
  const QuickAddButton({super.key, required this.productId, this.isDark = false});
  @override
  State<QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends State<QuickAddButton> {
  bool _isLoading = false;

  Future<void> _handleTap() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final tag = 'quick_${widget.productId}';
      final c = Get.put(ProductDetailController(widget.productId), tag: tag);
      while (c.loading.value) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      final p = c.product.value;
      if (p == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load product')));
        return;
      }

      if (p['type']?.toString() == 'variable' && (c.sizeOptions.isNotEmpty || c.colorOptions.isNotEmpty)) {
        if (mounted) await openSizeSheet(context, c);
      } else {
        if (mounted) await c.addToCart(
          context: context,
          productId: widget.productId,
          quantity: 1,
          attributes: {},
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      Get.delete<ProductDetailController>(tag: 'quick_${widget.productId}', force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: widget.isDark ? Colors.white : Colors.black,
          shape: BoxShape.circle,
        ),
        child: _isLoading 
            ? Padding(padding: const EdgeInsets.all(6), child: CircularProgressIndicator(color: widget.isDark ? Colors.black : Colors.white, strokeWidth: 2))
            : Icon(Icons.add, color: widget.isDark ? Colors.black : Colors.white, size: 16),
      ),
    );
  }
}
