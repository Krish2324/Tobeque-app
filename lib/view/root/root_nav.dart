import 'package:tobeque/view/menu/menu_screen.dart';
import 'package:tobeque/view/root/bage_controller.dart';

import 'package:tobeque/view/profile/profile_screen.dart';
import 'package:tobeque/view/style_journal/style_journal_page.dart';
import 'package:flutter/material.dart';


import 'package:tobeque/view/home/homepage_view.dart';
import 'package:tobeque/view/search/search_screen.dart';
import 'package:tobeque/view/cart/cart_screen.dart';

// Your badge widget (rename the import if your file name differs)
 // -> provides CartBadge


import 'package:flutter/services.dart';


class RootNav extends StatefulWidget {
  const RootNav({super.key});

  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> with TickerProviderStateMixin {
  int _index = 0;

  late final List<Widget> _pages = <Widget>[
    HomePageView(),            // 0
    SearchScreen(),            // 1
   MenuScreen(),         // 2 (MENU)
    CartScreen(),              // 3
    // in RootNav pages list
 ProfileScreen(),
// 4
  ];

  // ---- bottom bar slide-up animation ----
  late final AnimationController _barCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final Animation<Offset> _barOffset =
      Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    // kick the bar in
    _barCtrl.forward();
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    super.dispose();
  }

  // Handle back button press
  Future<bool> _onWillPop() async {
    // If not on home tab, go to home first
    if (_index != 0) {
      setState(() => _index = 0);
      return false; // Don't exit
    }
    
    // If on home tab, show exit dialog
    return await _showExitDialog() ?? false;
  }

  // Show stylish exit confirmation dialog
  Future<bool?> _showExitDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 16,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with animation
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.exit_to_app_rounded,
                          size: 40,
                          color: Colors.red.shade400,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Exit App?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Message
                Text(
                  'Are you sure you want to exit the app?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                          // Exit the app
                          SystemNavigator.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Exit',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        // ---- page transition (slight slide up) ----
       body: IndexedStack(
 index: _index,
  children: _pages,
)
,

        // ---- bottom bar that slides in from bottom ----
        bottomNavigationBar: SlideTransition(
          position: _barOffset,
          child: _BottomBar(
            currentIndex: _index,
            onTap: (i) async {
             
              setState(() => _index = i);
            },
          ),
        ),
      ),
    );
  }

}

/// ---------------------------------------------------------------------------
/// Bottom bar (with live cart badge) - UNCHANGED
/// ---------------------------------------------------------------------------
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sel = theme.colorScheme.onSurface;
    final unSel = theme.iconTheme.color?.withOpacity(0.55) ?? Colors.black54;

    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BarItem(
              icon: Icons.home_rounded,
              outline: Icons.home_outlined,
              label: ' ',
              selected: currentIndex == 0,
              selectedColor: sel,
              unselectedColor: unSel,
              onTap: () => onTap(0),
            ),
            _BarItem(
              icon: Icons.search_rounded,
              outline: Icons.search,
              label: ' ',
              selected: currentIndex == 1,
              selectedColor: sel,
              unselectedColor: unSel,
              onTap: () => onTap(1),
            ),

            // Center "MENU" tap area
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(2),
              child: SizedBox(
                height: double.infinity,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Text(
                      'MENU',
                      style: theme.textTheme.labelLarge?.copyWith(
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Cart with live badge
            _BarItem(
              icon: Icons.shopping_bag,
              outline: Icons.shopping_bag_outlined,
              label: ' ',
              selected: currentIndex == 3,
              selectedColor: sel,
              unselectedColor: unSel,
              onTap: () => onTap(3),
              trailing: const CartBadge(), // <- badge
            ),
            _BarItem(
              icon: Icons.person,
              outline: Icons.person_outline,
              label: ' ',
              selected: currentIndex == 4,
              selectedColor: sel,
              unselectedColor: unSel,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.icon,
    required this.outline,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final IconData outline;
  final String label;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : unselectedColor;
    final iconWidget = Icon(selected ? icon : outline, color: color, size: 26);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 72,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (trailing == null)
              iconWidget
            else
              Stack(
                clipBehavior: Clip.none,
                children: [
                  iconWidget,
                  Positioned(right: -4, top: -2, child: trailing!),
                ],
              ),
            if (label.isNotEmpty) const SizedBox(height: 2),
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Simple placeholder
class _StubScreen extends StatelessWidget {
  final String title;
  const _StubScreen({required this.title, super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Profile', style: TextStyle(fontSize: 22))),
    );
  }
}
