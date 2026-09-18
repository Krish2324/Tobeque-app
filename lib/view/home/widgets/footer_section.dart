import 'package:tobeque/componant/helper.dart';
import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/constants/string_constant.dart';
import 'package:tobeque/utills/helper_func.dart';
import 'package:tobeque/view/about/about_page.dart';
import 'package:tobeque/view/legal/privacy_policy_screen.dart';
import 'package:tobeque/view/legal/return_refund_policy.dart';
import 'package:tobeque/view/legal/shipping_policy.dart';
import 'package:tobeque/view/legal/sustainability_screen.dart';
import 'package:tobeque/view/legal/terms_purchase_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class StoreFooterTobeque extends StatelessWidget {
  const StoreFooterTobeque({
    super.key,
    this.onSubscribe,
    this.onCall,
    this.onChat,
    this.onPrivacy,
    this.onTerms,
    this.onCookies,
    this.onCookieSettings,
    this.appVersion = '1.0.0',
  });

  final VoidCallback? onSubscribe;

  // Bottom-sheet actions
  final VoidCallback? onCall;
  final VoidCallback? onChat;

  // Legal links
  final VoidCallback? onPrivacy;
  final VoidCallback? onTerms;
  final VoidCallback? onCookies;
  final VoidCallback? onCookieSettings;

  final String appVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF0E0E0E) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // -------------------- Newsletter hero --------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 30, 16, 25),
            child: _NewsletterHero(
              onSubscribe: onSubscribe,
            ),
          ),

          const SizedBox(height: 8),
         

          // -------------------- Menu rows --------------------
     
          _FooterRow(
            icon: Icons.info_outline_rounded,
            label: 'We are Tobeque',
            // simple inline expand for a couple of links
            trailingBuilder: (ctx, open) => _Chevron(open: open),
            // expanded: const _InlineList(items: [
            //   'About us',
            //   'Sustainability',
            //   'Careers',
            // ]),
            expanded: _InlineList(
              items: const ['About us', 'Careers'],
              onItemTap: (label, _) {
                switch (label) {
                  case 'About us':
                    Get.to(() => const AboutPage());
                    break;
                  case 'Careers':
                    launchWebUrl(Constent.carrerUrl);
                    break;
                }
              },
            ),

          ),
          _FooterRow(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Contact',
            onTap: () => _showContactSheet(context, onCall: onCall, onChat: onChat),
          ),
          const SizedBox(height: 25),
          const Divider(height: 1, thickness: 0.3),

          // -------------------- Legal links --------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 35, 16, 6),
            child: Wrap(
              alignment: WrapAlignment.start,
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _LegalLink('Terms and conditions of purchase', onTap: (){
                  Get.to(() => const TermsAndConditionsTobequePage());

                }),
                const _Dot(),
                _LegalLink('Privacy policy', onTap: (){
                  Get.to(PrivacyPolicyTobequePage());
                }),
                const _Dot(),
                _LegalLink('Shipping Policy', onTap: (){
                  Get.to(ShippingPolicyTobequePage());
                }),
                const _Dot(),
                 _LegalLink('Return Refund Policy', onTap: (){
                  Get.to(ReturnsRefundPolicyTobequePage());
                }),
                const _Dot(),
               
              ],
            ),
          ),

          // -------------------- App version --------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 16, 18),
            child: Text(
              'TOBEQUE • $appVersion',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
                letterSpacing: .2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  



  void _showContactSheet(BuildContext context,
      {VoidCallback? onCall, VoidCallback? onChat}) {
    _showActionSheet(
      context,
      title: 'Contact us',
      actions: [
        _SheetAction(
          title: 'Call ${Constent.phone}',
          subtitle: 'From Monday to Saturday from 09:00 to 18:00',
          status: 'Online',
          icon: Icons.call_outlined,
         onTap: () => launchPhoneCall(Constent.phone , context: context),
        ),
        _SheetAction(
          title: 'Start chat',
          subtitle: 'From Monday to Saturday from 09:00 to 17:30',
          status: 'Online',
          icon: Icons.chat_bubble_outline_rounded,
         onTap: () async {
    final ok = await openWhatsAppChat(
     Constent.phone,                // can be "09876 543210", "+91-98765-43210", etc.
      message: 'Hello 👋 Need some info.',
      defaultCountryCode: '91',   // change if needed
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp on this device')),
      );
    }
  },
        ),
      ],
    );
  }

  void _showActionSheet(
    BuildContext context, {
    required String title,
    required List<_SheetAction> actions,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      useSafeArea: true,
      backgroundColor: Colors.white,
      showDragHandle: true, // Material 3 handle like in the screenshot
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                 const SizedBox(height: 35),
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w400)),
              const SizedBox(height: 12),
              ...actions.map((a) => _ActionTile(action: a)),
               const SizedBox(height: 60),
            ],
            
          ),
        );
      },
    );
  }
}

/* ============================================================
 * Newsletter hero
 * ============================================================
 */
class _NewsletterHero extends StatefulWidget {
  const _NewsletterHero({this.onSubscribe});
  final VoidCallback? onSubscribe;

  @override
  State<_NewsletterHero> createState() => _NewsletterHeroState();
}

