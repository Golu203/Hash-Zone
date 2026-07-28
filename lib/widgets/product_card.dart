import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/catalog_provider.dart';
import 'cloudinary_image_widget.dart';
import 'whatsapp_button.dart';
import 'context_menu_wrapper.dart';

/// Canonical size order: letter sizes first (XS→3XL), then Free Size, then numeric ascending.
const _kSizeOrder = [
  'XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', 'Free Size',
];

List<String> _sortedSizes(List<String> sizes) {
  final copy = List<String>.from(sizes);
  copy.sort((a, b) {
    final ai = _kSizeOrder.indexOf(a);
    final bi = _kSizeOrder.indexOf(b);
    final aIsLetter = ai != -1;
    final bIsLetter = bi != -1;

    if (aIsLetter && bIsLetter) return ai.compareTo(bi);   // both letter sizes
    if (aIsLetter) return -1;  // letter sizes come first
    if (bIsLetter) return 1;

    // Both numeric — compare as integers
    final an = int.tryParse(a);
    final bn = int.tryParse(b);
    if (an != null && bn != null) return an.compareTo(bn);

    return a.compareTo(b); // fallback lexicographic
  });
  return copy;
}

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final catalog = Provider.of<CatalogProvider>(context, listen: false);
    final categoryName =
        catalog.getCategoryById(widget.product.categoryId)?.name ?? 'Premium';
    final currencyFormatter =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final coverImg = widget.product.coverImage;

    return HZContextMenuWrapper(
      imageUrl: widget.product.coverImageUrl,
      productTitle: widget.product.title,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFF111111)
                  : const Color(0xFFE0E0E0),
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04),
                blurRadius: _isHovered ? 18 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              onTap: () => context.go('/product/${widget.product.slug}'),
              // Use LayoutBuilder to get actual card width for responsive sizing
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // isSmall based on actual card pixel width, not screen width
                  final cardW = constraints.maxWidth;
                  final isSmall = cardW < 240;

                  final hPad = isSmall ? 8.0 : 13.0;
                  final vPadTop = isSmall ? 7.0 : 10.0;
                  // Extra bottom padding so button never touches card boundary
                  final vPadBottom = isSmall ? 10.0 : 14.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Product Image (3:4 portrait) ───────────────────────
                      AspectRatio(
                        aspectRatio: 3 / 4,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              color: const Color(0xFFF8F8F9),
                              child: coverImg != null
                                  ? CloudinaryImageWidget(
                                      imageSource: coverImg,
                                      fit: BoxFit.cover,
                                      altText:
                                          '${widget.product.title} - Wholesale Garment Manufacturer Tiruppur HASH ZONE',
                                    )
                                  : const Center(
                                      child: Icon(Icons.image_outlined,
                                          size: 40,
                                          color: Color(0xFFBBBBBB)),
                                    ),
                            ),
                            const Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFE5E5E5),
                              ),
                            ),
                            if (widget.product.isOffer)
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD32F2F),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'SALE',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // ── Info Block: fills remaining card height ────────────
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                              hPad, vPadTop, hPad, vPadBottom),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category badge + SKU
                              Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F0F2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        categoryName.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.6,
                                          color: const Color(0xFF444444),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      widget.product.sku,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 8,
                                        color: const Color(0xFF999999),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: isSmall ? 4 : 6),

                              // Product title — always 1 line
                              Text(
                                widget.product.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: isSmall ? 14 : 19,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF111111),
                                ),
                              ),

                              SizedBox(height: isSmall ? 2 : 4),

                              // ── Price — FIXED HEIGHT keeps all cards aligned ─
                              SizedBox(
                                height: isSmall ? 26 : 32,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (widget.product.isOffer &&
                                        widget.product.offerPrice != null &&
                                        widget.product.offerPrice! > 0) ...[
                                      Text(
                                        currencyFormatter.format(
                                            widget.product.offerPrice!),
                                        style: GoogleFonts.inter(
                                          fontSize: isSmall ? 11 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFD32F2F),
                                        ),
                                      ),
                                      if (widget.product.price
                                          .trim()
                                          .isNotEmpty)
                                        Text(
                                          widget.product.price,
                                          style: GoogleFonts.inter(
                                            fontSize: 8,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: const Color(0xFF999999),
                                          ),
                                        ),
                                    ] else if (widget.product.price
                                        .trim()
                                        .isNotEmpty) ...[
                                      Text(
                                        widget.product.price,
                                        style: GoogleFonts.inter(
                                          fontSize: isSmall ? 11 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF111111),
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        'Price on Inquiry',
                                        style: GoogleFonts.inter(
                                          fontSize: isSmall ? 10 : 12,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF888888),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              SizedBox(height: isSmall ? 2 : 4),

                              // ── Sizes — ALL sizes shown sorted small→big ────
                              Wrap(
                                spacing: isSmall ? 2 : 4,
                                runSpacing: isSmall ? 2 : 3,
                                children: (_sortedSizes(
                                            widget.product.availableSizes
                                                .isNotEmpty
                                        ? widget.product.availableSizes
                                        : ['Free Size']))
                                    .map(
                                      (s) => Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isSmall ? 4 : 6,
                                          vertical: isSmall ? 1 : 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0F0F2),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          s,
                                          style: GoogleFonts.inter(
                                            fontSize: isSmall ? 7.5 : 9,
                                            color: const Color(0xFF555555),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),

                              // Spacer pushes button to bottom — stays INSIDE card
                              const Spacer(),

                              // ── WhatsApp Inquiry Button ─────────────────────
                              _CompactInquiryButton(
                                product: widget.product,
                                isSmall: isSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact inquiry button sized for the card context
class _CompactInquiryButton extends StatelessWidget {
  final Product product;
  final bool isSmall;

  const _CompactInquiryButton({
    required this.product,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return WhatsAppInquiryButton(
      product: product,
      isFullWidth: true,
      compact: isSmall,
    );
  }
}
