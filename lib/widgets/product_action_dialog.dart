import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/business_provider.dart';
import '../providers/catalog_provider.dart';
import 'quantity_stepper.dart';

class HZProductActionDialog extends StatefulWidget {
  final Product product;
  final bool isWhatsApp;
  final BuildContext parentContext;

  const HZProductActionDialog({
    super.key,
    required this.product,
    required this.isWhatsApp,
    required this.parentContext,
  });

  static Future<void> show(BuildContext context, {required Product product, required bool isWhatsApp}) {
    return showDialog(
      context: context,
      builder: (dialogContext) => HZProductActionDialog(
        product: product,
        isWhatsApp: isWhatsApp,
        parentContext: context,
      ),
    );
  }

  @override
  State<HZProductActionDialog> createState() => _HZProductActionDialogState();
}

class _HZProductActionDialogState extends State<HZProductActionDialog> {
  late String _selectedSize;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    final sizes = widget.product.availableSizes.isNotEmpty
        ? widget.product.availableSizes
        : ['Free Size'];
    _selectedSize = sizes.first;
  }

  Future<void> _handleWhatsAppSubmit(BuildContext context, double unitPrice, double totalPrice) async {
    final business = Provider.of<BusinessProvider>(context, listen: false);
    final catalog = Provider.of<CatalogProvider>(context, listen: false);

    final rawNumber = business.settings.whatsAppNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final cleanWa = rawNumber.startsWith('+') ? rawNumber.substring(1) : rawNumber;
    
    final dept = catalog.getDepartmentById(widget.product.departmentId)?.name ?? 'Apparel';
    final cat = catalog.getCategoryById(widget.product.categoryId)?.name ?? 'Clothing';
    final productUrl = '${Uri.base.origin}/product/${widget.product.slug}';

    final message = '''
🛍️ *PRODUCT INQUIRY - HASH ZONE*
──────────────────
• *Product Name*: ${widget.product.title}
• *SKU*: ${widget.product.sku}
• *Selected Size*: $_selectedSize
• *Quantity*: $_quantity
• *Unit Price*: ₹${unitPrice.toStringAsFixed(0)}
• *Total Price*: ₹${totalPrice.toStringAsFixed(0)}
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

  static Timer? _snackBarTimer;

  void _handleAddToCartSubmit(BuildContext context, double unitPrice) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.addItem(widget.product, _selectedSize, unitPrice, _quantity);

    final parentCtx = widget.parentContext;
    Navigator.pop(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!parentCtx.mounted) return;
      final router = GoRouter.of(parentCtx);

      _snackBarTimer?.cancel();
      rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();

      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('"${widget.product.title}" ($_selectedSize) added to cart.'),
          duration: const Duration(seconds: 6),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: Colors.white,
            onPressed: () {
              _snackBarTimer?.cancel();
              rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
              router.go('/cart');
            },
          ),
        ),
      );

      _snackBarTimer = Timer(const Duration(seconds: 6), () {
        rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final sizes = widget.product.availableSizes.isNotEmpty
        ? widget.product.availableSizes
        : ['Free Size'];

    final double unitPrice = widget.product.getActivePriceForSize(_selectedSize);
    final double totalPrice = unitPrice * _quantity;

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
                    widget.isWhatsApp ? 'INQUIRE VIA WHATSAPP' : 'ADD TO CART',
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
                    final sizePrice = widget.product.getActivePriceForSize(size);
                    final priceLabel = sizePrice > 0 ? '₹${sizePrice.toStringAsFixed(0)}' : 'Price on Inquiry';
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
            SizedBox(
              width: 120,
              child: HZQuantityStepper(
                product: widget.product,
                height: 36.0,
                value: _quantity,
                onChanged: (newQty) {
                  setState(() {
                    _quantity = newQty;
                  });
                },
              ),
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
                        unitPrice > 0 ? '₹${unitPrice.toStringAsFixed(0)}' : 'Inquiry',
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
                        totalPrice > 0 ? '₹${totalPrice.toStringAsFixed(0)}' : 'Inquiry',
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
                    onPressed: () {
                      if (widget.isWhatsApp) {
                        _handleWhatsAppSubmit(context, unitPrice, totalPrice);
                      } else {
                        _handleAddToCartSubmit(context, unitPrice);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isWhatsApp ? const Color(0xFF25D366) : Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.isWhatsApp ? 'CONTINUE TO WHATSAPP' : 'ADD TO CART',
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
}
