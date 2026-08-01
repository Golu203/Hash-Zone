import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';

class HZSizePriceTable extends StatefulWidget {
  final Product product;
  final bool isSmall;
  final bool isScrollable;

  const HZSizePriceTable({
    super.key,
    required this.product,
    this.isSmall = false,
    this.isScrollable = true,
  });

  @override
  State<HZSizePriceTable> createState() => _HZSizePriceTableState();
}

class _HZSizePriceTableState extends State<HZSizePriceTable> {
  late ScrollController _scrollController;
  bool _showScrollIndicator = false;

  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  static const _kSizeOrder = [
    'XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', 'Free Size',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollable();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HZSizePriceTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollable();
    });
  }

  bool _canScrollUp = false;
  bool _canScrollDown = false;

  void _onScroll() {
    _checkScrollable();
  }

  void _checkScrollable() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    
    final canUp = currentScroll > 0.5;
    final canDown = maxScroll > 0 && currentScroll < maxScroll - 0.5;
    final canScrollIndicator = maxScroll > 0 && currentScroll < maxScroll - 4.0;

    if (_canScrollUp != canUp || _canScrollDown != canDown || _showScrollIndicator != canScrollIndicator) {
      setState(() {
        _canScrollUp = canUp;
        _canScrollDown = canDown;
        _showScrollIndicator = canScrollIndicator;
      });
    }
  }

  List<String> _sortedSizes(List<String> sizes) {
    final copy = List<String>.from(sizes);
    copy.sort((a, b) {
      final ai = _kSizeOrder.indexOf(a);
      final bi = _kSizeOrder.indexOf(b);
      if (ai != -1 && bi != -1) return ai.compareTo(bi);
      if (ai != -1) return -1;
      if (bi != -1) return 1;

      final an = double.tryParse(a.replaceAll(RegExp(r'[^\d.]'), ''));
      final bn = double.tryParse(b.replaceAll(RegExp(r'[^\d.]'), ''));
      if (an != null && bn != null) return an.compareTo(bn);
      if (an != null) return -1;
      if (bn != null) return 1;
      return a.compareTo(b);
    });
    return copy;
  }

  String getSizePriceString(String size) {
    return widget.product.getPriceLabelForSize(size);
  }

  @override
  Widget build(BuildContext context) {
    final sizesList = widget.product.availableSizes.isNotEmpty
        ? widget.product.availableSizes
        : ['Free Size'];
    final sortedSizesList = _sortedSizes(sizesList);
    final isSmall = widget.isSmall;

    if (!widget.isScrollable) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9FA),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sticky Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: const Color(0xFFEEEEEE),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SIZE',
                    style: GoogleFonts.inter(
                      fontSize: isSmall ? 8 : 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF555555),
                    ),
                  ),
                  Text(
                    'PRICE',
                    style: GoogleFonts.inter(
                      fontSize: isSmall ? 8 : 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF555555),
                    ),
                  ),
                ],
              ),
            ),
            // Expanded row list (no height bounds, no scrolling)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: sortedSizesList.map((s) {
                  final priceStr = getSizePriceString(s);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s,
                          style: GoogleFonts.inter(
                            fontSize: isSmall ? 9 : 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          priceStr,
                          style: GoogleFonts.inter(
                            fontSize: isSmall ? 9 : 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    }

    final bool isMobileDevice = Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.android;

    final double rowHeight = isSmall ? 15.0 : 18.5;

    void scrollUpOneRow() {
      if (!_scrollController.hasClients) return;
      final target = (_scrollController.offset - rowHeight).clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }

    void scrollDownOneRow() {
      if (!_scrollController.hasClients) return;
      final target = (_scrollController.offset + rowHeight).clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }

    final bool hasScrollExtent = _scrollController.hasClients && _scrollController.position.maxScrollExtent > 0;

    final Widget tableBody = Container(
      height: isSmall ? 64 : 76,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        children: [
          // Sticky Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: const Color(0xFFEEEEEE),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SIZE',
                  style: GoogleFonts.inter(
                    fontSize: isSmall ? 7.5 : 9,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF555555),
                  ),
                ),
                Text(
                  'PRICE',
                  style: GoogleFonts.inter(
                    fontSize: isSmall ? 7.5 : 9,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable rows
          Expanded(
            child: Stack(
              children: [
                Theme(
                  data: Theme.of(context).copyWith(
                    scrollbarTheme: ScrollbarThemeData(
                      thumbColor: WidgetStateProperty.all(Colors.transparent),
                      thickness: WidgetStateProperty.all(0.0),
                      trackColor: WidgetStateProperty.all(Colors.transparent),
                      trackVisibility: WidgetStateProperty.all(false),
                    ),
                  ),
                  child: Scrollbar(
                    thumbVisibility: false,
                    trackVisibility: false,
                    controller: _scrollController,
                    child: Listener(
                      onPointerSignal: (pointerSignal) {
                        if (pointerSignal is PointerScrollEvent) {
                          final double rawDelta = pointerSignal.scrollDelta.dy;
                          if (rawDelta != 0) {
                            if (!_scrollController.hasClients) return;
                            final double maxScroll = _scrollController.position.maxScrollExtent;
                            final double minScroll = _scrollController.position.minScrollExtent;

                            if (maxScroll > 0) {
                              final double currentOffset = _scrollController.offset;
                              final double scaledDelta = rawDelta * 0.06;
                              final double targetOffset = (currentOffset + scaledDelta).clamp(minScroll, maxScroll);

                              _scrollController.animateTo(
                                targetOffset,
                                duration: const Duration(milliseconds: 80),
                                curve: Curves.easeOut,
                              );

                              GestureBinding.instance.pointerSignalResolver.register(pointerSignal, (event) {});
                            }
                          }
                        }
                      },
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: isMobileDevice
                            ? const BouncingScrollPhysics()
                            : const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: Column(
                            children: sortedSizesList.map((s) {
                              final priceStr = getSizePriceString(s);

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      s,
                                      style: GoogleFonts.inter(
                                        fontSize: isSmall ? 8 : 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      priceStr,
                                      style: GoogleFonts.inter(
                                        fontSize: isSmall ? 8 : 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (hasScrollExtent) {
      return Row(
        children: [
          Expanded(child: tableBody),
          const SizedBox(width: 4),
          Container(
            height: isSmall ? 64 : 76,
            width: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5),
                    ),
                    onTap: _canScrollUp ? scrollUpOneRow : null,
                    child: Center(
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: 16,
                        color: _canScrollUp ? Colors.black : Colors.black26,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFD5D5D5), indent: 4, endIndent: 4),
                Expanded(
                  child: InkWell(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                    ),
                    onTap: _canScrollDown ? scrollDownOneRow : null,
                    child: Center(
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: _canScrollDown ? Colors.black : Colors.black26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return tableBody;
  }
}
