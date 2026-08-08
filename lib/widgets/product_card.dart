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
import 'size_price_table.dart';
import 'quantity_stepper.dart';
import 'manage_cart_dialog.dart';

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

                              const SizedBox(height: 4),

                              HZSizePriceTable(
                                product: widget.product,
                                isSmall: isSmall,
                              ),

                              // Spacer pushes button to bottom — stays INSIDE card
                              const Spacer(),

                              // ── Buy Now Button ────────────────────────────
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
    final business = Provider.of<BusinessProvider>(context);
    final cart = Provider.of<CartProvider>(context);

    // ── Cart DISABLED by admin: show only the Inquire button ─────────────────
    if (!business.settings.enableShoppingCart) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => HZProductActionDialog.show(context, product: product, isWhatsApp: true),
          icon: const Icon(Icons.chat_outlined, color: Colors.white, size: 14),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            elevation: 0,
          ),
          label: Text(
            'INQUIRE',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: isSmall ? 10 : 12),
          ),
        ),
      );
    }

    // ── Cart ENABLED: show quantity stepper if item already in cart ───────────
    final int cartQty = cart.getProductTotalQuantity(product.id);
    if (cartQty > 0) {
      return GestureDetector(
        onTap: () => HZManageCartDialog.show(context, product: product),
        child: AbsorbPointer(
          child: HZQuantityStepper(
            product: product,
            initialValue: cartQty,
            height: isSmall ? 28 : 36,
            isSmall: isSmall,
            isFullWidth: true,
            showNote: false,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => HZProductActionDialog.show(
              context,
              product: product,
              isWhatsApp: false,
              isBuyNow: true,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 0,
            ),
            child: Text(
              'BUY NOW',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: isSmall ? 9 : 11,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: OutlinedButton(
            onPressed: () => HZProductActionDialog.show(
              context,
              product: product,
              isWhatsApp: false,
              isBuyNow: false,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black, width: 1.0),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 0,
            ),
            child: Text(
              'ADD TO CART',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: isSmall ? 8 : 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
