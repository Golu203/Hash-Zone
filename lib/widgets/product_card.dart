import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/catalog_provider.dart';
import '../providers/business_provider.dart';
import '../providers/cart_provider.dart';
import 'product_action_dialog.dart';
import 'cloudinary_image_widget.dart';
import 'context_menu_wrapper.dart';
import 'quantity_stepper.dart';

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
              color: _isHovered ? const Color(0xFF111111) : const Color(0xFFE0E0E0),
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04),
                blurRadius: _isHovered ? 18 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              onTap: () => context.go('/product/${widget.product.slug}'),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardW = constraints.maxWidth;
                  final isSmall = cardW < 240;
                  final hPad = isSmall ? 8.0 : 12.0;
                  final vPad = isSmall ? 8.0 : 12.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Product Image (3:4 portrait) ────────────────────────
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
                                          '${widget.product.title} - Wholesale Garment Tiruppur HASH ZONE',
                                    )
                                  : const Center(
                                      child: Icon(Icons.image_outlined,
                                          size: 40, color: Color(0xFFBBBBBB)),
                                    ),
                            ),
                            const Positioned(
                              left: 0, right: 0, bottom: 0,
                              child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E5E5)),
                            ),
                            if (widget.product.isOffer)
                              Positioned(
                                top: 10, left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD32F2F),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text('SALE',
                                    style: GoogleFonts.inter(
                                      fontSize: 9, fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0, color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // ── Info Block ──────────────────────────────────────────
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top: Category + SKU + Title + Price
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category badge + SKU row
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0F0F2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            categoryName.toUpperCase(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: 7, fontWeight: FontWeight.bold,
                                              letterSpacing: 0.6, color: const Color(0xFF444444),
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
                                          style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF999999)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isSmall ? 4 : 6),

                                  // Product title
                                  Text(
                                    widget.product.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cormorantGaramond(
                                      fontSize: isSmall ? 14 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF111111),
                                    ),
                                  ),
                                  SizedBox(height: isSmall ? 4 : 6),

                                  // ── Compact price + sizes (no overflow) ────
                                  _CompactPriceLine(product: widget.product, isSmall: isSmall),
                                ],
                              ),

                              // Bottom: Add to cart button
                              _CompactInquiryButton(product: widget.product, isSmall: isSmall),
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

/// Ultra-compact single-line price + sizes for use inside a product card.
/// Shows: ₹1000 / bundle  ·  M · L · XL
/// or just the price text for legacy products.
class _CompactPriceLine extends StatelessWidget {
  final Product product;
  final bool isSmall;
  const _CompactPriceLine({required this.product, required this.isSmall});

  @override
  Widget build(BuildContext context) {
    if (product.hasBundle) {
      final b = product.bundle!;
      final priceStyle = GoogleFonts.inter(
        fontSize: isSmall ? 12 : 14,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF111111),
      );
      final labelStyle = GoogleFonts.inter(
        fontSize: isSmall ? 9 : 10,
        color: const Color(0xFF888888),
      );
      final sizeStyle = GoogleFonts.inter(
        fontSize: isSmall ? 9 : 10,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF333333),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price row: ₹1000 / bundle
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(b.priceLabel, style: priceStyle),
              const SizedBox(width: 3),
              Text('/ bundle', style: labelStyle),
            ],
          ),
          if (b.sizes.isNotEmpty) ...[
            const SizedBox(height: 4),
            // Sizes as compact chips in a Wrap (never overflows)
            Wrap(
              spacing: 4,
              runSpacing: 3,
              children: b.sizes.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                child: Text(s, style: sizeStyle),
              )).toList(),
            ),
          ],
        ],
      );
    }

    // Legacy: just show the price string
    return Text(
      product.displayPrice,
      style: GoogleFonts.inter(
        fontSize: isSmall ? 12 : 14,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF111111),
      ),
    );
  }
}


/// Compact add-to-cart button sized for the card context.
/// For bundle products: directly adds 1 bundle to cart with no popup.
/// Shows inline +/- stepper once in cart. Step = 1, min = 1.
class _CompactInquiryButton extends StatelessWidget {
  final Product product;
  final bool isSmall;

  const _CompactInquiryButton({
    required this.product,
    required this.isSmall,
  });

  void _directAddToCart(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (product.hasBundle) {
      final b = product.bundle!;
      cart.addItem(
        product,
        b.bundleName,
        b.bundlePrice,
        1,
        bundleName: b.bundleName,
        bundleSizes: b.sizes,
        totalPiecesPerBundle: b.totalPieces,
        piecesPerSize: b.piecesPerSize,
      );
    } else {
      // Legacy product — add with free size
      final size = product.availableSizes.isNotEmpty
          ? product.availableSizes.first
          : 'Free Size';
      cart.addItem(product, size, product.getActivePriceForSize(size), 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = Provider.of<BusinessProvider>(context);
    final cart = Provider.of<CartProvider>(context);

    // ── Cart DISABLED: show WhatsApp Inquire button only ─────────────────────
    if (!business.settings.enableShoppingCart) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () =>
              HZProductActionDialog.show(context, product: product, isWhatsApp: true),
          icon: const Icon(Icons.chat_outlined, color: Colors.white, size: 14),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            elevation: 0,
          ),
          label: Text(
            'INQUIRE',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, fontSize: isSmall ? 10 : 12),
          ),
        ),
      );
    }

    // ── Cart ENABLED: show stepper if already in cart ─────────────────────────
    final int cartQty = cart.getProductTotalQuantity(product.id);
    if (cartQty > 0) {
      return HZQuantityStepper(
        product: product,
        initialValue: cartQty,
        height: isSmall ? 28 : 36,
        isSmall: isSmall,
        isFullWidth: true,
        showNote: false,
        step: 1,
        minValue: 1,
      );
    }

    // ── ADD TO CART button (no popup) ─────────────────────────────────────────
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _directAddToCart(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
        ),
        child: Text(
          'ADD TO CART',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: isSmall ? 9 : 11,
          ),
        ),
      ),
    );
  }
}
