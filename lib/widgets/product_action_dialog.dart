import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/business_provider.dart';
import '../providers/catalog_provider.dart';
import '../providers/customer_auth_provider.dart';
import 'quantity_stepper.dart';
import 'customer_info_dialog.dart';

class HZProductActionDialog extends StatefulWidget {
  final Product product;
  final bool isWhatsApp;
  final bool isBuyNow;
  final BuildContext parentContext;

  const HZProductActionDialog({
    super.key,
    required this.product,
    required this.isWhatsApp,
    this.isBuyNow = false,
    required this.parentContext,
  });

  static Future<void> show(
    BuildContext context, {
    required Product product,
    required bool isWhatsApp,
    bool isBuyNow = false,
  }) {
    return showDialog(
      context: context,
      builder: (dialogContext) => HZProductActionDialog(
        product: product,
        isWhatsApp: isWhatsApp,
        isBuyNow: isBuyNow,
        parentContext: context,
      ),
    );
  }

  @override
  State<HZProductActionDialog> createState() => _HZProductActionDialogState();
}

class _HZProductActionDialogState extends State<HZProductActionDialog> {
  // For bundle orders: quantity = number of bundles (starts at 1)
  // For legacy (no bundle): quantity = pieces, starts at 5
  int _quantity = 1;
  bool _isQuantityValid = true;

  bool get _isBundle => widget.product.hasBundle;

  @override
  void initState() {
    super.initState();
    _quantity = _isBundle ? 1 : 5;
    _isQuantityValid = true;
  }

