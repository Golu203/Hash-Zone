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
  late String _selectedSize;
  int _quantity = 5;
  bool _isQuantityValid = true;

  @override
  void initState() {
    super.initState();
    final sizes = widget.product.availableSizes.isNotEmpty
        ? widget.product.availableSizes
        : ['Free Size'];
    _selectedSize = sizes.first;
  }

  Future<void> _handleWhatsAppSubmit(BuildContext context, String unitPriceLabel, String totalPriceLabel) async {
    final business = Provider.of<BusinessProvider>(context, listen: false);
    final catalog = Provider.of<CatalogProvider>(context, listen: false);

    final result = await HZCustomerInfoDialog.show(context);
    if (result == null) return; // user cancelled

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

    final message = '''
${detailsBuffer.toString()}• *Product Name*: ${widget.product.title}
• *SKU CODE*: "${widget.product.sku}"
• *Selected Size*: $_selectedSize
• *Quantity*: $_quantity
• *Unit Price*: $unitPriceLabel
• *Total Price*: $totalPriceLabel
• *Segment*: $dept
• *Category*: $cat
• *Product URL*: $productUrl
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

  void _handleAddToCartSubmit(BuildContext context, double unitPrice) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final auth = Provider.of<CustomerAuthProvider>(context, listen: false);
    cart.addItem(widget.product, _selectedSize, unitPrice, _quantity);
    Navigator.pop(context);

    if (widget.isBuyNow) {
      if (!auth.isAuthenticated) {
        context.go('/login?redirect=${Uri.encodeComponent('/checkout')}');
      } else {
        context.go('/checkout');
      }
    } else {
      if (!auth.isAuthenticated) {
        context.go('/login?redirect=${Uri.encodeComponent('/cart')}');
      } else {
        context.go('/cart');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = widget.product.availableSizes.isNotEmpty
        ? widget.product.availableSizes
        : ['Free Size'];

    final double unitPrice = widget.product.getActivePriceForSize(_selectedSize);
    final double totalPrice = unitPrice * _quantity;
    final String unitPriceLabel = widget.product.getPriceLabelForSize(_selectedSize);
    final String totalPriceLabel = _quantity > 0 && unitPrice > 0
        ? _getTotalPriceLabel(unitPriceLabel, _quantity, totalPrice)
        : unitPriceLabel;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
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
                    widget.isWhatsApp ? 'INQUIRE VIA WHATSAPP' : 'SELECT SIZE & QUANTITY',
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
            const SizedBox(height: 20),

            // Size Dropdown
            Text(
              'Select Size',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF555555)),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCCCCCC)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedSize,
                  dropdownColor: Colors.white,
                  focusColor: Colors.transparent,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600),
                  items: sizes.map((size) {
                    final priceLabel = widget.product.getPriceLabelForSize(size);
                    return DropdownMenuItem<String>(
                      value: size,
                      child: Text('$size — $priceLabel'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedSize = val;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quantity Selector
            Text(
              'Quantity',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF555555)),
            ),
            const SizedBox(height: 6),
            HZQuantityStepper(
              initialValue: _quantity,
              isSmall: false,
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
                        'UNIT PRICE',
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
                              _handleWhatsAppSubmit(context, unitPriceLabel, totalPriceLabel);
                            } else {
                              _handleAddToCartSubmit(context, unitPrice);
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
                      widget.isWhatsApp ? 'CONTINUE TO WHATSAPP' : (widget.isBuyNow ? 'PROCEED TO CHECKOUT' : 'ADD TO CART'),
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

  String _getTotalPriceLabel(String unitPriceLabel, int quantity, double totalPrice) {
    if (totalPrice <= 0) return unitPriceLabel;
    final cleanNumStr = unitPriceLabel.replaceAll(RegExp(r'[^\d.]'), '');
    final numIndex = unitPriceLabel.lastIndexOf(cleanNumStr);
    if (numIndex != -1) {
      final suffix = unitPriceLabel.substring(numIndex + cleanNumStr.length);
      return '₹${totalPrice.toStringAsFixed(0)}$suffix';
    }
    return '₹${totalPrice.toStringAsFixed(0)}';
  }
}
