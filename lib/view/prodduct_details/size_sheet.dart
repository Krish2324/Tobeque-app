// lib/view/prodduct_details/size_sheet.dart
import 'package:tobeque/componant/helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'product_detail_controller.dart';
import 'package:tobeque/view/cart/cart_screen.dart';

Future<void> openSizeSheet(BuildContext context, ProductDetailController c) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => _SizeSheet(c: c),
  );
}

class _SizeSheet extends StatelessWidget {
  const _SizeSheet({required this.c});
  final ProductDetailController c;

  // ---------- Snack helpers (use Get.showSnackbar so it shows over sheets) ----------
 void _showSnackSuccess(String title, String message) {
  Get.closeAllSnackbars();
  Get.showSnackbar(
    GetSnackBar(
      snackPosition: SnackPosition.TOP,
      snackStyle: SnackStyle.FLOATING,
      backgroundColor: Colors.grey.shade600,
      borderRadius: 10,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // tighter
      duration: const Duration(seconds: 2),
      messageText: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          // Single compact line (title • message)
          Expanded(
            child: Text(
              '$title • $message',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Get.closeAllSnackbars();
              Get.to(() => const CartScreen());
            },
            child: const Text(
              'VIEW',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}

  void _showSnackError(String title, String message) {
    Get.closeAllSnackbars();
    Get.showSnackbar(
      GetSnackBar(
        titleText: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900)),
        messageText: Text(message,
            style: const TextStyle(color: Colors.white, height: 1.2)),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 2),
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
        snackPosition: SnackPosition.TOP,
      ),
    );
  }

  Future<void> _closeSheet(BuildContext context) async {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
      return;
    }
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    final root = Navigator.of(context, rootNavigator: true);
    if (root.canPop()) root.pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Center(
              child: Container(
                width: 44, height: 6,
                decoration: BoxDecoration(
                  color: Colors.black12, borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                const Text('Select size', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {/* TODO: size guide */},
                  icon: const Icon(Icons.straighten, size: 18),
                  label: const Text('Size guide'),
                ),
              ],
            ),

            // ---- Sizes (reactive) ----
            if (c.sizeOptions.isNotEmpty)
              _Section(
                title: null,
                child: Obx(() {
                  final current = (c.sizeSlug.value ?? '');
                  return Column(
                    children: c.sizeOptions.map((opt) {
                      final slug  = (opt['slug'] ?? '') as String;
                      final label = (opt['label'] ?? slug.toUpperCase()) as String;
                      final selected = slug.isNotEmpty && current == slug;
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: selected
                              ? const Icon(Icons.check_circle, color: Colors.black, key: ValueKey('on'))
                              : const SizedBox(width: 24, key: ValueKey('off')),
                        ),
                        onTap: () {
                          c.sizeSlug.value  = slug;
                          c.sizeLabel.value = label;
                        },
                      );
                    }).toList(),
                  );
                }),
              ),

            // ---- Colors (reactive) ----
          // ---- Colors (reactive, as colored chips) ----
if (c.colorOptions.isNotEmpty)
  Align(
    alignment: Alignment.bottomLeft,
    child: _Section(
      title: 'Color',
      child: Obx(() {
        final current = (c.colorSlug.value ?? '');
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: c.colorOptions.map((opt) {
              final slug  = (opt['slug'] ?? '').toString();
              final label = (opt['label'] ?? slug.toUpperCase()).toString();
              final selected = slug.isNotEmpty && current == slug;
              final color = guessColor(label) ?? guessColor(slug);
    
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  c.colorSlug.value  = slug;
                  c.colorLabel.value = label;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: selected ? Colors.black : const Color(0xFFE5E5E5),
                      width: selected ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          color: color ?? Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.black12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: .2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }),
    ),
  ),

            const SizedBox(height: 12),

            // ---- ADD TO BAG ----
          // ---- ADD TO BAG ----
SizedBox(
  width: double.infinity,
  height: 50,
  child: Obx(() {
    final busy = c.adding.value;

    final sizeSlug  = (c.sizeSlug.value ?? '').trim();
    final colorSlug = (c.colorSlug.value ?? '').trim();

    final attrs = <String, String>{};
    if (sizeSlug.isNotEmpty)  attrs['pa_size']  = sizeSlug;
    if (colorSlug.isNotEmpty) attrs['pa_color'] = colorSlug;

    // product id
    final int? pid = (() {
      try {
        final m = (c as dynamic).product?.value as Map<String, dynamic>?;
        return m?['id'] as int?;
      } catch (_) { return null; }
    })();

    return ElevatedButton(
      onPressed: busy
          ? null
          : () async {
              if (pid == null) {
                await _closeSheet(context);
                _showSnackError('Couldn’t add item', 'Product not ready yet.');
                return;
              }
              if (c.sizeOptions.isNotEmpty && sizeSlug.isEmpty) {
                _showSnackError('Select size', 'Please choose a size before adding.');
                return;
              }
              if (c.colorOptions.isNotEmpty && colorSlug.isEmpty) {
                _showSnackError('Select color', 'Please choose a color before adding.');
                return;
              }

              final ok = await c.addToCart(
                context: context,
                productId: pid,
                quantity: c.qty.value,
                attributes: attrs,
                variationId: null,
              );

              await _closeSheet(context);
              ok
                ? _showSnackSuccess('Added to bag', 'Item added successfully.')
                : _showSnackError('Failed to add', 'Please try again.');
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.5),
        ),
      ),
      child: busy
          ? const SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Text('ADD TO BAG', style: TextStyle(fontWeight: FontWeight.w900)),
    );
  }),
),

          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({this.title, required this.child});
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
              child: Text(title!, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffeeeeee)),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
