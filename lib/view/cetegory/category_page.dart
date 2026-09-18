// lib/view/category/category_page.dart
import 'package:tobeque/componant/shimmer_componant.dart';
import 'package:tobeque/utills/html_decode.dart';
import 'package:tobeque/view/prodduct_details/product_detail_binding.dart';
import 'package:tobeque/view/prodduct_details/product_details_page.dart';
import 'package:tobeque/view/wishlist/wish_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tobeque/constants/api_constants.dart';
import 'package:tobeque/componant/helper.dart';
import '../home/home_repository.dart';

enum SortMode { popular, priceLowHigh, priceHighLow }
enum GridMode { full, two, three } // NEW

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key, required this.categoryId, required this.title});
  final String categoryId; // Real MongoDB _id string
  final String title;

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
final repo = HomeRepository();

  bool loading = true;
  String? error;
  // current category being shown
  late String _currentCatId; // MongoDB _id string
  late String _currentTitle;
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> products = [];

  SortMode sort = SortMode.popular;
  GridMode grid = GridMode.two;
  int activeFilters = 0;

  final _sc = ScrollController();

  // NEW ▼ facets (available options) + selections
  final Set<String> _facetColors = <String>{};
  final Set<String> _facetSizes  = <String>{};
  final Set<String> _selColors   = <String>{};
  final Set<String> _selSizes    = <String>{};
  bool _onlyDiscount = false;
  double? _minPriceFilter;
  double? _maxPriceFilter;

  double _getProductPrice(Map<String, dynamic> p) {
    final priceNum = p['price'] ?? p['discountPrice'] ?? p['regularPrice'];
    if (priceNum != null && priceNum is num) return priceNum.toDouble();
    if (priceNum != null && priceNum is String) return double.tryParse(priceNum) ?? 0.0;
    
    final prices = p['prices'];
    if (prices is Map && prices['price'] != null) {
      return double.tryParse(prices['price'].toString()) ?? 0.0;
    }
    return 0.0;
  }

  // NEW ▼ subcategories (optional)
  List<Map<String, dynamic>> _subcats = const [];



 

  bool _showAppBarFilter = false;

  @override
  void initState() {
    super.initState();
        // ✅ initialize first
    _currentCatId = widget.categoryId;
    _currentTitle = widget.title;
    _load();
    
    _sc.addListener(() {
      final shouldShow = _sc.hasClients && _sc.offset > 120;
      if (shouldShow != _showAppBarFilter) {
        setState(() => _showAppBarFilter = shouldShow);
      }
    });
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  Future<void> _load([String? catId]) async {
    setState(() { loading = true; error = null; });
    final id = catId ?? _currentCatId;
    try {
      final res = await repo.fetchProductsByCategory(categoryId: id);
      _all = List<Map<String, dynamic>>.from(res);
      products = List<Map<String, dynamic>>.from(_all);
      _collectFacets();
      _fetchSubcategories();          // uses _currentCatId internally
      _applySort();
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }
  // ---------- FACETS ----------
void _collectFacets() {
  _facetColors.clear();
  _facetSizes.clear();

  const standardOrder = [
    'black', 'white', 'grey', 'beige', 'brown', 'blue', 'navy', 'green', 'red', 'pink', 'yellow', 'purple', 'orange'
  ];

  final Set<String> extractedColors = {};
  for (final p in _all) {
    final cList = _extractProductColors(p);
    extractedColors.addAll(cList.map((e) => e.toLowerCase()));
    
    final sList = _extractProductSizes(p);
    _facetSizes.addAll(sList.map((e) => e.toLowerCase()));
  }

  final Set<String> canonicalSet = {};

  for (final sc in standardOrder) {
    final canonicalName = _canonicalColorName(sc);
    if (!canonicalSet.contains(canonicalName)) {
      canonicalSet.add(canonicalName);
      _facetColors.add(canonicalName);
    }
  }

  for (final ec in extractedColors) {
    final canonicalName = _canonicalColorName(ec);
    if (!canonicalSet.contains(canonicalName)) {
      canonicalSet.add(canonicalName);
      _facetColors.add(canonicalName);
    }
  }
}

bool _productHasAnyColor(Map p, Set<String> want) {
  if (want.isEmpty) return true;
  final cList = _extractProductColors(p as Map<String, dynamic>);
  final pSet = cList.map((e) => e.toLowerCase()).toSet();
  final pName = (p['name'] ?? p['title'] ?? '').toString().toLowerCase();

  final wantCanonical = want.map((w) => _canonicalColorName(w)).toSet();

  for (final c in pSet) {
    if (wantCanonical.contains(_canonicalColorName(c))) return true;
  }

  for (final w in want) {
    final target = w.toLowerCase().trim();
    if (pName.contains(target)) return true;
  }

  return false;
}

bool _productHasAnySize(Map p, Set<String> want) {
  if (want.isEmpty) return true;
  final sList = _extractProductSizes(p as Map<String, dynamic>);
  final pSet = sList.map((e) => e.toLowerCase()).toSet();
  return pSet.intersection(want.map((e) => e.toLowerCase()).toSet()).isNotEmpty;
}


  bool _productDiscounted(Map p) {
    // Woo Store API often exposes: prices.sale_price, prices.regular_price, is_on_sale
    final prices = p['prices'];
    if (prices is Map) {
      final onSale = prices['on_sale'] == true || prices['is_on_sale'] == true;
      if (onSale) return true;
      final sale = double.tryParse('${prices['sale_price'] ?? ''}') ?? 0;
      final reg  = double.tryParse('${prices['regular_price'] ?? ''}') ?? 0;
      if (sale > 0 && reg > 0 && sale < reg) return true;
    }
    // Fallback: price_html contains <del>
    final html = (p['price_html'] ?? p['priceHtml'])?.toString() ?? '';
    return html.contains('<del');
  }

  void _applyFilters() {
    List<Map<String, dynamic>> list = _all.where((p) {
      if (!_productHasAnyColor(p, _selColors)) return false;
      if (!_productHasAnySize(p, _selSizes)) return false;
      if (_onlyDiscount && !_productDiscounted(p)) return false;
      
      final price = _getProductPrice(p);
      if (_minPriceFilter != null && price < _minPriceFilter!) return false;
      if (_maxPriceFilter != null && price > _maxPriceFilter!) return false;
      
      return true;
    }).toList();

    // badge count
    activeFilters = (_selColors.isNotEmpty ? 1 : 0) +
                    (_selSizes.isNotEmpty ? 1 : 0) +
                    (_onlyDiscount ? 1 : 0) +
                    (_minPriceFilter != null || _maxPriceFilter != null ? 1 : 0);

    products = list;
    _applySort();
    setState(() {});
  }


  // ---------- SUBCATEGORIES ----------
  Future<void> _fetchSubcategories() async {
    try {
      final allCats = await repo.fetchSubcategories(parentId: _currentCatId);
      List<Map<String, dynamic>> subs = [];

      List<Map<String, dynamic>> flatList = [];
      void flatten(List<dynamic> list) {
        for (final item in list) {
          if (item is Map) {
            final map = item.cast<String, dynamic>();
            flatList.add(map);
            if (map['subcategories'] is List && (map['subcategories'] as List).isNotEmpty) {
              flatten(map['subcategories']);
            }
          }
        }
      }
      flatten(allCats);

      if (_currentCatId != 'all' && _currentCatId.isNotEmpty) {
        final match = flatList.firstWhere(
          (c) => (c['_id'] ?? c['id'] ?? '').toString() == _currentCatId,
          orElse: () => <String, dynamic>{},
        );

        if (match.isNotEmpty && match['subcategories'] is List && (match['subcategories'] as List).isNotEmpty) {
          subs = (match['subcategories'] as List)
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList();
        } else {
          subs = flatList.where((c) {
            final parentId = c['parent'] is Map
                ? (c['parent']['_id'] ?? c['parent']['id'] ?? '').toString()
                : (c['parent'] ?? c['parentCategory'] ?? c['parentId'] ?? '').toString();
            final cid = (c['_id'] ?? c['id'] ?? '').toString();
            return parentId == _currentCatId && cid != _currentCatId;
          }).toList();

          if (subs.isEmpty && match.isNotEmpty) {
            final currentParentId = match['parent'] is Map
                ? (match['parent']['_id'] ?? match['parent']['id'] ?? '').toString()
                : (match['parent'] ?? match['parentCategory'] ?? match['parentId'] ?? '').toString();

            if (currentParentId.isNotEmpty && currentParentId != 'null' && currentParentId != '0') {
              final parentMatch = flatList.firstWhere(
                (c) => (c['_id'] ?? c['id'] ?? '').toString() == currentParentId,
                orElse: () => <String, dynamic>{},
              );
              if (parentMatch.isNotEmpty && parentMatch['subcategories'] is List) {
                subs = (parentMatch['subcategories'] as List)
                    .whereType<Map>()
                    .map((e) => e.cast<String, dynamic>())
                    .toList();
              }
            }
          }
        }
      } else {
        subs = allCats;
      }
      _subcats = subs;
    } catch (_) {
      _subcats = const [];
    }
    if (mounted) setState(() {});
  }




// --- helpers to read attribute values safely ---
String _termLabel(dynamic o) {
  if (o is Map) return (o['name'] ?? o['value'] ?? o['slug'] ?? '').toString();
  return o?.toString() ?? '';
}
Set<String> _termSet(dynamic listLike) {
  final out = <String>{};
  if (listLike is List) {
    for (final o in listLike) {
      final s = _termLabel(o).trim();
      if (s.isNotEmpty) out.add(s.toLowerCase());
    }
  } else if (listLike is String && listLike.isNotEmpty) {
    out.addAll(listLike.split(',').map((e) => e.trim().toLowerCase()));
  }
  return out;
}


  /* -------------------------------- SORT -------------------------------- */
  Future<void> _openFilterSheet() async {
    final tempColors = Set<String>.from(_selColors);
    final tempSizes  = Set<String>.from(_selSizes);
    bool tempDiscount = _onlyDiscount;
    SortMode tempSort = sort;
    bool expandedColors = false;

    double absoluteMin = 0.0;
    double absoluteMax = 10000.0;
    if (_all.isNotEmpty) {
      final prices = _all.map((p) => _getProductPrice(p)).where((p) => p > 0).toList();
      if (prices.isNotEmpty) {
        absoluteMin = prices.reduce((a, b) => a < b ? a : b).floorToDouble();
        absoluteMax = prices.reduce((a, b) => a > b ? a : b).ceilToDouble();
      }
    }
    if (absoluteMax <= absoluteMin) {
      absoluteMax = absoluteMin + 1000;
    }

    RangeValues tempRange = RangeValues(
      (_minPriceFilter ?? absoluteMin).clamp(absoluteMin, absoluteMax),
      (_maxPriceFilter ?? absoluteMax).clamp(absoluteMin, absoluteMax),
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) {
          final resCount = _all.where((p) {
            if (tempColors.isNotEmpty && !_productHasAnyColor(p, tempColors)) return false;
            if (tempSizes.isNotEmpty  && !_productHasAnySize(p, tempSizes))   return false;
            if (tempDiscount && !_productDiscounted(p)) return false;

            final price = _getProductPrice(p);
            if (price < tempRange.start) return false;
            if (price > tempRange.end) return false;

            return true;
          }).length;

          Widget groupTitle(String s) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text(
              s.toUpperCase(), 
              style: const TextStyle(
                fontWeight: FontWeight.w700, 
                fontSize: 12, 
                letterSpacing: 1.2, 
                color: Color(0xFF6B7280) // cool grey
              ),
            ),
          );

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.86,
              child: Column(
                children: [
                  // header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: Row(
                      children: [
                        const SizedBox(width: 40),
                        const Expanded(
                          child: Text('Filter', textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                        TextButton(
                          onPressed: () {
                            setM(() {
                              tempColors.clear();
                              tempSizes.clear();
                              tempDiscount = false;
                              tempSort = SortMode.popular;
                              tempRange = RangeValues(absoluteMin, absoluteMax);
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // Sort by
                        groupTitle('Sort by'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 10, runSpacing: 10,
                            children: [
                              for (final s in SortMode.values)
                                ChoiceChip(
                                  label: Text(
                                    s == SortMode.popular ? 'New In'
                                      : s == SortMode.priceLowHigh ? 'Price low to high'
                                      : 'Price high to low',
                                  ),
                                  selected: tempSort == s,
                                  onSelected: (_) => setM(() => tempSort = s),
                                  selectedColor: Colors.black,
                                  labelStyle: TextStyle(
                                    color: tempSort == s ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  shape: StadiumBorder(
                                    side: BorderSide(color: Colors.black.withValues(alpha: .12)),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Colour
                        if (_facetColors.isNotEmpty) ...[
                          const Divider(height: 24),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'COLORS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    letterSpacing: 1.2,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                if (_facetColors.length > 7)
                                  GestureDetector(
                                    onTap: () => setM(() => expandedColors = !expandedColors),
                                    child: Text(
                                      expandedColors ? 'Show Less' : '+${_facetColors.length - 7} More',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Wrap(
                              spacing: 14, runSpacing: 12,
                              children: (expandedColors ? _facetColors : _facetColors.take(7)).map((c) {
                                final sel = tempColors.contains(c);
                                final colorVal = _colorFromName(c);
                                final isWhiteOrLight = colorVal == const Color(0xFFFFFFFF) || colorVal == const Color(0xFFFAFAFA) || colorVal == const Color(0xFFF6F4E8);
                                return GestureDetector(
                                  onTap: () => setM(() {
                                    if (sel) tempColors.remove(c); else tempColors.add(c);
                                  }),
                                  child: Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: colorVal,
                                      border: Border.all(
                                        color: sel 
                                            ? Colors.black 
                                            : (isWhiteOrLight ? const Color(0xFFE5E7EB) : Colors.transparent), 
                                        width: sel ? 2.5 : 1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: sel ? Icon(
                                      Icons.check,
                                      size: 18,
                                      color: (colorVal == const Color(0xFF000000) || colorVal == const Color(0xFF111111) || colorVal == const Color(0xFF1D3557) || colorVal == const Color(0xFF1E3A8A) || colorVal == const Color(0xFF78350F))
                                          ? Colors.white
                                          : Colors.black,
                                    ) : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],

                        // Size
                        if (_facetSizes.isNotEmpty) ...[
                          const Divider(height: 24),
                          groupTitle('Size'),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Wrap(
                              spacing: 10, runSpacing: 10,
                              children: _facetSizes.map((s) {
                                final sel = tempSizes.contains(s);
                                return ChoiceChip(
                                  label: Text(s.toUpperCase()),
                                  selected: sel,
                                  onSelected: (_) => setM(() {
                                    if (sel) tempSizes.remove(s); else tempSizes.add(s);
                                  }),
                                  selectedColor: Colors.black,
                                  labelStyle: TextStyle(
                                    color: sel ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  shape: StadiumBorder(
                                    side: BorderSide(color: Colors.black.withValues(alpha: .12)),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],

                        // Discount
                        const Divider(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: tempDiscount,
                            onChanged: (v) => setM(() => tempDiscount = v ?? false),
                            title: const Text('With discount',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            controlAffinity: ListTileControlAffinity.trailing,
                          ),
                        ),
                        // Price Range
                        const Divider(height: 24),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'PRICE RANGE',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              Text(
                                '₹${tempRange.start.round()} - ₹${tempRange.end.round()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: Colors.black,
                              inactiveTrackColor: const Color(0xFFE5E7EB),
                              thumbColor: Colors.black,
                              overlayColor: Colors.black.withValues(alpha: 0.12),
                              trackHeight: 4,
                              rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 9),
                            ),
                            child: RangeSlider(
                              values: tempRange,
                              min: absoluteMin,
                              max: absoluteMax,
                              divisions: (absoluteMax - absoluteMin) > 0 
                                  ? ((absoluteMax - absoluteMin) / 50).clamp(10, 200).toInt() 
                                  : 100,
                              labels: RangeLabels(
                                '₹${tempRange.start.round()}',
                                '₹${tempRange.end.round()}',
                              ),
                              onChanged: (RangeValues values) {
                                setM(() {
                                  tempRange = values;
                                });
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹${absoluteMin.round()}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '₹${absoluteMax.round()}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // Footer button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // apply
                          sort = tempSort;
                          _selColors
                            ..clear()
                            ..addAll(tempColors);
                          _selSizes
                            ..clear()
                            ..addAll(tempSizes);
                          _onlyDiscount = tempDiscount;
                          _minPriceFilter = tempRange.start > absoluteMin ? tempRange.start : null;
                          _maxPriceFilter = tempRange.end < absoluteMax ? tempRange.end : null;
                          Navigator.pop(ctx);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text('SEE RESULTS ($resCount)',
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _applySort() {
    int safeInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    double safeDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    int priceMinor(Map<String, dynamic> p) {
      final prices = p['prices'];
      if (prices is Map && prices['price'] != null) {
        final rawStr = prices['price'].toString();
        return (double.tryParse(rawStr) ?? 0).round();
      }
      return 0;
    }

    final list = [...products];

    switch (sort) {
      case SortMode.popular:
        list.sort((a, b) {
          final r1 = safeInt(a['review_count']);
          final r2 = safeInt(b['review_count']);
          if (r1 != r2) return r2.compareTo(r1);
          final ar1 = safeDouble(a['average_rating']);
          final ar2 = safeDouble(b['average_rating']);
          if (ar1 != ar2) return ar2.compareTo(ar1);
          return safeInt(b['id']).compareTo(safeInt(a['id']));
        });
        break;
      case SortMode.priceLowHigh:
        list.sort((a, b) => _getProductPrice(a).compareTo(_getProductPrice(b)));
        break;
      case SortMode.priceHighLow:
        list.sort((a, b) => _getProductPrice(b).compareTo(_getProductPrice(a)));
        break;
    }

    products = list;
    setState(() {});
  }

  /* ------------------------------- BUILD -------------------------------- */

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: _CategorySkeleton(),
      );
    }
    if (error != null) {
      return Scaffold(
        body: _ErrorState(message: error!, onRetry: _load),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _sc,
        slivers: [
          // AppBar
      SliverAppBar(
        pinned: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '',
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(_currentTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        actions: [
          if (_showAppBarFilter)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: _openFilterSheet,
                  tooltip: 'Filter',
                ),
                if (activeFilters > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$activeFilters',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(width: 4),
        ],
      ),
// Subcategories / Category horizontal pill bar (web style)
SliverToBoxAdapter(
  child: SizedBox(
    height: 48,
    child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      scrollDirection: Axis.horizontal,
      children: [
        // ALL PRODUCTS chip
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(
              'ALL PRODUCTS',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
                letterSpacing: 0.5,
                color: _currentCatId == 'all' ? Colors.white : Colors.black,
              ),
            ),
            onPressed: () async {
              if (_currentCatId == 'all') return;
              setState(() {
                _currentCatId = 'all';
                _currentTitle = 'ALL PRODUCTS';
                loading = true;
                products = const [];
              });
              _sc.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
              await _load('all');
            },
            backgroundColor: _currentCatId == 'all' ? Colors.black : Colors.white,
            shape: StadiumBorder(
              side: BorderSide(color: _currentCatId == 'all' ? Colors.black : Colors.black12),
            ),
          ),
        ),

        // Subcategory / Category chips
        ..._subcats.map((c) {
          final id = (c['_id'] ?? c['id'] ?? '').toString();
          final name = (c['name'] ?? '').toString();
          final selected = id == _currentCatId || name.toLowerCase() == _currentTitle.toLowerCase();

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                name.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                  letterSpacing: 0.5,
                  color: selected ? Colors.white : Colors.black,
                ),
              ),
              onPressed: () async {
                if (selected) return;
                setState(() {
                  _currentCatId = id;
                  _currentTitle = name;
                  loading = true;
                  products = const [];
                });
                _sc.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                await _load(id);
              },
              backgroundColor: selected ? Colors.black : Colors.white,
              shape: StadiumBorder(
                side: BorderSide(color: selected ? Colors.black : Colors.black12),
              ),
            ),
          );
        }),
      ],
    ),
  ),
),


               // 3) Toolbar (layout + result count + filter + sort)
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12).copyWith(top: 6, bottom: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => grid = GridMode.full),
                child: _ToolbarIcon(icon: Icons.crop_square, selected: grid == GridMode.full),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => grid = GridMode.two),
                child: _ToolbarIcon(icon: Icons.table_rows_rounded, selected: grid == GridMode.two),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => grid = GridMode.three),
                child: _ToolbarIcon(icon: Icons.grid_view, selected: grid == GridMode.three),
              ),
              const Spacer(),

              // result count
              Text('${products.length} results',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(width: 8),

              // filter badge + button
              if (activeFilters > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black, borderRadius: BorderRadius.circular(14)),
                  child: Text('$activeFilters',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 6),
              ],
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: _openFilterSheet,
                tooltip: 'Filter',
              ),

              // sort popup
              
            ],
          ),
        ),
      ),

          // Content changes by grid mode
          if (grid == GridMode.full)
            SliverList(
              delegate: SliverChildListDelegate(
                _buildStaggeredBlocks(context),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: grid == GridMode.two ? 2 : 3,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                  childAspectRatio: grid == GridMode.two ? 0.58 : 0.46,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final p   = products[i];
                    final id  = (p['_id'] ?? p['id'] ?? '').toString();

                    if (grid == GridMode.two) {
                      return SmallTile(
                        p: p,
                        onTap: () => Get.to(
                          () => ProductDetailPage(key: ValueKey(id), productId: id),
                          binding: ProductDetailBinding(id),
                        ),
                      );
                    }

                    final sources = _imagesFromProduct(p);
                    return InkWell(
                      onTap: () => Get.to(
                        () => ProductDetailPage(key: ValueKey(id), productId: id),
                        binding: ProductDetailBinding(id),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: _ResilientImage(sources: sources, fit: BoxFit.cover),
                      ),
                    );
                  },
                  childCount: products.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  /* ------------------------ FULL (Big + 2-up) feed ------------------------ */

  List<Widget> _buildStaggeredBlocks(BuildContext context) {
    final out = <Widget>[];
    int i = 0;
    while (i < products.length) {
      // Big
      final p0 = products[i++];
      out.add(_BigTile(
        p: p0,
        onTap: () {
          final id = (p0['_id'] ?? p0['id'] ?? '').toString();
          Get.to(() => ProductDetailPage(key: ValueKey(id), productId: id),
              binding: ProductDetailBinding(id));
        },
      ));
      out.add(const SizedBox(height: 16));

      // Two-up row
      if (i < products.length) {
        final p1 = products[i++];
        final Map<String, dynamic>? item2 = (i < products.length) ? products[i++] : null;
        out.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 0.58,
                  child: SmallTile(
                    p: p1,
                    onTap: () {
                      final id = (p1['_id'] ?? p1['id'] ?? '').toString();
                      Get.to(() => ProductDetailPage(key: ValueKey(id), productId: id),
                          binding: ProductDetailBinding(id));
                    },
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: (item2 == null)
                    ? const SizedBox.shrink()
                    : AspectRatio(
                        aspectRatio: 0.58,
                        child: SmallTile(
                          p: item2,
                          onTap: () {
                            final id = (item2['_id'] ?? item2['id'] ?? '').toString();
                            Get.to(() => ProductDetailPage(key: ValueKey(id), productId: id),
                                binding: ProductDetailBinding(id));
                          },
                        ),
                      ),
              ),
            ],
          ),
        ));
        out.add(const SizedBox(height: 16));
      }
    }
    return out;
  }
}
class SwipeGallery extends StatefulWidget {
  const SwipeGallery({
    required this.sources,
    this.fit = BoxFit.cover,
    this.borderRadius = 2,
  });

  final List<String> sources;
  final BoxFit fit;
  final double borderRadius;

  @override
  State<SwipeGallery> createState() => SwipeGalleryState();
}

class SwipeGalleryState extends State<SwipeGallery> {
  late final PageController _pc;

  @override
  void initState() {
    super.initState();
    _pc = PageController();
    // pre-cache the next image
    WidgetsBinding.instance.addPostFrameCallback((_) => _precacheNext(0));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _precacheNext(int i) {
    if (!mounted) return;
    final next = i + 1;
    if (next < widget.sources.length) {
      precacheImage(NetworkImage(widget.sources[next]), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.sources;
    if (urls.length <= 1) {
      // Single image: just show it
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: _ResilientImage(sources: urls, fit: widget.fit),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          
          PageView.builder(
            controller: _pc,
            physics: const BouncingScrollPhysics(),
            itemCount: urls.length,
            onPageChanged: (i) {
              _precacheNext(i);
            },
            itemBuilder: (_, i) =>
                _ResilientImage(sources: [urls[i]], fit: widget.fit),
          ),
          // tiny dot indicator (bottom-center)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(urls.length, (i) {
              
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

int pow10(int n) => List.filled(n, 0).fold(1, (a, _) => a * 10);

String _priceTextFrom(Map p) {
  final m = (p['prices'] as Map?) ?? {};
  final raw = m['price']?.toString();
  if (raw != null && raw.isNotEmpty) {
    final minor = (m['currency_minor_unit'] as int?) ?? 2;
    final sym   = (m['currency_symbol']?.toString() ?? '₹');
    final value = (double.tryParse(raw) ?? 0) / (pow10(minor));
    final fmt   = NumberFormat.decimalPattern();
    final res   = '$sym${fmt.format(value)}';
    return res.replaceFirst(RegExp(r'\.00$'), '').replaceAll('.00', '');
  }

  final directPrice = p['price'] ?? p['salePrice'] ?? p['regularPrice'] ?? p['discountPrice'];
  if (directPrice != null && directPrice.toString().isNotEmpty) {
    var pStr = directPrice.toString().trim();
    if (pStr.endsWith('.00')) pStr = pStr.substring(0, pStr.length - 3);
    final d = double.tryParse(pStr);
    if (d != null && d == d.toInt()) pStr = d.toInt().toString();
    final clean = pStr.replaceFirst(RegExp(r'\.00$'), '').replaceAll('.00', '');
    if (clean.isNotEmpty && clean != '0') {
      return '₹$clean';
    }
  }

  final html = (p['price_html'] ?? p['priceHtml'])?.toString() ?? '';
  var s = html.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ');
  s = s.replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m[1]!)));
  s = s.replaceFirstMapped(RegExp(r'^([^\d\s]+)(\d)'), (m) => '${m[1]} ${m[2]}');
  return s.trim().replaceFirst(RegExp(r'\.00$'), '').replaceAll('.00', '');
}

/* =============================== Tiles =============================== */
List<String> _imagesFromProduct(Map<String, dynamic> p, {String? targetColor}) {
  final imgs = (p['images'] as List? ?? []);
  final urls = <String>[];

  if (targetColor != null && targetColor.trim().isNotEmpty) {
    final tc = targetColor.trim().toLowerCase();
    final colorRegex = RegExp(r'\b' + RegExp.escape(tc) + r'\b', caseSensitive: false);

    // 1. Check gallery images matching targetColor
    for (final m in imgs) {
      String? rawSrc;
      if (m is Map) {
        rawSrc = (m['imageUrl'] ?? m['url'] ?? m['src'] ?? m['thumbnail'])?.toString();
      } else if (m != null) {
        rawSrc = m.toString();
      }
      final u = _sanitizeUrl(rawSrc);
      if (u != null && u.isNotEmpty && colorRegex.hasMatch(u) && !urls.contains(u)) {
        urls.add(u);
      }
    }
    // 2. Check thumbnail matching targetColor
    final thumb = _sanitizeUrl((p['thumbnail'] ?? p['thumbnailImage'] ?? p['featuredImage'] ?? p['image'])?.toString());
    if (thumb != null && thumb.isNotEmpty && colorRegex.hasMatch(thumb) && !urls.contains(thumb)) {
      urls.add(thumb);
    }
  }

  // 1. Extract from thumbnail / thumbnailImage / featuredImage first if available
  final thumb = _sanitizeUrl((p['thumbnail'] ?? p['thumbnailImage'] ?? p['featuredImage'] ?? p['image'])?.toString());
  if (thumb != null && thumb.isNotEmpty && !urls.contains(thumb)) {
    urls.add(thumb);
  }

  // 2. Extract from images array
  for (final m in imgs) {
    String? rawSrc;
    if (m is Map) {
      rawSrc = (m['imageUrl'] ?? m['url'] ?? m['src'] ?? m['thumbnail'])?.toString();
    } else if (m != null) {
      rawSrc = m.toString();
    }
    final u = _sanitizeUrl(rawSrc);
    if (u != null && u.isNotEmpty && !urls.contains(u)) {
      urls.add(u);
    }
  }

  // Fallbacks if the product has 0 images
  if (urls.isEmpty) {
    final name = (p['name'] as String? ?? 'item');
    urls.addAll(_imageCandidates(primary: '', seed: name));
  }
  return urls;
}
class _BigTile extends StatelessWidget {
  const _BigTile({required this.p, this.onTap});
  final Map<String, dynamic> p;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = (HtmlDecode.text(p['name']) as String? ?? '').trim();
    final priceText = _priceTextFrom(p);
    final sources = _imagesFromProduct(p);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              InkWell(
                onTap: onTap,
                child: SwipeGallery(
                  sources: sources,
                  fit: BoxFit.cover,
                  borderRadius: 4,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: WishButton(
                  id: (p['_id'] ?? p['id'] ?? '').toString(),
                  name: name,
                  image: sources.isNotEmpty ? sources.first : null,
                  size: 22,
                  activeColor: Colors.redAccent,
                  inactiveColor: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: .3,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                priceText,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: .3,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _canonicalColorName(String name) {
  final lower = name.toLowerCase().trim();
  if (lower.isEmpty) return 'grey';

  if (lower.contains('black') || lower.contains('charcoal')) return 'black';
  if (lower.contains('white') || lower.contains('off white') || lower.contains('off-white') || lower.contains('cream') || lower.contains('ivory')) return 'white';
  if (lower.contains('grey') || lower.contains('gray') || lower.contains('silver') || lower.contains('slate')) return 'grey';
  if (lower.contains('beige') || lower.contains('nude') || lower.contains('sand')) return 'beige';
  if (lower.contains('brown') || lower.contains('chocolate') || lower.contains('tan') || lower.contains('camel')) return 'brown';
  if (lower.contains('navy') || lower.contains('dark blue')) return 'navy';
  if (lower.contains('blue') || lower.contains('sky') || lower.contains('cyan') || lower.contains('denim')) return 'blue';
  if (lower.contains('green') || lower.contains('emerald') || lower.contains('teal') || lower.contains('mint') || lower.contains('pista') || lower.contains('olive')) return 'green';
  if (lower.contains('red') || lower.contains('maroon') || lower.contains('burgundy') || lower.contains('wine') || lower.contains('rust')) return 'red';
  if (lower.contains('pink') || lower.contains('rose') || lower.contains('blush') || lower.contains('peach') || lower.contains('fuchsia')) return 'pink';
  if (lower.contains('yellow') || lower.contains('mustard') || lower.contains('gold') || lower.contains('lemon')) return 'yellow';
  if (lower.contains('orange') || lower.contains('coral')) return 'orange';
  if (lower.contains('purple') || lower.contains('violet') || lower.contains('lavender') || lower.contains('plum')) return 'purple';
  if (lower.contains('multi') || lower.contains('print') || lower.contains('pattern') || lower.contains('stripe')) return 'multi';

  return lower;
}

Color _colorFromName(String name) {
  final lower = name.toLowerCase().trim();
  if (lower.isEmpty) return const Color(0xFFD1D5DB);

  if (lower == 'black' || lower.contains('black') || lower.contains('charcoal')) {
    return const Color(0xFF000000);
  }
  if (lower == 'white' || lower.contains('white') || lower.contains('off white') || lower.contains('off-white')) {
    return const Color(0xFFFFFFFF);
  }
  if (lower == 'grey' || lower.contains('grey') || lower.contains('gray') || lower.contains('silver')) {
    return const Color(0xFF9CA3AF);
  }
  if (lower == 'beige' || lower.contains('beige') || lower.contains('cream') || lower.contains('ivory') || lower.contains('nude')) {
    return const Color(0xFFF6F4E8);
  }
  if (lower == 'brown' || lower.contains('brown') || lower.contains('chocolate') || lower.contains('tan') || lower.contains('camel')) {
    return const Color(0xFF78350F);
  }
  if (lower == 'blue' || lower == 'sky blue' || lower.contains('light blue')) {
    return const Color(0xFF3B82F6);
  }
  if (lower == 'navy' || lower.contains('navy') || lower.contains('dark blue')) {
    return const Color(0xFF1D3557);
  }
  if (lower == 'green' || lower.contains('green') || lower.contains('emerald') || lower.contains('teal') || lower.contains('mint') || lower.contains('pista') || lower.contains('olive')) {
    return const Color(0xFF10B981);
  }
  if (lower == 'red' || lower.contains('red') || lower.contains('maroon') || lower.contains('burgundy') || lower.contains('wine') || lower.contains('rust')) {
    return const Color(0xFFEF4444);
  }
  if (lower == 'pink' || lower.contains('pink') || lower.contains('rose') || lower.contains('blush') || lower.contains('peach') || lower.contains('fuchsia')) {
    return const Color(0xFFEC4899);
  }
  if (lower == 'yellow' || lower.contains('yellow') || lower.contains('mustard') || lower.contains('gold') || lower.contains('lemon')) {
    return const Color(0xFFFBBF24);
  }
  if (lower.contains('orange') || lower.contains('coral')) {
    return const Color(0xFFF97316);
  }
  if (lower.contains('purple') || lower.contains('violet') || lower.contains('lavender') || lower.contains('plum')) {
    return const Color(0xFFA855F7);
  }
  if (lower.contains('multi') || lower.contains('print') || lower.contains('pattern') || lower.contains('stripe')) {
    return const Color(0xFF6366F1);
  }

  final int hash = lower.hashCode.abs();
  final double hue = (hash % 360).toDouble();
  return HSLColor.fromAHSL(1.0, hue, 0.65, 0.55).toColor();
}

Color _parseColorSwatch(String name) {
  return _colorFromName(name);
}



class _ColorSwatchData {
  final String name;
  final String? image;
  final Color color;

  const _ColorSwatchData({required this.name, this.image, required this.color});
}

List<_ColorSwatchData> _extractColorsFromProductMap(Map<String, dynamic> p) {
  final List<_ColorSwatchData> result = [];
  final Map<String, _ColorSwatchData> mapBySlug = {};

  void addOrUpdateSwatch(String nameStr, [String? rawImg, String? hexColor]) {
    final cleanName = nameStr.trim();
    if (cleanName.isEmpty) return;
    final slug = cleanName.toLowerCase();

    String? fullImg;
    if (rawImg != null && rawImg.trim().isNotEmpty) {
      fullImg = ApiConstant.getImageUrl(rawImg.trim());
    }

    Color colorVal = Colors.transparent;
    if (hexColor != null && hexColor.trim().isNotEmpty) {
      colorVal = guessColor(hexColor) ?? guessColor(cleanName) ?? const Color(0xFF9CA3AF);
    } else {
      colorVal = guessColor(cleanName) ?? const Color(0xFF9CA3AF);
    }

    if (mapBySlug.containsKey(slug)) {
      final existing = mapBySlug[slug]!;
      if ((existing.image == null || existing.image!.isEmpty) && fullImg != null && fullImg.isNotEmpty) {
        final updated = _ColorSwatchData(name: existing.name, image: fullImg, color: existing.color);
        mapBySlug[slug] = updated;
        final idx = result.indexWhere((e) => e.name.trim().toLowerCase() == slug);
        if (idx != -1) result[idx] = updated;
      }
      return;
    }

    final swatch = _ColorSwatchData(name: cleanName, image: fullImg, color: colorVal);
    mapBySlug[slug] = swatch;
    result.add(swatch);
  }

  // 1. Check colorSwatches / swatches FIRST (stores admin custom fabric/color images)
  final swatches = (p['colorSwatches'] as List?) ?? (p['swatches'] as List?) ?? const [];
  for (final s in swatches) {
    if (s is Map) {
      final name = (s['color'] ?? s['name'] ?? s['label'] ?? s['title'])?.toString();
      final img = (s['image'] ?? s['imageUrl'] ?? s['photo'] ?? s['swatch'] ?? s['src'] ?? s['icon'])?.toString();
      final hex = (s['hex'] ?? s['code'] ?? s['colorCode'] ?? s['value'])?.toString();
      if (name != null) addOrUpdateSwatch(name, img, hex);
    }
  }

  // 2. Direct colors list (strings or maps)
  final cols = (p['colors'] as List?) ?? const [];
  for (final c in cols) {
    if (c is Map) {
      final name = (c['name'] ?? c['color'] ?? c['label'] ?? c['title'])?.toString();
      final img = (c['image'] ?? c['imageUrl'] ?? c['photo'] ?? c['swatch'] ?? c['src'] ?? c['icon'])?.toString();
      final hex = (c['hex'] ?? c['code'] ?? c['colorCode'] ?? c['value'])?.toString();
      if (name != null) addOrUpdateSwatch(name, img, hex);
    } else if (c != null) {
      addOrUpdateSwatch(c.toString());
    }
  }

  // 3. Single color field
  if (p['color'] is String && (p['color'] as String).trim().isNotEmpty) {
    for (final splitted in (p['color'] as String).split(',')) {
      addOrUpdateSwatch(splitted);
    }
  }

  // 4. Images list with color tags
  final imgs = (p['images'] as List?) ?? const [];
  for (final item in imgs) {
    if (item is Map && item['color'] != null) {
      final c = item['color'].toString().trim();
      final img = (item['imageUrl'] ?? item['url'] ?? item['src'] ?? item['image'])?.toString();
      addOrUpdateSwatch(c, img);
    }
  }

  // 5. Attributes
  final attrs = (p['attributes'] as List?) ?? const [];
  for (final a in attrs.whereType<Map>()) {
    final key = ((a['taxonomy'] ?? a['name'])?.toString() ?? '').toLowerCase();
    if (key.contains('color') || key == 'pa_color' || key.contains('colour')) {
      final terms = a['terms'] ?? a['options'] ?? a['options_json'] ?? a['value'];
      if (terms is List) {
        for (final t in terms) {
          if (t is Map) {
            final val = (t['name'] ?? t['value'] ?? t['label'] ?? '').toString();
            final img = (t['image'] ?? t['imageUrl'] ?? t['photo'] ?? t['swatch'] ?? t['src'] ?? t['icon'])?.toString();
            final hex = (t['hex'] ?? t['code'] ?? t['colorCode'] ?? t['value'] ?? t['color'])?.toString();
            addOrUpdateSwatch(val, img, hex);
          } else if (t != null) {
            addOrUpdateSwatch(t.toString());
          }
        }
      } else if (terms is String && terms.trim().isNotEmpty) {
        for (final s in terms.split(',')) {
          addOrUpdateSwatch(s);
        }
      }
    }
  }

  // 6. Variants
  final vars = (p['variants'] as List?) ?? (p['variations'] as List?) ?? const [];
  for (final v in vars.whereType<Map>()) {
    final c = (v['color'] ?? v['attributes']?['color'] ?? v['attributes']?['pa_color'])?.toString();
    final img = (v['image'] ?? v['imageUrl'] ?? v['thumbnail'])?.toString();
    final hex = (v['colorCode'] ?? v['hex'])?.toString();
    if (c != null) addOrUpdateSwatch(c, img, hex);
  }

  // 7. Title fallback
  if (result.isEmpty) {
    final name = (p['name'] ?? p['title'] ?? '').toString();
    final g = guessColor(name);
    if (g != null) {
      addOrUpdateSwatch(name);
    }
  }

  return result;
}

List<String> _extractProductColors(Map<String, dynamic> p) {
  final Set<String> colors = {};
  final swatches = (p['colorSwatches'] as List?) ?? (p['swatches'] as List?) ?? const [];
  for (final s in swatches) {
    if (s is Map) {
      final val = (s['color'] ?? s['name'] ?? s['label'] ?? s['title'])?.toString().trim();
      if (val != null && val.isNotEmpty) colors.add(val);
    }
  }
  if (p['color'] is String && (p['color'] as String).trim().isNotEmpty) {
    colors.addAll((p['color'] as String).split(',').map((e) => e.trim()));
  }
  if (p['colors'] is List) {
    for (final c in (p['colors'] as List)) {
      if (c is String && c.trim().isNotEmpty) colors.add(c.trim());
      else if (c is Map) {
        final val = (c['name'] ?? c['label'] ?? c['value'] ?? '').toString().trim();
        if (val.isNotEmpty) colors.add(val);
      }
    }
  }
  final attrs = (p['attributes'] as List?) ?? const [];
  for (final a in attrs.whereType<Map>()) {
    final key = ((a['taxonomy'] ?? a['name'])?.toString() ?? '').toLowerCase();
    if (key.contains('color') || key == 'pa_color' || key.contains('colour')) {
      final terms = a['terms'] ?? a['options'] ?? a['options_json'] ?? a['value'];
      if (terms is List) {
        for (final t in terms) {
          if (t is Map) {
            final val = (t['name'] ?? t['value'] ?? t['label'] ?? '').toString().trim();
            if (val.isNotEmpty) colors.add(val);
          } else if (t != null) {
            final val = t.toString().trim();
            if (val.isNotEmpty) colors.add(val);
          }
        }
      } else if (terms is String && terms.trim().isNotEmpty) {
        colors.addAll(terms.split(',').map((e) => e.trim()));
      }
    }
  }
  final vars = (p['variants'] as List?) ?? (p['variations'] as List?) ?? const [];
  for (final v in vars.whereType<Map>()) {
    final c = (v['color'] ?? v['attributes']?['color'] ?? v['attributes']?['pa_color'])?.toString();
    if (c != null && c.isNotEmpty) colors.add(c.trim());
  }
  return colors.where((c) => c.isNotEmpty).toList();
}

List<String> _extractProductSizes(Map<String, dynamic> p) {
  final Set<String> sizes = {};
  if (p['size'] is String && (p['size'] as String).trim().isNotEmpty) {
    sizes.addAll((p['size'] as String).split(',').map((e) => e.trim()));
  }
  if (p['sizes'] is List) {
    for (final c in (p['sizes'] as List)) {
      if (c is String && c.trim().isNotEmpty) sizes.add(c.trim());
      else if (c is Map) {
        final val = (c['name'] ?? c['label'] ?? c['value'] ?? '').toString().trim();
        if (val.isNotEmpty) sizes.add(val);
      }
    }
  }
  final attrs = (p['attributes'] as List?) ?? const [];
  for (final a in attrs.whereType<Map>()) {
    final key = ((a['taxonomy'] ?? a['name'])?.toString() ?? '').toLowerCase();
    if (key.contains('size') || key == 'pa_size') {
      final terms = a['terms'] ?? a['options'] ?? a['options_json'] ?? a['value'];
      if (terms is List) {
        for (final t in terms) {
          if (t is Map) {
            final val = (t['name'] ?? t['value'] ?? t['label'] ?? '').toString().trim();
            if (val.isNotEmpty) sizes.add(val);
          } else if (t != null) {
            final val = t.toString().trim();
            if (val.isNotEmpty) sizes.add(val);
          }
        }
      } else if (terms is String && terms.trim().isNotEmpty) {
        sizes.addAll(terms.split(',').map((e) => e.trim()));
      }
    }
  }
  final vars = (p['variants'] as List?) ?? (p['variations'] as List?) ?? const [];
  for (final v in vars.whereType<Map>()) {
    final s = (v['size'] ?? v['attributes']?['size'] ?? v['attributes']?['pa_size'])?.toString();
    if (s != null && s.isNotEmpty) sizes.add(s.trim());
  }
  return sizes.where((c) => c.isNotEmpty).toList();
}

class SmallTile extends StatelessWidget {
  const SmallTile({required this.p, this.onTap, this.targetColor});
  final Map<String, dynamic> p;
  final VoidCallback? onTap;
  final String? targetColor;

  @override
  Widget build(BuildContext context) {
    final name = (HtmlDecode.text(p['name']) as String? ?? '').trim();
    final priceText = _priceTextFrom(p);
    final sources = _imagesFromProduct(p, targetColor: targetColor);
    final colorSwatches = _extractColorsFromProductMap(p);
    String? firstImg = sources.isNotEmpty ? sources.first : null;
    if (firstImg != null && firstImg.isNotEmpty && !firstImg.startsWith('http')) {
      firstImg = 'https://backend.tobeque.com$firstImg';
    }

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image area
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                SwipeGallery(
                  sources: sources,
                  fit: BoxFit.cover,
                  borderRadius: 0,
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: WishButton(
                    id: (p['_id'] ?? p['id'] ?? '').toString(),
                    name: name,
                    image: firstImg,
                    size: 20,
                    activeColor: Colors.redAccent,
                    inactiveColor: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          
          // Title, Price & Colors text
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    letterSpacing: 0.5,
                    fontSize: 11,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (priceText.isNotEmpty)
                      Expanded(
                        child: Text(
                          priceText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                            letterSpacing: .2,
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    if (colorSwatches.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...colorSwatches.take(4).map((swatchData) {
                            final bool hasImage = swatchData.image != null && swatchData.image!.isNotEmpty;
                            final Color swatchColor = swatchData.color;
                            final bool isLight = swatchColor == const Color(0xFFFFFFFF) || swatchColor == const Color(0xFFFAFAFA);

                            return Container(
                              margin: const EdgeInsets.only(left: 3),
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isLight ? Colors.black38 : Colors.black12,
                                  width: 1,
                                ),
                                color: hasImage ? Colors.white : swatchColor,
                              ),
                              child: ClipOval(
                                child: hasImage
                                    ? CachedNetworkImage(
                                        imageUrl: swatchData.image!,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => ColoredBox(color: swatchColor),
                                        errorWidget: (_, __, ___) => ColoredBox(color: swatchColor),
                                      )
                                    : null,
                              ),
                            );
                          }),
                          if (colorSwatches.length > 4)
                            Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: Text(
                                '+${colorSwatches.length - 4}',
                                style: const TextStyle(fontSize: 9, color: Colors.black54, fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


/* ----------------------------- Toolbar icon ----------------------------- */

class _ToolbarIcon extends StatelessWidget {
  const _ToolbarIcon({required this.icon, this.selected = false});
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = selected ? Colors.black : const Color(0xFF9E9E9E);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEAEAEA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: c),
    );
  }
}

/* ----------------------------- Promo bar ----------------------------- */

class _PromoBar extends StatelessWidget {
  const _PromoBar({required this.text, required this.action, this.onTap});
  final String text;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        color: Colors.black,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(text,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .4)),
                const SizedBox(width: 10),
                Text(action,
                    style: const TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* -------------------------- Resilient image -------------------------- */

class _ResilientImage extends StatefulWidget {
  const _ResilientImage({required this.sources, this.fit = BoxFit.cover});
  final List<String> sources;
  final BoxFit fit;

  @override
  State<_ResilientImage> createState() => _ResilientImageState();
}

class _ResilientImageState extends State<_ResilientImage> {
  @override
  Widget build(BuildContext context) {
    if (widget.sources.isEmpty) {
      return const ColoredBox(color: Color(0xfff2f2f2));
    }
    final url = widget.sources.firstWhere(
      (s) => s.isNotEmpty && s.startsWith('http'),
      orElse: () => '',
    );
    if (url.isEmpty) {
      return const ColoredBox(color: Color(0xfff2f2f2));
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: widget.fit,
      memCacheWidth: 450,
      placeholder: (ctx, _) => const ShimmerWave(
        period: Duration(milliseconds: 2200),
        direction: ShineDirection.diagonal,
        tiltDegrees: 20,
        child: ColoredBox(color: Color(0xFFEDEDED)),
      ),
      errorWidget: (_, __, ___) => const ColoredBox(
        color: Color(0xfff2f2f2),
        child: Icon(Icons.image_not_supported_outlined, color: Colors.black26, size: 24),
      ),
    );
  }
}

/* ----------------------------- Error box ----------------------------- */

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            Text('Something went wrong',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            )
          ],
        ),
      ),
    );
  }
}

/* --------------------- formatting + images helpers --------------------- */

String? _sanitizeUrl(String? u) {
  if (u == null || u.isEmpty) return null;
  var x = u.trim().replaceAll(' ', '%20');
  if (x.startsWith('http://')) x = x.replaceFirst('http://', 'https://');
  if (!x.startsWith('http')) return ApiConstant.getImageUrl(x);
  return x;
}

List<String> _imageCandidates({required String primary, required String seed}) {
  final list = <String>[];
  final p = _sanitizeUrl(primary);
  if (p != null && p.isNotEmpty) list.add(p);
  return list;
}

/* -------------------------- Page Skeleton (shimmer) -------------------------- */

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          centerTitle: false,
          title: ShimmerWave.box(
              width: 120, height: 20, radius: BorderRadius.circular(4)),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                _iconSkeleton(),
                const SizedBox(width: 8),
                _iconSkeleton(),
                const SizedBox(width: 8),
                _iconSkeleton(),
                const Spacer(),
                ShimmerWave.box(
                    width: 100, height: 16, radius: BorderRadius.circular(4)),
                const SizedBox(width: 8),
                _iconSkeleton(),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: _BigCardSkeleton()),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: .53,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, __) => const _ProductCardSkeleton(),
              childCount: 2,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: _BigCardSkeleton()),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _iconSkeleton() =>
      Padding(padding: const EdgeInsets.all(2), child: ShimmerWave.circle(size: 32));
}

class _BigCardSkeleton extends StatelessWidget {
  const _BigCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: const ShimmerWave(
                period: Duration(milliseconds: 1800),
                direction: ShineDirection.diagonal,
                tiltDegrees: 20,
                child: ColoredBox(color: Color(0xFFEDEDED)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ShimmerWave.box(
              width: 160, height: 16, radius: BorderRadius.circular(4)),
          const SizedBox(height: 6),
          ShimmerWave.box(
              width: 90, height: 16, radius: BorderRadius.circular(4)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: const ShimmerWave(
              period: Duration(milliseconds: 1800),
              direction: ShineDirection.diagonal,
              tiltDegrees: 20,
              child: ColoredBox(color: Color(0xFFEDEDED)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ShimmerWave.box(
            width: double.infinity,
            height: 14,
            radius: BorderRadius.circular(4)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ShimmerWave.box(
                  width: 110, height: 14, radius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 8),
            ShimmerWave.circle(size: 28),
          ],
        ),
      ],
    );
  }
}