class _NewsletterHeroState extends State<_NewsletterHero> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _done    = false;

  Future<void> _subscribe() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final dio = Dio();
      await dio.post(ApiConstant.subscribers, data: {'email': email});
      setState(() { _loading = false; _done = true; });
      widget.onSubscribe?.call();
    } catch (_) {
      setState(() => _loading = false);
      // still show success (backend might return 409 for existing sub)
      setState(() => _done = true);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headline = Theme.of(context).textTheme.displaySmall?.copyWith(
          fontSize: 33,
          height: 1.15,
          letterSpacing: .4,
          fontWeight: FontWeight.bold,
        );

    if (_done) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SUBSCRIBED!', style: headline),
          const SizedBox(height: 10),
          const Text(
            "You're on the list. Expect the latest drops, promos, and style tips delivered to your inbox.",
            style: TextStyle(color: Colors.black87, height: 1.4),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SUBSCRIBE TO OUR\nNEWSLETTER', style: headline),
        const SizedBox(height: 15),
        const Text(
          'Be the first to get the latest news about trends,\n'
          'promotions and much more!',
          style: TextStyle(color: Colors.black87, height: 1.35),
        ),
        const SizedBox(height: 15),

        // Email input + button row
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _subscribe(),
                  decoration: InputDecoration(
                    hintText: 'Your email address',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    filled: true,
                    fillColor: const Color(0xFFF6F6F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Colors.black, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _loading ? null : _subscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Subscribe', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


/* ============================================================
 * Footer row (accordion-like)
 * ============================================================
 */
class _FooterRow extends StatefulWidget {
  const _FooterRow({
    required this.icon,
    required this.label,
    this.onTap,
    this.expanded,
    this.trailingBuilder,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// If provided, row becomes an inline accordion
  final Widget? expanded;

  /// Custom trailing (e.g., chevron that rotates)
  final Widget Function(BuildContext context, bool isOpen)? trailingBuilder;

  @override
  State<_FooterRow> createState() => _FooterRowState();
}

class _FooterRowState extends State<_FooterRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final row = Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(widget.icon),
        title: Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600,fontSize: 14),),
        trailing: widget.trailingBuilder?.call(context, _open) ??
            const Icon(Icons.chevron_right_rounded),
        onTap: () {
          if (widget.expanded != null) {
            setState(() => _open = !_open);
          } else {
            widget.onTap?.call();
          }
        },
      ),
    );

    if (widget.expanded == null) {
      return row;
    }

    return Column(
      children: [
        row,
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: widget.expanded!,
          ),
          crossFadeState:
              _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.open});
  final bool open;
  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      duration: const Duration(milliseconds: 200),
      turns: open ? .5 : 0,
      child: const Icon(Icons.expand_more_rounded),
    );
  }
}

// Replace your existing _InlineList with this version

class _InlineList extends StatelessWidget {
  const _InlineList({
    required this.items,
    this.onItemTap,                 // fallback handler: gets (label, index)
    this.actions,                   // per-label actions override
    this.spacing = 8,
  });

  final List<String> items;
  final void Function(String label, int index)? onItemTap;
  final Map<String, VoidCallback>? actions;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (i) {
        final label = items[i];
        final tap = (actions != null && actions!.containsKey(label))
            ? actions![label]
            : (onItemTap != null ? () => onItemTap!(label, i) : null);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: tap,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: spacing),
              child: Row(
                children: [
                  const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}


/* ============================================================
 * Bottom sheet pieces
 * ============================================================
 */
class _SheetAction {
  final String title;
  final String subtitle;
  final String status; // "Online"
  final IconData icon;
  final VoidCallback? onTap;

  _SheetAction({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
    this.onTap,
  });
}



/* ============================================================
 * Legal links
 * ============================================================
 */
class _LegalLink extends StatelessWidget {
  const _LegalLink(this.text, {this.onTap});
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 2),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: isDark ? Colors.white : Colors.black,
            decorationColor: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text('·', style: TextStyle(color: isDark ? Colors.white60 : Colors.black45));
  }
}
/// One row in the sheet (Call / Start chat)
class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});
  final _SheetAction action;

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(2);
    final borderColor = const Color(0xFFE7E7E7);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: Colors.white,
        borderRadius: border,
        child: InkWell(
          borderRadius: border,
          onTap: action.onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: border,
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading icon in a subtle circle
                
                const SizedBox(width: 12),

                // Title + “Online” + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + status chip
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0,vertical: 15),
                        child: Row(
                          children: [
                            // Title wraps if needed
                            Expanded(
                              child: Text(
                                action.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16,
                                  height: 1.1,
                                ),
                              ),
                            ),
                           
                            _StatusPill(text: action.status),
                             const SizedBox(width: 28), // “Online”
                          ],
                        ),
                      ),

                     
                      Text(
                        action.subtitle,
                        maxLines: 2,
                        style: const TextStyle(
                          color: Colors.black54,
                          
                          fontSize: 17,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.black54),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small green “Online” label with a dot
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // green dot
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF0FA678),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Online',
            style: TextStyle(
              color: Color(0xFF0FA678),
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}