  Future<void> _handleWhatsAppSubmit(BuildContext context) async {
    final business = Provider.of<BusinessProvider>(context, listen: false);
    final catalog = Provider.of<CatalogProvider>(context, listen: false);
    final bundle = widget.product.bundle;

    final result = await HZCustomerInfoDialog.show(context);
    if (result == null) return;

    final rawNumber = business.settings.whatsAppNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final cleanWa = rawNumber.startsWith('+') ? rawNumber.substring(1) : rawNumber;

    final dept = catalog.getDepartmentById(widget.product.departmentId)?.name ?? 'Apparel';
    final cat = catalog.getCategoryById(widget.product.categoryId)?.name ?? 'Clothing';
    final productUrl = '${Uri.base.origin}/#/product/${widget.product.slug}';

    final customerName = result['name'] ?? '';
    final customerPhone = result['phone'] ?? '';
    final customerNote = result['note'] ?? '';

    final detailsBuffer = StringBuffer();
    detailsBuffer.writeln('🛍️ *PRODUCT INQUIRY - HASH ZONE*');
    detailsBuffer.writeln('──────────────────');
    detailsBuffer.writeln('👤 *Customer Details*');
    detailsBuffer.writeln('   • Name: ${customerName.trim()}');
    if (customerPhone.trim().isNotEmpty) {
      detailsBuffer.writeln('   • Phone: ${customerPhone.trim()}');
    }
    if (customerNote.trim().isNotEmpty) {
      detailsBuffer.writeln('   • Note: ${customerNote.trim()}');
    }
    detailsBuffer.writeln('──────────────────');

    String orderDetails;
    if (_isBundle && bundle != null) {
      final totalPieces = bundle.totalPieces * _quantity;
      final totalPrice = bundle.bundlePrice * _quantity;
      orderDetails = '''• *Product Name*: ${widget.product.title}
• *SKU CODE*: "${widget.product.sku}"
• *Bundle*: ${bundle.bundleName}
• *Sizes*: ${bundle.sizesBreakdown}
• *Bundles Ordered*: $_quantity
• *Pieces per Bundle*: ${bundle.totalPieces}
• *Total Pieces*: $totalPieces
• *Price per Bundle*: ${bundle.priceLabel}
• *Total Price*: ₹${totalPrice.toStringAsFixed(0)}
• *Segment*: $dept
• *Category*: $cat
• *Product URL*: $productUrl''';
    } else {
      // Legacy fallback
      orderDetails = '''• *Product Name*: ${widget.product.title}
• *SKU CODE*: "${widget.product.sku}"
• *Quantity*: $_quantity
• *Segment*: $dept
• *Category*: $cat
• *Product URL*: $productUrl''';
    }

    final message = '''
${detailsBuffer.toString()}$orderDetails
──────────────────
Please confirm availability and ordering details. Thank you!
''';

    final uri = Uri.parse('https://wa.me/$cleanWa?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp'), backgroundColor: Colors.red),
        );
      }
    }
    if (context.mounted) Navigator.pop(context);
  }

  void _handleAddToCartSubmit(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final auth = Provider.of<CustomerAuthProvider>(context, listen: false);
    final bundle = widget.product.bundle;

    if (_isBundle && bundle != null) {
      cart.addItem(
        widget.product,
        bundle.bundleName, // size field holds bundle name for keying
        bundle.bundlePrice,
        _quantity,
        bundleName: bundle.bundleName,
        bundleSizes: bundle.sizes,
        totalPiecesPerBundle: bundle.totalPieces,
        piecesPerSize: bundle.piecesPerSize,
      );
    } else {
      // Legacy fallback: add as free-size item
      cart.addItem(
        widget.product,
        'Free Size',
        0.0,
        _quantity,
      );
    }
    Navigator.pop(context);

    if (widget.isBuyNow) {
      if (!auth.isAuthenticated) {
        if (auth.needsOnboarding) {
          context.go('/onboarding?redirect=${Uri.encodeComponent('/checkout')}');
        } else {
          context.go('/login?redirect=${Uri.encodeComponent('/checkout')}');
        }
      } else {
        context.go('/checkout');
      }
    } else {
      context.go('/cart');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bundle = widget.product.bundle;

    // Prices
    final double unitPrice = _isBundle && bundle != null ? bundle.bundlePrice : 0.0;
    final double totalPrice = unitPrice * _quantity;
    final String unitPriceLabel =
        _isBundle && bundle != null ? bundle.priceLabel : widget.product.displayPrice;
    final String totalPriceLabel = totalPrice > 0
        ? '₹${totalPrice.toStringAsFixed(0)}'
        : unitPriceLabel;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.isWhatsApp ? 'INQUIRE VIA WHATSAPP' : 'SELECT QUANTITY',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(color: Color(0xFFE5E5E5), height: 24),

            // Product Brief Info
            Row(
              children: [
                if (widget.product.coverImageUrl.isNotEmpty)
                  Container(
                    width: 70,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E5E5)),
                      image: DecorationImage(
                        image: NetworkImage(widget.product.coverImageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${widget.product.sku}',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF666666)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Bundle Info (shown for bundle products)
            if (_isBundle && bundle != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'BUNDLE',
                            style: GoogleFonts.inter(
                                fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            bundle.bundleName,
                            style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF333333)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _infoChip('${bundle.totalPieces} pcs/bundle'),
                        const SizedBox(width: 8),
                        _infoChip('${bundle.piecesPerSize} pcs/size'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sizes: ${bundle.sizesBreakdown}',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF555555)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Quantity Selector
            Text(
              _isBundle ? 'Number of Bundles' : 'Quantity (pieces)',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF555555)),
            ),
            const SizedBox(height: 6),
            HZQuantityStepper(
              initialValue: _quantity,
              isSmall: false,
              step: _isBundle ? 1 : 5,
              minValue: _isBundle ? 1 : 5,
              onChanged: (newQty, isValid) {
                setState(() {
                  _quantity = newQty;
                  _isQuantityValid = isValid;
                });
              },
            ),
            const SizedBox(height: 24),

            // Price Live Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isBundle ? 'PRICE / BUNDLE' : 'UNIT PRICE',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF888888)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unitPriceLabel,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TOTAL PRICE',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF888888)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalPriceLabel,
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Total pieces note for bundle orders
            if (_isBundle && bundle != null && _isQuantityValid && _quantity > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${bundle.totalPieces * _quantity} total pieces across ${bundle.sizes.length} sizes',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF555555),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF666666), fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isQuantityValid
                        ? () {
                            if (widget.isWhatsApp) {
                              _handleWhatsAppSubmit(context);
                            } else {
                              _handleAddToCartSubmit(context);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isWhatsApp ? const Color(0xFF25D366) : Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.isWhatsApp
                          ? 'CONTINUE TO WHATSAPP'
                          : (widget.isBuyNow ? 'PROCEED TO CHECKOUT' : 'ADD TO CART'),
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFCCCCCC)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }
}
